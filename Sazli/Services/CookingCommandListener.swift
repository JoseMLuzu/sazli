@preconcurrency import AVFoundation
@preconcurrency import Speech

/// The audio tap and task teardown may run on different queues. The box serializes access
/// to Apple's request and never retains buffers or writes recordings to disk.
private final class CookingAudioRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    init(_ request: SFSpeechAudioBufferRecognitionRequest) { self.request = request }
    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock(); defer { lock.unlock() }
        request?.append(buffer)
    }
    func finish() {
        lock.lock(); defer { lock.unlock() }
        request?.endAudio()
        request = nil
    }
}

@MainActor
final class NativeCookingCommandListener: CookingCommandListening {
    private let engine = AVAudioEngine()
    private var task: SFSpeechRecognitionTask?
    private var renewal: Task<Void, Never>?
    private var recognizer: SFSpeechRecognizer?
    private var preparedRecognizer: SFSpeechRecognizer?
    private var preparedLanguage: CookingVoiceLanguage?
    private var requestBox: CookingAudioRequest?
    private var sessionID: UUID?
    private var hasTap = false
    private var ownsAudioSession = false

    func authorize(language: CookingVoiceLanguage) async throws {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization(Self.authorizationCallback(continuation))
        }
        guard speech == .authorized else { throw VoiceError.speechPermission }
        preparedRecognizer = nil
        preparedLanguage = nil
        let candidates = recognitionCandidates(language: language)
        // Speech can need a brief initialization period before reporting local
        // model support. Retain the recognizers while it resolves availability.
        for attempt in 0..<4 {
            if let selected = selectRecognizer(language: language, candidates: candidates) {
                preparedRecognizer = selected
                preparedLanguage = language
                break
            }
            if attempt < 3 { try await Task.sleep(for: .milliseconds(300)) }
        }
        guard preparedRecognizer != nil else { throw VoiceError.onDeviceUnavailable(language) }
        guard await AVAudioApplication.requestRecordPermission() else { throw VoiceError.microphonePermission }
    }

    func start(language: CookingVoiceLanguage, onText: @escaping @MainActor (CookingRecognizedText) -> Void,
               onEnd: @escaping @MainActor (String?) -> Void) throws {
        stop()
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              AVAudioApplication.shared.recordPermission == .granted else { throw VoiceError.microphonePermission }
        let ready = preparedLanguage == language ? preparedRecognizer : nil
        guard let recognizer = ready ?? selectRecognizer(language: language, candidates: recognitionCandidates(language: language)),
              recognizer.supportsOnDeviceRecognition else { throw VoiceError.onDeviceUnavailable(language) }
        guard recognizer.isAvailable else { throw VoiceError.unavailable }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers])
            try audio.setActive(true)
            ownsAudioSession = true
            let request = Self.recognitionRequest(language: language)
            let box = CookingAudioRequest(request)
            requestBox = box
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else { throw VoiceError.unavailable }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in box.append(buffer) }
            hasTap = true
            let id = UUID()
            sessionID = id
            self.recognizer = recognizer
            task = recognizer.recognitionTask(with: request) { @Sendable [weak self] result, error in
                let text = result?.bestTranscription.formattedString
                let final = result?.isFinal == true
                let message = error?.localizedDescription
                Task { @MainActor [weak self] in
                    guard let self, self.sessionID == id else { return }
                    if let text { onText(CookingRecognizedText(text: text, isFinal: final)) }
                    guard self.sessionID == id else { return }
                    if final || message != nil {
                        self.stop()
                        onEnd(final ? nil : message)
                    }
                }
            }
            engine.prepare()
            try engine.start()
            renewal = Task { @MainActor [weak self] in
                do { try await Task.sleep(for: .seconds(45)) } catch { return }
                guard let self, self.sessionID == id else { return }
                self.stop()
                onEnd(nil)
            }
        } catch {
            stop()
            throw error
        }
    }

    private func recognitionCandidates(language: CookingVoiceLanguage) -> [(String, SFSpeechRecognizer)] {
        let locales = language.recognitionLocales(preferred: Locale.preferredLanguages,
            supported: SFSpeechRecognizer.supportedLocales().map(\.identifier))
        return locales.compactMap { identifier in
            SFSpeechRecognizer(locale: Locale(identifier: identifier)).map { (identifier, $0) }
        }
    }

    private func selectRecognizer(language: CookingVoiceLanguage,
        candidates: [(String, SFSpeechRecognizer)]) -> SFSpeechRecognizer? {
        let byLocale = Dictionary(uniqueKeysWithValues: candidates)
        guard let locale = language.availableRecognitionLocale(in: candidates.map(\.0),
            supportsOnDevice: { byLocale[$0]?.supportsOnDeviceRecognition == true },
            isAvailable: { byLocale[$0]?.isAvailable == true }) else { return nil }
        return byLocale[locale]
    }

    // Speech invokes authorization on its own queue. A Sendable callback must not
    // inherit this listener's MainActor isolation, even with preconcurrency imports.
    nonisolated static func authorizationCallback(
        _ continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>
    ) -> @Sendable (SFSpeechRecognizerAuthorizationStatus) -> Void {
        { @Sendable status in continuation.resume(returning: status) }
    }

    static func recognitionRequest(language: CookingVoiceLanguage) -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation
        request.contextualStrings = language == .spanish
            ? ["Sazli", "siguiente", "anterior", "repetir", "detener"]
            : ["Sazli", "next", "previous", "repeat", "stop"]
        return request
    }

    func stop() {
        renewal?.cancel()
        renewal = nil
        sessionID = nil
        engine.stop()
        if hasTap { engine.inputNode.removeTap(onBus: 0); hasTap = false }
        requestBox?.finish()
        requestBox = nil
        task?.cancel()
        task = nil
        recognizer = nil
        engine.reset()
        if ownsAudioSession {
            ownsAudioSession = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    enum VoiceError: LocalizedError {
        case onDeviceUnavailable(CookingVoiceLanguage), speechPermission, microphonePermission, unavailable
        var errorDescription: String? {
            switch self {
            case .onDeviceUnavailable(let language): "No available on-device recognizer was found for \(language.title). Sazli checked supported regional variants. Check this language's Dictation availability in iPhone Settings > General > Keyboard, then try again. Read aloud is still available."
            case .speechPermission: "Allow Speech Recognition for Sazli in iPhone Settings to use voice commands. Read aloud is still available."
            case .microphonePermission: "Allow Microphone access for Sazli in iPhone Settings to use voice commands. Read aloud is still available."
            case .unavailable: "Voice input isn't available right now. Check your microphone or try again."
            }
        }
    }
}
