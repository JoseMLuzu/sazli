import XCTest
import AVFoundation
@preconcurrency import Speech
@testable import Sazli

@MainActor
final class CookingVoiceTests: XCTestCase {
    private let step = CookingVoiceStep(number: 1, text: "Mix the eggs gently.")

    func testNarrationPrefersQualityWithinRecipeLanguageWithoutNoveltyOrPersonalVoices() {
        let voices = [
            CookingNarrationVoice(identifier: "compact", language: "es-ES", quality: 1),
            CookingNarrationVoice(identifier: "enhanced", language: "es-MX", quality: 2),
            CookingNarrationVoice(identifier: "premium", language: "es-US", quality: 3),
            CookingNarrationVoice(identifier: "english", language: "en-US", quality: 3),
            CookingNarrationVoice(identifier: "novelty", language: "es-ES", quality: 3, isNovelty: true),
            CookingNarrationVoice(identifier: "personal", language: "es-ES", quality: 3, isPersonal: true)
        ]
        XCTAssertEqual(NativeCookingSpeechOutput.preferredVoice(in: voices, language: "es-ES",
            preferredLocales: ["es-ES"], defaultIdentifier: "compact"), "premium")
        XCTAssertEqual(NativeCookingSpeechOutput.preferredVoice(in: Array(voices.prefix(2)), language: "es-ES",
            preferredLocales: ["es-ES"], defaultIdentifier: "compact"), "enhanced")
        XCTAssertNil(NativeCookingSpeechOutput.preferredVoice(in: voices, language: "fr-FR",
            preferredLocales: ["es-ES"], defaultIdentifier: "compact"))
    }

    func testEqualQualityNarrationRespectsRegionThenSystemVoiceAndHasStableFallback() {
        let voices = [CookingNarrationVoice(identifier: "a", language: "es-ES", quality: 1),
            CookingNarrationVoice(identifier: "b", language: "es-MX", quality: 1),
            CookingNarrationVoice(identifier: "c", language: "es-MX", quality: 1)]
        XCTAssertEqual(NativeCookingSpeechOutput.preferredVoice(in: voices, language: "es-ES",
            preferredLocales: ["es_MX"], defaultIdentifier: "c"), "c")
        XCTAssertEqual(NativeCookingSpeechOutput.preferredVoice(in: voices.reversed(), language: "es-ES",
            preferredLocales: ["es-MX"], defaultIdentifier: nil), "b")
        XCTAssertEqual(NativeCookingSpeechOutput.preferredVoice(in: [voices[0]], language: "es-ES",
            preferredLocales: ["es-MX"], defaultIdentifier: nil), "a")
    }

    func testNativeNarrationKeepsRecipeTextAndUsesNormalPitchAndCadence() {
        let text = "Añade 1,5 g de sal. Remueve suavemente; cocina durante 2 minutos."
        let utterance = NativeCookingSpeechOutput.makeUtterance(CookingVoiceStep(number: 2, text: text),
            fallbackLanguage: .english)
        XCTAssertEqual(utterance.speechString, "Paso 2. \(text)")
        XCTAssertEqual(utterance.rate, AVSpeechUtteranceDefaultSpeechRate)
        XCTAssertEqual(utterance.pitchMultiplier, 1)
        if let voice = utterance.voice {
            XCTAssertTrue(voice.language.hasPrefix("es"))
            print("SAZLI_NARRATION_VOICE name=\(voice.name) locale=\(voice.language) quality=\(voice.quality.rawValue)")
        }
    }

    func testSpanishRecognitionTriesRegionalVariantsWithoutChangingLanguage() {
        let locales = CookingVoiceLanguage.spanish.recognitionLocales(
            preferred: ["en-US", "es-EC", "es_ES"], supported: ["es-MX", "en-US", "es_ES", "es-US", "es-AR"])
        XCTAssertEqual(locales, ["es-ES", "es-MX", "es-US", "es-AR"])
        let selected = CookingVoiceLanguage.spanish.availableRecognitionLocale(in: locales,
            supportsOnDevice: { $0 == "es-MX" }, isAvailable: { _ in true })
        XCTAssertEqual(selected, "es-MX", "Spain's missing local model must not block available Mexican Spanish.")
        XCTAssertEqual(CookingVoiceCommand.parse("Siguiente", language: .spanish), .next)
    }

