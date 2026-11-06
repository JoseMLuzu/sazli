@preconcurrency import AVFoundation
import NaturalLanguage

struct CookingNarrationVoice: Sendable {
    let identifier: String
    let language: String
    let quality: Int
    var isNovelty = false
    var isPersonal = false
}

@MainActor
final class NativeCookingSpeechOutput: NSObject, CookingSpeechOutput, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var utteranceID: ObjectIdentifier?
    private var completion: (@MainActor () -> Void)?
    private var ownsSession = false

    override init() {
        super.init()
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = true
    }

    func speak(_ step: CookingVoiceStep, fallbackLanguage: CookingVoiceLanguage, onFinish: @escaping @MainActor () -> Void) throws {
        stop()
        try activateAudio()
        let utterance = Self.makeUtterance(step, fallbackLanguage: fallbackLanguage)
        utteranceID = ObjectIdentifier(utterance)
        completion = onFinish
        synthesizer.speak(utterance)
    }

    static func makeUtterance(_ step: CookingVoiceStep, fallbackLanguage: CookingVoiceLanguage) -> AVSpeechUtterance {
        let detected = NLLanguageRecognizer.dominantLanguage(for: step.text)?.rawValue
        let language = detected == "es" ? "es-ES" : detected == "en" ? "en-US" : fallbackLanguage.rawValue
        let available = AVSpeechSynthesisVoice.speechVoices()
        let options = available.map {
            CookingNarrationVoice(identifier: $0.identifier, language: $0.language, quality: $0.quality.rawValue,
                isNovelty: $0.voiceTraits.contains(.isNoveltyVoice), isPersonal: $0.voiceTraits.contains(.isPersonalVoice))
        }
        let defaultVoice = AVSpeechSynthesisVoice(language: language)
        let identifier = preferredVoice(in: options, language: language,
            preferredLocales: Locale.preferredLanguages, defaultIdentifier: defaultVoice?.identifier)
        let prefix = language.hasPrefix("es") ? "Paso" : "Step"
        let utterance = AVSpeechUtterance(string: "\(prefix) \(step.number). \(step.text)")
        utterance.voice = identifier.flatMap { AVSpeechSynthesisVoice(identifier: $0) } ?? defaultVoice
        // Let the selected voice retain its normal cadence and pitch. Preserve
        // recipe punctuation so the native synthesizer can apply its own prosody.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1
        return utterance
    }

    static func preferredVoice(in voices: [CookingNarrationVoice], language: String,
        preferredLocales: [String], defaultIdentifier: String?) -> String? {
        func canonical(_ locale: String) -> String { locale.replacingOccurrences(of: "_", with: "-") }
        let code = canonical(language).split(separator: "-").first
        let preferences = preferredLocales.map(canonical) + [canonical(language)]
        func regionRank(_ voice: CookingNarrationVoice) -> Int {
            preferences.firstIndex(of: canonical(voice.language)) ?? preferences.count
        }
        return voices.filter {
            !$0.isNovelty && !$0.isPersonal && canonical($0.language).split(separator: "-").first == code
        }.sorted {
            if $0.quality != $1.quality { return $0.quality > $1.quality }
            if regionRank($0) != regionRank($1) { return regionRank($0) < regionRank($1) }
            if ($0.identifier == defaultIdentifier) != ($1.identifier == defaultIdentifier) {
                return $0.identifier == defaultIdentifier
            }
            return $0.identifier < $1.identifier
        }.first?.identifier
    }

    func pause() -> Bool {
        guard synthesizer.pauseSpeaking(at: .immediate) else { return false }
        releaseAudio()
        return true
    }

    func resume() throws -> Bool {
        try activateAudio()
        let resumed = synthesizer.continueSpeaking()
        if !resumed { releaseAudio() }
        return resumed
    }

    func stop() {
        utteranceID = nil
        completion = nil
        synthesizer.stopSpeaking(at: .immediate)
        releaseAudio()
    }

    private func activateAudio() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try session.setActive(true)
        ownsSession = true
    }

    private func releaseAudio() {
        guard ownsSession else { return }
        ownsSession = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in self?.finished(id) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in self?.finished(id) }
    }

    private func finished(_ id: ObjectIdentifier) {
        guard utteranceID == id else { return }
        utteranceID = nil
        let callback = completion
        completion = nil
        releaseAudio()
        callback?()
    }
}
