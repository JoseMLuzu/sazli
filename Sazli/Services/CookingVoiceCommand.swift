import Foundation

enum CookingVoiceLanguage: String, CaseIterable, Identifiable, Sendable {
    case spanish = "es-ES", english = "en-US"
    var id: String { rawValue }
    var title: String { self == .spanish ? "Español" : "English" }
    /// Keep the saved language choice stable while resolving regional Speech assets
    /// independently. Never substitute a recognizer in another language.
    func recognitionLocales(preferred: [String], supported: [String]) -> [String] {
        let code = self == .spanish ? "es" : "en"
        func canonical(_ value: String) -> String { value.replacingOccurrences(of: "_", with: "-") }
        let matching = Set(supported.map(canonical).filter { $0.split(separator: "-").first == Substring(code) })
        let defaults = self == .spanish ? ["es-MX", "es-US", "es-ES"] : ["en-US", "en-GB", "en-AU"]
        var seen = Set<String>()
        return (preferred.map(canonical) + defaults + matching.sorted()).filter {
            matching.contains($0) && seen.insert($0).inserted
        }
    }

    func availableRecognitionLocale(in candidates: [String],
        supportsOnDevice: (String) -> Bool, isAvailable: (String) -> Bool) -> String? {
        candidates.first { supportsOnDevice($0) && isAvailable($0) }
    }
    var examples: String {
        self == .spanish ? "Siguiente · Anterior · Repetir · Detener"
            : "Next · Previous · Repeat · Stop"
    }
}

enum CookingVoiceCommand: Equatable, Sendable {
    case next, previous, repeatStep, stop

    static func parse(_ text: String, language: CookingVoiceLanguage) -> Self? {
        guard !text.contains(where: \.isNumber) else { return nil }
        var words = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: language.rawValue))
            .components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        if words.first == "sazli" { words.removeFirst() }
        let phrase = words.joined(separator: " ")
        let commands: [(Self, [String])]
        if language == .spanish {
            commands = [(.next, ["siguiente", "siguiente paso", "paso siguiente", "avanza", "avanzar"]),
                (.previous, ["anterior", "paso anterior", "atras", "retroceder"]),
                (.repeatStep, ["repetir", "repite", "repetir paso", "repite el paso"]),
                (.stop, ["detener", "parar", "detener voz", "deten la voz"])]
        } else {
            commands = [(.next, ["next", "next step", "go next"]), (.previous, ["previous", "previous step", "go back"]),
                (.repeatStep, ["repeat", "repeat step", "read again"]), (.stop, ["stop", "stop voice", "stop reading"])]
        }
        return commands.first { $0.1.contains(phrase) }?.0
    }
}

struct CookingRecognizedText: Sendable {
    let text: String
    let isFinal: Bool
}

struct CookingVoiceStep: Equatable, Sendable {
    let number: Int
    let text: String
}

@MainActor
protocol CookingSpeechOutput: AnyObject {
    func speak(_ step: CookingVoiceStep, fallbackLanguage: CookingVoiceLanguage, onFinish: @escaping @MainActor () -> Void) throws
    func pause() -> Bool
    func resume() throws -> Bool
    func stop()
}

@MainActor
protocol CookingCommandListening: AnyObject {
    func authorize(language: CookingVoiceLanguage) async throws
    func start(language: CookingVoiceLanguage, onText: @escaping @MainActor (CookingRecognizedText) -> Void,
               onEnd: @escaping @MainActor (String?) -> Void) throws
    func stop()
}