    func testRecognitionPrefersInstalledUserVariantAndSkipsUnavailableServices() {
        let language = CookingVoiceLanguage.spanish
        let locales = language.recognitionLocales(preferred: ["es-US", "es-MX"],
            supported: ["es-US", "es-MX", "es-ES"])
        XCTAssertEqual(locales, ["es-US", "es-MX", "es-ES"])
        XCTAssertEqual(language.availableRecognitionLocale(in: locales,
            supportsOnDevice: { _ in true }, isAvailable: { $0 != "es-US" }), "es-MX")
        XCTAssertNil(language.availableRecognitionLocale(in: locales,
            supportsOnDevice: { _ in false }, isAvailable: { _ in true }))
    }

    func testEnglishRecognitionNeverUsesSpanishOrUnsupportedPreferredLocale() {
        let locales = CookingVoiceLanguage.english.recognitionLocales(preferred: ["es-EC", "en_NZ"],
            supported: ["en-GB", "en-US", "es-MX", "en-NZ", "en_US"])
        XCTAssertEqual(locales, ["en-NZ", "en-US", "en-GB"])
        XCTAssertTrue(CookingVoiceLanguage.spanish.recognitionLocales(preferred: ["es-EC"],
            supported: ["en-US"]).isEmpty)
    }

    func testNativeAuthorizationCallbackCanRunOffMainActor() async {
        // Exercise the production callback on the queue used by Speech/TCC.
        // The previous actor-inheriting closure traps here under Swift 6.
        for status in [SFSpeechRecognizerAuthorizationStatus.authorized, .denied, .restricted, .notDetermined] {
            let received = await withCheckedContinuation { continuation in
                let callback = NativeCookingCommandListener.authorizationCallback(continuation)
                DispatchQueue.global().async { callback(status) }
            }
            XCTAssertEqual(received, status)
        }
    }

    func testOnlyExplicitCommandsNavigateAndPunctuationAndAccentsAreSupported() {
        for phrase in ["siguiente", "Siguiente paso!", "Sazli, siguiente."] {
            XCTAssertEqual(CookingVoiceCommand.parse(phrase, language: .spanish), .next)
        }
        XCTAssertEqual(CookingVoiceCommand.parse("ATRÁS", language: .spanish), .previous)
        XCTAssertEqual(CookingVoiceCommand.parse("Repite el paso", language: .spanish), .repeatStep)
        XCTAssertEqual(CookingVoiceCommand.parse("Detén la voz", language: .spanish), .stop)
        XCTAssertEqual(CookingVoiceCommand.parse("Next step", language: .english), .next)
        XCTAssertEqual(CookingVoiceCommand.parse("Sazli, go back", language: .english), .previous)
        XCTAssertEqual(CookingVoiceCommand.parse("read again", language: .english), .repeatStep)
        for text in ["next add the eggs", "do not stop", "the next ingredient", "siguiente receta", "", "pausa", "123", "Next step 2", "siguiente 2"] {
            XCTAssertNil(CookingVoiceCommand.parse(text, language: .english), text)
            XCTAssertNil(CookingVoiceCommand.parse(text, language: .spanish), text)
        }
    }

    func testReadingNeedsNoMicrophoneAuthorizationAndStepChangesReplaceTheUtterance() {
        let f = fixture()
        defer { f.voice.shutdown() }
        f.voice.setReadAloud(true)
        XCTAssertEqual(f.speaker.steps, [step])
        XCTAssertEqual(f.listener.authorizations.count, 0)
        f.voice.updateStep(CookingVoiceStep(number: 2, text: "Cook until set."))
        XCTAssertEqual(f.speaker.steps.map(\.number), [1, 2])
        f.speaker.finish(0) // Late completion from the canceled first step.
        XCTAssertEqual(f.voice.readingState, .speaking)
        f.speaker.finish(1)
        XCTAssertEqual(f.voice.readingState, .idle)
        XCTAssertTrue(f.voice.readAloudEnabled)
    }

