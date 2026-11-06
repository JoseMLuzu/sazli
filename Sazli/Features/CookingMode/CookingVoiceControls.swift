import SwiftUI
import UIKit

struct CookingVoiceControls: View {
    @Bindable var voice: CookingVoiceController
    @Binding var language: CookingVoiceLanguage
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Toggle(isOn: Binding(get: { voice.readAloudEnabled }, set: { voice.setReadAloud($0) })) {
                Label("Read aloud", systemImage: "speaker.wave.2")
            }
            .accessibilityIdentifier("cookingReadAloud")
            if voice.readAloudEnabled {
                HStack(spacing: 16) {
                    if voice.readingState == .speaking {
                        Button("Pause", systemImage: "pause.fill") { voice.pauseReading() }
                    } else if voice.readingState == .paused {
                        Button("Resume", systemImage: "play.fill") { voice.resumeReading() }
                    }
                    Button("Repeat", systemImage: "arrow.counterclockwise") { voice.repeatStep() }
                }
                .buttonStyle(.bordered).frame(minHeight: 44)
            }
            Toggle(isOn: Binding(get: { voice.commandsEnabled }, set: { enabled in
                if enabled { Task { await voice.enableCommands() } }
                else { voice.disableCommands() }
            })) {
                Label("Voice commands", systemImage: voice.isListening ? "waveform" : "mic")
            }
            .accessibilityIdentifier("cookingVoiceCommands")
            Picker("Command language", selection: $language) {
                ForEach(CookingVoiceLanguage.allCases) { language in
                    Text(language.title).tag(language)
                }
            }
            .pickerStyle(.menu)
            Text(language.examples).font(.footnote).foregroundStyle(.secondary)
            Text("Commands listen between readings. Use Pause to interrupt reading. Microphone access is used only while voice commands are on; recognition stays on this iPhone.")
                .font(.footnote).foregroundStyle(.secondary)
            if voice.isRequestingPermission { ProgressView("Waiting for permission…") }
            if let message = voice.message {
                Text(message).font(.footnote).foregroundStyle(.secondary)
                if message.contains("Settings") {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }.font(.footnote)
                }
            }
        }
        .tint(SazliTheme.terracotta)
        .padding(20)
        .recipePanel(cornerRadius: 24)
        .accessibilityIdentifier("cookingVoiceAssistance")
        .onChange(of: language) { _, value in Task { await voice.changeLanguage(value) } }
    }
}
