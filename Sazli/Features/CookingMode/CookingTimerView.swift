import SwiftUI

struct CookingTimerView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @State private var store = CookingTimerStore.shared
  let recipeID: UUID
  let recipeTitle: String
  let stepNumber: Int
  @State private var minutes = "5"
  @State private var seconds = "00"
  @FocusState private var durationFocused: Bool

  private var duration: Int? {
    guard let minutes = Int(minutes), let seconds = Int(seconds),
          (0...1_439).contains(minutes), (0...59).contains(seconds) else { return nil }
    let total = minutes * 60 + seconds
    return total > 0 ? total : nil
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          VStack(alignment: .leading, spacing: 6) {
            Text(store.timer?.recipeTitle ?? recipeTitle).font(.headline)
            Text("Step \(store.timer?.stepNumber ?? stepNumber)")
              .font(.subheadline).foregroundStyle(.secondary)
          }
          if let timer = store.timer {
            TimelineView(.periodic(from: .now, by: 1)) { context in
              activeTimer(timer, at: context.date)
            }
          } else {
            durationForm
          }
          if let notice = store.notice {
            Label(notice, systemImage: "bell.slash")
              .font(.footnote).foregroundStyle(.secondary)
          }
        }
        .padding(24)
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
      .sazliScreen()
      .navigationTitle("Timer").navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }.disabled(store.isUpdating)
        }
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Done") { durationFocused = false }
        }
      }
      .interactiveDismissDisabled(store.isUpdating)
      .task { await store.refreshAlertStatus() }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active { Task { await store.refreshAlertStatus() } }
      }
    }
  }

  private var durationForm: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 16) {
        durationField("Minutes", text: $minutes)
        Text(":").font(.largeTitle).accessibilityHidden(true)
        durationField("Seconds", text: $seconds)
      }
      HStack(spacing: 12) {
        ForEach([1, 5, 10], id: \.self) { value in
          Button("\(value) min") {
            minutes = "\(value)"; seconds = "00"; durationFocused = false
          }
          .buttonStyle(.bordered).frame(maxWidth: .infinity, minHeight: 44)
        }
      }
      if duration == nil {
        Text("Choose a duration greater than zero and under 24 hours. Seconds must be between 0 and 59.")
          .font(.footnote).foregroundStyle(.secondary)
      }
      PrimaryButton(title: store.isUpdating ? "Starting…" : "Start timer", symbol: "play.fill") {
        guard let duration else { return }
        durationFocused = false
        Task { await store.start(recipeID: recipeID, title: recipeTitle,
                                 stepNumber: stepNumber, seconds: duration) }
      }
      .disabled(duration == nil || store.isUpdating)
      Text("Allow notifications when you start a timer to receive an alert outside Sazli.")
        .font(.footnote).foregroundStyle(.secondary)
    }
  }

  private func durationField(_ title: String, text: Binding<String>) -> some View {
    VStack(spacing: 8) {
      TextField("00", text: text)
        .keyboardType(.numberPad).multilineTextAlignment(.center)
        .font(.largeTitle.monospacedDigit())
        .focused($durationFocused)
        .accessibilityLabel(title)
        .padding(16).recipePanel(cornerRadius: 20)
      Text(title).font(.caption).foregroundStyle(.secondary)
    }
  }

  private func activeTimer(_ timer: CookingTimerState, at date: Date) -> some View {
    let phase = timer.phase(at: date)
    return VStack(spacing: 24) {
      VStack(spacing: 12) {
        Text(phase == .finished ? "Time's up" : phase == .paused ? "Paused" : "Time remaining")
          .font(.subheadline.weight(.medium)).foregroundStyle(SazliTheme.terracotta)
        Text(timer.countdown(at: date))
          .font(.system(.largeTitle, design: .rounded, weight: .semibold).monospacedDigit())
          .accessibilityLabel("Time remaining").accessibilityValue(timer.countdown(at: date))
        ProgressView(value: min(timer.duration, timer.remaining(at: date)), total: timer.duration)
          .tint(SazliTheme.terracotta).accessibilityLabel("Timer remaining")
      }
      .padding(24).frame(maxWidth: .infinity).recipePanel()
      if phase == .finished {
        PrimaryButton(title: "Dismiss timer", symbol: "checkmark") { store.cancel(); dismiss() }
      } else {
        PrimaryButton(title: phase == .paused ? "Resume timer" : "Pause timer",
                      symbol: phase == .paused ? "play.fill" : "pause.fill") {
          if phase == .paused { Task { await store.resume() } }
          else { store.pause() }
        }
        Button("Cancel timer", role: .destructive) { store.cancel() }
          .frame(minHeight: 44)
        if phase == .running {
          Text(timer.hasScheduledAlert && store.notice == nil
               ? "An alert is scheduled. The timer keeps running when you leave cooking mode."
               : "The timer keeps running when you leave cooking mode.")
            .font(.footnote).foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
      }
    }
    .disabled(store.isUpdating)
  }
}

struct CookingTimerSummary: View {
  @State private var store = CookingTimerStore.shared
  let open: () -> Void

  var body: some View {
    if let timer = store.timer {
      TimelineView(.periodic(from: .now, by: 1)) { context in
        let phase = timer.phase(at: context.date)
        Button(action: open) {
          HStack(spacing: 12) {
            Image(systemName: phase == .finished ? "bell.fill" : "timer")
              .foregroundStyle(SazliTheme.terracotta).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
              Text(phase == .finished ? "Timer finished" : "\(phase == .paused ? "Paused" : "Timer") · \(timer.countdown(at: context.date))")
                .font(.subheadline.weight(.semibold)).monospacedDigit()
              Text("\(timer.recipeTitle) · Step \(timer.stepNumber)")
                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
          }
          .padding(14).frame(minHeight: 44)
          .background(SazliTheme.terracotta.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
          .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens timer controls.")
      }
    }
  }
}