    func testMicrophoneIsOffDuringReadingAndLateRecognitionCannotNavigate() async throws {
        let f = fixture()
        defer { f.voice.shutdown() }
        var commands: [CookingVoiceCommand] = []
        f.voice.onCommand = { commands.append($0) }
        await f.voice.enableCommands()
        XCTAssertTrue(f.voice.isListening)
        f.voice.setReadAloud(true)
        XCTAssertFalse(f.listener.active)
        XCTAssertFalse(f.voice.isListening)
        f.listener.text("siguiente", session: 0)
        XCTAssertTrue(commands.isEmpty)
        f.speaker.finish(0)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(f.voice.isListening)
        XCTAssertEqual(f.listener.sessions.count, 2)
    }

    func testPermissionResultAfterClosingCannotStartTheMicrophone() async {
        let f = fixture()
        f.listener.deferred = true
        let request = Task { await f.voice.enableCommands() }
        await Task.yield()
        XCTAssertTrue(f.voice.isRequestingPermission)
        f.voice.shutdown()
        f.listener.grant(0)
        await request.value
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertFalse(f.listener.active)
        XCTAssertTrue(f.listener.sessions.isEmpty)
    }

    func testPermissionSheetInactivityDefersCaptureUntilSceneIsActive() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        f.listener.deferred = true
        let request = Task { await f.voice.enableCommands() }
        await Task.yield()
        f.voice.sceneInactive(background: false)
        f.listener.grant(0)
        await request.value
        XCTAssertTrue(f.voice.commandsEnabled)
        XCTAssertFalse(f.voice.isListening)
        f.voice.sceneActive()
        XCTAssertTrue(f.voice.isListening)
    }

    func testBackgroundCancelsPendingPermissionAndDoesNotAutoResume() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        f.listener.deferred = true
        let request = Task { await f.voice.enableCommands() }
        await Task.yield()
        f.voice.sceneInactive(background: true)
        f.listener.grant(0)
        await request.value
        f.voice.sceneActive()
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertFalse(f.listener.active)
    }

    func testDeniedCommandsStillAllowReadAloud() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        f.listener.authorizationError = NativeCookingCommandListener.VoiceError.speechPermission
        await f.voice.enableCommands()
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertNotNil(f.voice.message)
        f.voice.setReadAloud(true)
        XCTAssertEqual(f.speaker.steps.count, 1)
        XCTAssertEqual(f.voice.readingState, .speaking)
    }

    func testPauseResumeAndInterruptionsReleaseListeningAndDoNotAutoResume() async throws {
        let f = fixture()
        defer { f.voice.shutdown() }
        await f.voice.enableCommands()
        f.voice.setReadAloud(true)
        f.voice.pauseReading()
        XCTAssertEqual(f.voice.readingState, .paused)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(f.voice.isListening)
        f.voice.resumeReading()
        XCTAssertEqual(f.voice.readingState, .speaking)
        XCTAssertFalse(f.listener.active)
        f.voice.interrupt()
        XCTAssertFalse(f.voice.readAloudEnabled)
        XCTAssertFalse(f.voice.commandsEnabled)
        f.speaker.finish(0)
        f.voice.sceneActive()
        XCTAssertFalse(f.listener.active)
    }

    func testPartialAndFinalResultsCannotAdvanceTwiceAndStopDisablesVoice() async throws {
        let f = fixture()
        defer { f.voice.shutdown() }
        var received: [CookingVoiceCommand] = []
        f.voice.onCommand = { received.append($0) }
        await f.voice.enableCommands()
        f.listener.text("siguiente", session: 0, final: false)
        XCTAssertTrue(received.isEmpty)
        f.listener.text("siguiente paso", session: 0)
        XCTAssertEqual(received, [.next])
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(f.voice.isListening)
        f.listener.text("detener", session: 1)
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertFalse(f.voice.isListening)
    }

    func testUnrecognizedSpeechDoesNotNavigateAndCompletedCaptureRenews() async throws {
        let f = fixture()
        defer { f.voice.shutdown() }
        var received: [CookingVoiceCommand] = []
        f.voice.onCommand = { received.append($0) }
        await f.voice.enableCommands()
        f.listener.text("siguiente añade los huevos", session: 0)
        XCTAssertTrue(received.isEmpty)
        XCTAssertTrue(f.voice.isListening)
        f.listener.end(nil, session: 0)
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(f.listener.sessions.count, 2)
        XCTAssertTrue(f.voice.isListening)
    }

    func testLanguageChangeIgnoresAnEarlierPermissionResult() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        f.listener.deferred = true
        let first = Task { await f.voice.enableCommands() }
        await Task.yield()
        let second = Task { await f.voice.changeLanguage(.english) }
        await Task.yield()
        f.listener.grant(0)
        await first.value
        XCTAssertFalse(f.voice.isListening)
        f.listener.grant(1)
        await second.value
        XCTAssertEqual(f.listener.authorizations, [.spanish, .english])
        XCTAssertEqual(f.listener.startedLanguages, [.english])
    }

    func testShutdownClearsActiveResourcesAndAllLateCallbacks() async {
        let f = fixture()
        await f.voice.enableCommands()
        f.voice.setReadAloud(true)
        f.voice.shutdown()
        f.speaker.finish(0)
        f.listener.text("siguiente", session: 0)
        XCTAssertFalse(f.listener.active)
        XCTAssertFalse(f.speaker.playing)
        XCTAssertFalse(f.voice.readAloudEnabled)
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertNil(f.voice.onCommand)
    }

    func testNativeRequestsRequireOnDeviceRecognitionAndUsageDescriptionsArePresent() {
        for language in CookingVoiceLanguage.allCases {
            let request = NativeCookingCommandListener.recognitionRequest(language: language)
            XCTAssertTrue(request.requiresOnDeviceRecognition)
            XCTAssertTrue(request.shouldReportPartialResults)
            XCTAssertTrue(request.contextualStrings.contains(language == .spanish ? "siguiente" : "next"))
        }
        XCTAssertFalse((Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String ?? "").isEmpty)
        XCTAssertFalse((Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String ?? "").isEmpty)
    }

    func testCaptureFailureKeepsReadAloudAvailable() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        await f.voice.enableCommands()
        f.listener.end("Microphone disconnected", session: 0)
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertFalse(f.voice.isListening)
        f.voice.setReadAloud(true)
        XCTAssertEqual(f.speaker.steps.count, 1)
    }

    func testSpeechFailureRestoresAuthorizedCommandListening() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        await f.voice.enableCommands()
        f.speaker.error = NativeCookingCommandListener.VoiceError.unavailable
        f.voice.setReadAloud(true)
        XCTAssertFalse(f.voice.readAloudEnabled)
        XCTAssertTrue(f.voice.commandsEnabled)
        XCTAssertTrue(f.voice.isListening)
        XCTAssertNotNil(f.voice.message)
    }

    func testMissingStepsCannotEnableReadingOrCapture() async {
        let f = fixture()
        defer { f.voice.shutdown() }
        f.voice.updateStep(nil)
        f.voice.setReadAloud(true)
        await f.voice.enableCommands()
        XCTAssertFalse(f.voice.readAloudEnabled)
        XCTAssertFalse(f.voice.commandsEnabled)
        XCTAssertTrue(f.speaker.steps.isEmpty)
        XCTAssertTrue(f.listener.sessions.isEmpty)
    }

    func testSameCommandEchoIsDebouncedAcrossRecognitionSessions() async throws {
        var now = 100.0
        let f = fixture(now: { now })
        defer { f.voice.shutdown() }
        var commands: [CookingVoiceCommand] = []
        f.voice.onCommand = { commands.append($0) }
        await f.voice.enableCommands()
        f.listener.text("siguiente", session: 0)
        try await Task.sleep(for: .milliseconds(350))
        f.listener.text("siguiente", session: 1)
        XCTAssertEqual(commands, [.next])
        now += 1
        f.listener.text("siguiente", session: 1)
        XCTAssertEqual(commands, [.next, .next])
    }

    func testACommandPrefixInLongerSpeechDoesNotNavigate() async throws {
        let f = fixture()
        defer { f.voice.shutdown() }
        var received: [CookingVoiceCommand] = []
        f.voice.onCommand = { received.append($0) }
        await f.voice.enableCommands()
        f.listener.text("siguiente", session: 0, final: false)
        f.listener.text("siguiente ingrediente añade los huevos", session: 0, final: false)
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertTrue(received.isEmpty)
        XCTAssertTrue(f.voice.isListening)
    }

    func testStablePartialCommandActsOnceAndLateFinalDoesNotRepeatIt() async throws {
        let f = fixture()
        defer { f.voice.shutdown() }
        var received: [CookingVoiceCommand] = []
        f.voice.onCommand = { received.append($0) }
        await f.voice.enableCommands()
        f.listener.text("siguiente", session: 0, final: false)
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(received, [.next])
        f.listener.text("siguiente", session: 0)
        XCTAssertEqual(received, [.next])
    }

    private func fixture(now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) -> (voice: CookingVoiceController, speaker: VoiceSpeakerFake, listener: VoiceListenerFake) {
        let speaker = VoiceSpeakerFake()
        let listener = VoiceListenerFake()
        let voice = CookingVoiceController(speaker: speaker, listener: listener, observesAudioEvents: false, now: now)
        voice.activate(step: step, language: .spanish)
        return (voice, speaker, listener)
    }
}

