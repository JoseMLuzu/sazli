import ActivityKit
import SwiftUI
import WidgetKit

@main
struct SazliTimerWidgetBundle: WidgetBundle {
  var body: some Widget { SazliTimerLiveActivity() }
}

struct SazliTimerLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CookingTimerAttributes.self) { context in
      TimerLockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("Sazli", systemImage: symbol(context))
            .font(.caption.weight(.semibold)).foregroundStyle(ActivityPalette.terracotta)
            .padding(.leading, 8)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("Step \(context.attributes.stepNumber)").font(.caption).foregroundStyle(.secondary)
            .padding(.trailing, 8)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
              Text(context.attributes.recipeTitle).font(.headline).lineLimit(2)
              Text(status(context)).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ActivityCountdown(state: context.state, isStale: context.isStale)
              .font(.title2.weight(.semibold)).frame(maxWidth: 125, alignment: .trailing)
              .foregroundStyle(ActivityPalette.coral)
          }
          .padding(.top, 6)
          .padding(.horizontal, 6)
        }
      } compactLeading: {
        Image(systemName: symbol(context)).foregroundStyle(ActivityPalette.coral)
      } compactTrailing: {
        ActivityCountdown(state: context.state, isStale: context.isStale)
          .font(.caption.weight(.semibold))
          .frame(width: context.state.durationSeconds >= 3_600 ? 65 : 46)
          .foregroundStyle(ActivityPalette.coral)
      } minimal: {
        Image(systemName: symbol(context)).foregroundStyle(ActivityPalette.coral)
      }
      .keylineTint(ActivityPalette.terracotta)
    }
  }

  private func symbol(_ context: ActivityViewContext<CookingTimerAttributes>) -> String {
    if context.isStale || context.state.phase == .finished { return "bell.fill" }
    return context.state.phase == .paused ? "pause.fill" : "timer"
  }

  private func status(_ context: ActivityViewContext<CookingTimerAttributes>) -> String {
    if context.isStale || context.state.phase == .finished { return "Time's up" }
    return context.state.phase == .paused ? "Paused" : "Cooking timer"
  }
}

private struct TimerLockScreenView: View {
  @Environment(\.colorScheme) private var colorScheme
  let context: ActivityViewContext<CookingTimerAttributes>

  private var finished: Bool { context.isStale || context.state.phase == .finished }

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: finished ? "bell.fill" : context.state.phase == .paused ? "pause.fill" : "timer")
        .font(.title2).foregroundStyle(ActivityPalette.terracotta)
        .frame(width: 44, height: 44)
        .background(ActivityPalette.terracotta.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 5) {
        Text("Sazli · \(finished ? "Time's up" : context.state.phase == .paused ? "Paused" : "Cooking timer")")
          .font(.caption.weight(.semibold)).foregroundStyle(ActivityPalette.terracotta)
        Text(context.attributes.recipeTitle).font(.headline).lineLimit(2)
        Text("Step \(context.attributes.stepNumber)").font(.caption).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      ActivityCountdown(state: context.state, isStale: context.isStale)
        .font(.title2.weight(.semibold)).frame(maxWidth: 125, alignment: .trailing)
    }
    .padding(16)
    .activityBackgroundTint(colorScheme == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : ActivityPalette.cream)
    .activitySystemActionForegroundColor(ActivityPalette.terracotta)
  }
}

private struct ActivityCountdown: View {
  let state: CookingTimerAttributes.ContentState
  let isStale: Bool

  var body: some View {
    Group {
      if isStale || state.phase == .finished {
        Text("00:00")
      } else if let range = state.countdownRange {
        Text(timerInterval: range, countsDown: true, showsHours: state.durationSeconds >= 3_600)
          .multilineTextAlignment(.trailing)
      } else {
        Text(state.formattedRemaining)
      }
    }
    .monospacedDigit()
    .accessibilityLabel(state.phase == .paused ? "Paused timer" : "Time remaining")
  }
}

private enum ActivityPalette {
  static let terracotta = Color(red: 201 / 255, green: 90 / 255, blue: 67 / 255)
  static let coral = Color(red: 1, green: 138 / 255, blue: 115 / 255)
  static let cream = Color(red: 253 / 255, green: 246 / 255, blue: 237 / 255)
}
