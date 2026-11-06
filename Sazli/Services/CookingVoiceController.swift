import AVFoundation
import Observation

/// One cooking screen owns the session. Reading and microphone capture never overlap.
@MainActor @Observable
final class CookingVoiceController {
    enum ReadingState { case idle, speaking, paused }
    private(set) var readingState = ReadingState.idle
    private(set) var readAloudEnabled = false
    private(set) var commandsEnabled = false
    private(set) var isListening = false
    private(set) var isRequestingPermission = false
    private(set) var language = CookingVoiceLanguage.spanish
    private(set) var message: String?
    @ObservationIgnored var onCommand: (@MainActor (CookingVoiceCommand) -> Void)?
    @ObservationIgnored private let speaker: CookingSpeechOutput
    @ObservationIgnored private let listener: CookingCommandListening
    @ObservationIgnored private let now: () -> TimeInterval
    @ObservationIgnored private let observesAudioEvents: Bool
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var active = false
    @ObservationIgnored private var step: CookingVoiceStep?
    @ObservationIgnored private var authorized = false
    @ObservationIgnored private var permissionID: UUID?
    @ObservationIgnored private var readingID: UUID?
    @ObservationIgnored private var captureID: UUID?
    @ObservationIgnored private var restartTask: Task<Void, Never>?
    @ObservationIgnored private var pendingCommand: Task<Void, Never>?
    @ObservationIgnored private var lastCommand: (CookingVoiceCommand, TimeInterval)?

    init(speaker: CookingSpeechOutput = NativeCookingSpeechOutput(),
         listener: CookingCommandListening = NativeCookingCommandListener(),
         observesAudioEvents: Bool = true, now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.speaker = speaker
        self.listener = listener
        self.observesAudioEvents = observesAudioEvents
        self.now = now
    }

    var status: String? {
        if isRequestingPermission { return "Waiting for voice permission…" }
        if isListening { return "Listening for commands · \(language.title)" }
        if commandsEnabled && readingState == .speaking { return "Listening pauses while Sazli reads." }
        if readingState == .speaking { return "Reading this step…" }
        if readingState == .paused { return "Reading paused." }
        if commandsEnabled { return "Voice commands are on." }
        if readAloudEnabled { return "Read aloud is on for new steps." }
        return nil
    }

    func activate(step: CookingVoiceStep?, language: CookingVoiceLanguage) {
        active = true
        self.step = step
        self.language = language
        observeAudioEvents()
        startCaptureIfReady()
    }

    func updateStep(_ step: CookingVoiceStep?) {
        self.step = step
        readingID = nil
        speaker.stop()
        readingState = .idle
        if active && readAloudEnabled { readCurrentStep() }
        else { startCaptureIfReady() }
    }

    func setReadAloud(_ enabled: Bool) {
        message = nil
        readAloudEnabled = enabled && active && step != nil
        if readAloudEnabled { readCurrentStep() }
        else {
            readingID = nil
            speaker.stop()
            readingState = .idle
            startCaptureIfReady()
        }
    }

    func repeatStep() {
        guard active, step != nil else { return }
        readAloudEnabled = true
        readCurrentStep()
    }

    func pauseReading() {
        guard readingState == .speaking, speaker.pause() else { return }
        readingState = .paused
        restartCaptureSoon()
    }

    func resumeReading() {
        guard active, readAloudEnabled, readingState == .paused else { return }
        stopCapture()
        do {
            if try speaker.resume() { readingState = .speaking }
            else { readCurrentStep() }
        } catch { readingFailed(error) }
    }

    func enableCommands() async {
        guard active, step != nil, !commandsEnabled else { return }
        message = nil
        let id = UUID()
        permissionID = id
        isRequestingPermission = true
        commandsEnabled = true
        authorized = false
        do {
            try await listener.authorize(language: language)
            guard permissionID == id, commandsEnabled else { return }
            permissionID = nil
            isRequestingPermission = false
            authorized = true
            startCaptureIfReady()
        } catch {
            guard permissionID == id else { return }
            disableCommands()
            message = error.localizedDescription
        }
    }

    func disableCommands() {
        permissionID = nil
        isRequestingPermission = false
        commandsEnabled = false
        authorized = false
        stopCapture()
    }

    func changeLanguage(_ language: CookingVoiceLanguage) async {
        guard self.language != language else { return }
        let resume = commandsEnabled
        disableCommands()
        self.language = language
        if resume { await enableCommands() }
    }

