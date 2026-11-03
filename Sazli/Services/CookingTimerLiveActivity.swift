import ActivityKit
import OSLog
import UIKit

@MainActor
protocol CookingTimerActivityUpdating {
  func synchronize(_ timer: CookingTimerState?, now: Date, requestIfNeeded: Bool) async
}

extension CookingTimerState {
  func activityContent(at date: Date) -> CookingTimerAttributes.ContentState {
    let phase: CookingTimerAttributes.ContentState.Phase = switch phase(at: date) {
    case .running: .running
    case .paused: .paused
    case .finished: .finished
    }
    return .init(phase: phase, deadline: phase == .running ? deadline : nil,
                 remainingSeconds: Int(ceil(remaining(at: date))), durationSeconds: Int(duration))
  }
}

@MainActor
final class CookingTimerLiveActivity: CookingTimerActivityUpdating {
  static let shared = CookingTimerLiveActivity()
  private let logger = Logger(subsystem: "com.sazli.app", category: "CookingTimerActivity")
  private var pendingTimerID: UUID?

  func synchronize(_ timer: CookingTimerState?, now: Date, requestIfNeeded: Bool) async {
    if requestIfNeeded { pendingTimerID = timer?.id }
    if timer == nil || pendingTimerID != timer?.id { pendingTimerID = nil }
    let state = timer?.activityContent(at: now)
    let content = state.map { ActivityContent(state: $0, staleDate: $0.deadline, relevanceScore: 100) }
    var updatedExisting = false
    // Each handle is used once, keeping legacy ActivityKit references local to its operation.
    for activity in Activity<CookingTimerAttributes>.activities {
      if activity.attributes.timerID != timer?.id || updatedExisting {
        await activity.end(nil, dismissalPolicy: .immediate)
      } else if state?.phase == .finished {
        await activity.end(content, dismissalPolicy: .immediate)
      } else if let content, activity.activityState == .active || activity.activityState == .stale {
        updatedExisting = true
        await activity.update(content)
      }
    }
    guard let timer, let content, state?.phase != .finished else { pendingTimerID = nil; return }
    if updatedExisting { pendingTimerID = nil }
    if !updatedExisting && pendingTimerID == timer.id && ActivityAuthorizationInfo().areActivitiesEnabled
        && UIApplication.shared.applicationState == .active {
      do {
        _ = try Activity.request(
          attributes: CookingTimerAttributes(timerID: timer.id, recipeTitle: String(timer.recipeTitle.prefix(180)),
                                              stepNumber: timer.stepNumber),
          content: content, pushType: nil)
        pendingTimerID = nil
      } catch {
        logger.error("Couldn't start the timer Live Activity: \(error.localizedDescription, privacy: .public)")
      }
    }
  }
}
