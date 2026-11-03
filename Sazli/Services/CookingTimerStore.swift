import Foundation
import Observation

struct CookingTimerState: Codable, Equatable, Identifiable, Sendable {
  enum Phase { case running, paused, finished }

  let id: UUID
  let recipeID: UUID
  let recipeTitle: String
  let stepNumber: Int
  let duration: TimeInterval
  var deadline: Date?
  var pausedRemaining: TimeInterval
  var hasScheduledAlert = false

  init(recipeID: UUID, recipeTitle: String, stepNumber: Int, seconds: Int, now: Date) {
    id = UUID()
    self.recipeID = recipeID
    self.recipeTitle = recipeTitle
    self.stepNumber = stepNumber
    duration = TimeInterval(seconds)
    deadline = now.addingTimeInterval(duration)
    pausedRemaining = duration
  }

  func remaining(at date: Date) -> TimeInterval {
    min(duration, max(0, deadline.map { $0.timeIntervalSince(date) } ?? pausedRemaining))
  }

  func phase(at date: Date) -> Phase {
    if remaining(at: date) <= 0 { return .finished }
    return deadline == nil ? .paused : .running
  }

  mutating func pause(at date: Date) {
    pausedRemaining = remaining(at: date)
    deadline = nil
    hasScheduledAlert = false
  }

  mutating func resume(at date: Date) {
    guard deadline == nil, pausedRemaining > 0 else { return }
    deadline = date.addingTimeInterval(pausedRemaining)
  }

  var isValid: Bool {
    duration.isFinite && (1...86_399).contains(duration)
      && pausedRemaining.isFinite && (0...duration).contains(pausedRemaining)
      && (deadline?.timeIntervalSinceReferenceDate.isFinite ?? true) && stepNumber > 0
  }

  func countdown(at date: Date) -> String {
    let seconds = Int(ceil(min(86_399, remaining(at: date))))
    if seconds >= 3_600 {
      return String(format: "%02d:%02d:%02d", seconds / 3_600, seconds / 60 % 60, seconds % 60)
    }
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
}

@MainActor
protocol CookingTimerNotifying {
  func requestPermission() async throws -> Bool
  func alertsAllowed() async -> Bool
  func schedule(_ timer: CookingTimerState, now: Date) async throws
  func remove()
}

/// A single device-local timer, independent of recipe persistence and view lifetimes.
@MainActor @Observable
final class CookingTimerStore {
  static let shared = CookingTimerStore()
  static let storageKey = "cookingTimer.v1"
  private(set) var timer: CookingTimerState?
  private(set) var isUpdating = false
  private(set) var notice: String?
  @ObservationIgnored private let defaults: UserDefaults
  @ObservationIgnored private let notifications: any CookingTimerNotifying
  @ObservationIgnored private let now: () -> Date

  init(defaults: UserDefaults = .standard,
       notifications: any CookingTimerNotifying = CookingTimerNotifications.shared,
       now: @escaping () -> Date = Date.init) {
    self.defaults = defaults
    self.notifications = notifications
    self.now = now
    if let data = defaults.data(forKey: Self.storageKey) {
      do {
        let restored = try JSONDecoder().decode(CookingTimerState.self, from: data)
        guard restored.isValid else { throw TimerError.invalidState }
        timer = restored
      } catch { notice = "The previous timer couldn't be restored. You can start a new one." }
    }
  }

  func start(recipeID: UUID, title: String, stepNumber: Int, seconds: Int) async {
    guard !isUpdating else { return }
    guard timer == nil else { notice = "Cancel the current timer before starting another."; return }
    guard (1...86_399).contains(seconds), stepNumber > 0 else {
      notice = "Choose a duration greater than zero and under 24 hours."
      return
    }
    isUpdating = true
    defer { isUpdating = false }
    let allowed = await permission()
    let candidate = CookingTimerState(recipeID: recipeID, recipeTitle: title,
                                     stepNumber: stepNumber, seconds: seconds, now: now())
    guard save(candidate) else { return }
    await scheduleIfAllowed(allowed)
  }

  func pause() {
    guard !isUpdating, var candidate = timer, candidate.deadline != nil else { return }
    candidate.pause(at: now())
    guard save(candidate) else { return }
    notifications.remove()
    notice = nil
  }

  func resume() async {
    guard !isUpdating, var candidate = timer, candidate.phase(at: now()) == .paused else { return }
    isUpdating = true
    defer { isUpdating = false }
    let allowed = await permission()
    candidate.resume(at: now())
    guard save(candidate) else { return }
    await scheduleIfAllowed(allowed)
  }

  func cancel() {
    guard !isUpdating else { return }
    notifications.remove()
    defaults.removeObject(forKey: Self.storageKey)
    timer = nil
    notice = nil
  }

  func refreshAlertStatus() async {
    guard !isUpdating, let timer, timer.phase(at: now()) == .running else { return }
    let allowed = await notifications.alertsAllowed()
    guard !isUpdating, self.timer?.id == timer.id, timer.phase(at: now()) == .running else { return }
    if !allowed {
      notice = "Notifications are off. Keep Sazli open to see when time is up."
    } else if !timer.hasScheduledAlert || notice != nil {
      isUpdating = true
      defer { isUpdating = false }
      notice = nil
      await scheduleIfAllowed(true)
    }
  }

  private func permission() async -> Bool {
    do {
      let allowed = try await notifications.requestPermission()
      notice = allowed ? nil : "Notifications are off. Keep Sazli open to see when time is up."
      return allowed
    } catch {
      notice = "Notification permission couldn't be checked. The timer will still work in Sazli."
      return false
    }
  }

  private func scheduleIfAllowed(_ allowed: Bool) async {
    guard allowed, var candidate = timer else { return }
    do {
      try await notifications.schedule(candidate, now: now())
      candidate.hasScheduledAlert = true
      _ = save(candidate)
    } catch { notice = "The timer is running, but its alert couldn't be scheduled. Keep Sazli open." }
  }

  @discardableResult private func save(_ candidate: CookingTimerState) -> Bool {
    do {
      let data = try JSONEncoder().encode(candidate)
      defaults.set(data, forKey: Self.storageKey)
      timer = candidate
      return true
    } catch {
      notice = "The timer couldn't be saved. Please try again."
      return false
    }
  }

  private enum TimerError: Error { case invalidState }
}
