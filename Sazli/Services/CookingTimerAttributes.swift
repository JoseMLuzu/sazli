import ActivityKit
import Foundation

/// Shared with the Live Activity extension without accessing the recipe store.
struct CookingTimerAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable, Sendable {
    enum Phase: String, Codable, Sendable { case running, paused, finished }
    let phase: Phase
    let deadline: Date?
    let remainingSeconds: Int
    let durationSeconds: Int

    var countdownRange: ClosedRange<Date>? {
      guard phase == .running, let deadline else { return nil }
      return deadline.addingTimeInterval(-Double(durationSeconds))...deadline
    }

    var formattedRemaining: String {
      let seconds = max(0, remainingSeconds)
      if seconds >= 3_600 {
        return String(format: "%02d:%02d:%02d", seconds / 3_600, seconds / 60 % 60, seconds % 60)
      }
      return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
  }

  let timerID: UUID
  let recipeTitle: String
  let stepNumber: Int
}