    func sceneActive() {
        active = true
        startCaptureIfReady()
    }

    func sceneInactive(background: Bool) {
        active = false
        // System permission sheets make a scene inactive. Keep that pending request, but
        // never start capture until the scene returns active; background/close cancels it.
        if isRequestingPermission && !background {
            readAloudEnabled = false
            readingID = nil
            speaker.stop()
            readingState = .idle
            stopCapture()
        } else { stopAll() }
    }

    func stopAll() {
        disableCommands()
        readAloudEnabled = false
        readingID = nil
        speaker.stop()
        readingState = .idle
        lastCommand = nil
    }

    func interrupt() {
        guard readAloudEnabled || commandsEnabled else { return }
        stopAll()
        message = "Voice stopped after an audio interruption. Turn it on again when you're ready."
    }

    func shutdown() {
        active = false
        stopAll()
        onCommand = nil
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers = []
    }

    private func readCurrentStep() {
        guard active, let step, !step.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        stopCapture()
        let id = UUID()
        readingID = id
        readingState = .speaking
        do {
            try speaker.speak(step, fallbackLanguage: language) { [weak self] in
                guard let self, self.readingID == id else { return }
                self.readingID = nil
                self.readingState = .idle
                self.restartCaptureSoon()
            }
        } catch { readingFailed(error) }
    }

    private func readingFailed(_ error: Error) {
        readingID = nil
        speaker.stop()
        readingState = .idle
        readAloudEnabled = false
        message = "Couldn't read this step. \(error.localizedDescription)"
        startCaptureIfReady()
    }

    private func startCaptureIfReady() {
        guard active, commandsEnabled, authorized, !isRequestingPermission,
              readingState != .speaking, !isListening else { return }
        restartTask?.cancel()
        restartTask = nil
        let id = UUID()
        captureID = id
        do {
            try listener.start(language: language, onText: { [weak self] text in
                guard let self, self.captureID == id else { return }
                self.receive(text)
            }, onEnd: { [weak self] error in
                guard let self, self.captureID == id else { return }
                self.stopCapture()
                if let error {
                    self.disableCommands()
                    self.message = "Voice commands stopped. \(error)"
                } else { self.restartCaptureSoon() }
            })
            isListening = true
        } catch {
            disableCommands()
            message = error.localizedDescription
        }
    }

    private func receive(_ result: CookingRecognizedText) {
        pendingCommand?.cancel()
        pendingCommand = nil
        guard active, commandsEnabled, isListening, readingState != .speaking,
              let command = CookingVoiceCommand.parse(result.text, language: language) else { return }
        if result.isFinal { accept(command); return }
        let id = captureID
        pendingCommand = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
            guard let self, self.captureID == id, self.active, self.commandsEnabled, self.isListening else { return }
            self.accept(command)
        }
    }

    private func accept(_ command: CookingVoiceCommand) {
        let instant = now()
        if let lastCommand, lastCommand.0 == command, instant - lastCommand.1 < 0.75 { return }
        lastCommand = (command, instant)
        stopCapture()
        switch command {
        case .repeatStep: repeatStep()
        case .stop: stopAll()
        case .next, .previous: onCommand?(command)
        }
        restartCaptureSoon()
    }

    private func stopCapture() {
        pendingCommand?.cancel()
        pendingCommand = nil
        restartTask?.cancel()
        restartTask = nil
        captureID = nil
        listener.stop()
        isListening = false
    }

    private func restartCaptureSoon() {
        guard active, commandsEnabled, readingState != .speaking else { return }
        restartTask?.cancel()
        restartTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            self?.startCaptureIfReady()
        }
    }

    private func observeAudioEvents() {
        guard observesAudioEvents, observers.isEmpty else { return }
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
            object: nil, queue: .main) { [weak self] notification in
                let began = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                    == AVAudioSession.InterruptionType.began.rawValue
                if began { Task { @MainActor [weak self] in self?.interrupt() } }
            })
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification,
            object: nil, queue: .main) { [weak self] notification in
                let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                let changed = reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
                    || reason == AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue
                    || reason == AVAudioSession.RouteChangeReason.noSuitableRouteForCategory.rawValue
                if changed { Task { @MainActor [weak self] in self?.interrupt() } }
            })
        observers.append(NotificationCenter.default.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.interrupt() }
            })
    }
}