@MainActor
private final class VoiceSpeakerFake: CookingSpeechOutput {
    var steps: [CookingVoiceStep] = []
    var completions: [@MainActor () -> Void] = []
    var playing = false
    var paused = false
    var error: Error?
    func speak(_ step: CookingVoiceStep, fallbackLanguage: CookingVoiceLanguage, onFinish: @escaping @MainActor () -> Void) throws {
        if let error { throw error }
        steps.append(step); completions.append(onFinish); playing = true; paused = false
    }
    func pause() -> Bool { paused = playing; playing = false; return paused }
    func resume() throws -> Bool { playing = paused; paused = false; return playing }
    func stop() { playing = false; paused = false }
    func finish(_ index: Int) { playing = false; completions[index]() }
}

@MainActor
private final class VoiceListenerFake: CookingCommandListening {
    struct Session { let text: @MainActor (CookingRecognizedText) -> Void; let end: @MainActor (String?) -> Void }
    var sessions: [Session] = []
    var authorizations: [CookingVoiceLanguage] = []
    var startedLanguages: [CookingVoiceLanguage] = []
    var pending: [CheckedContinuation<Void, Error>?] = []
    var deferred = false
    var authorizationError: Error?
    var active = false
    func authorize(language: CookingVoiceLanguage) async throws {
        authorizations.append(language)
        if let authorizationError { throw authorizationError }
        if deferred { try await withCheckedThrowingContinuation { pending.append($0) } }
    }
    func start(language: CookingVoiceLanguage, onText: @escaping @MainActor (CookingRecognizedText) -> Void,
               onEnd: @escaping @MainActor (String?) -> Void) throws {
        startedLanguages.append(language); sessions.append(Session(text: onText, end: onEnd)); active = true
    }
    func stop() { active = false }
    func grant(_ index: Int) { let request = pending[index]; pending[index] = nil; request?.resume() }
    func text(_ value: String, session: Int, final: Bool = true) { sessions[session].text(CookingRecognizedText(text: value, isFinal: final)) }
    func end(_ error: String?, session: Int) { active = false; sessions[session].end(error) }
}
