import XCTest
@testable import Sazli

final class CookingTimerTests: XCTestCase {
  func testDeadlineSurvivesMissedTicksAndPauseDoesNotConsumeTime() {
    let start = Date(timeIntervalSince1970: 1_000)
    var timer = CookingTimerState(recipeID: UUID(), recipeTitle: "Soup", stepNumber: 2,
                                  seconds: 120, now: start)
    XCTAssertEqual(timer.countdown(at: start.addingTimeInterval(30.2)), "01:30")
    timer.pause(at: start.addingTimeInterval(30))
    XCTAssertEqual(timer.phase(at: start.addingTimeInterval(500)), .paused)
    XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(500)), 90)
    timer.resume(at: start.addingTimeInterval(500))
    XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(530)), 60)
    XCTAssertEqual(timer.phase(at: start.addingTimeInterval(590)), .finished)
    XCTAssertEqual(timer.countdown(at: start.addingTimeInterval(600)), "00:00")
    XCTAssertTrue(timer.isValid)
  }

  @MainActor func testRunningAndExpiredTimerRestoreWithoutRestartingDuration() async throws {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    var now = Date(timeIntervalSince1970: 2_000)
    let store = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    let id = UUID()
    await store.start(recipeID: id, title: "Pasta", stepNumber: 3, seconds: 60)
    XCTAssertEqual(fixture.alerts.scheduled.count, 1)
    XCTAssertTrue(try XCTUnwrap(store.timer).hasScheduledAlert)
    now = now.addingTimeInterval(20)
    let reopened = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    XCTAssertEqual(reopened.timer?.recipeID, id)
    XCTAssertEqual(reopened.timer?.remaining(at: now), 40)
    XCTAssertEqual(reopened.timer?.id, store.timer?.id)
    now = now.addingTimeInterval(100)
    let expired = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    XCTAssertEqual(expired.timer?.phase(at: now), .finished)
    XCTAssertEqual(expired.timer?.countdown(at: now), "00:00")
  }

  @MainActor func testPauseResumeAndCancelUpdateSavedStateAndAlerts() async throws {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    var now = Date(timeIntervalSince1970: 3_000)
    let store = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    await store.start(recipeID: UUID(), title: "Rice", stepNumber: 1, seconds: 100)
    now = now.addingTimeInterval(25)
    store.pause()
    XCTAssertEqual(fixture.alerts.removals, 1)
    XCTAssertFalse(try XCTUnwrap(store.timer).hasScheduledAlert)
    now = now.addingTimeInterval(500)
    let reopened = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    XCTAssertEqual(reopened.timer?.phase(at: now), .paused)
    XCTAssertEqual(reopened.timer?.remaining(at: now), 75)
    await reopened.resume()
    XCTAssertEqual(reopened.timer?.deadline, now.addingTimeInterval(75))
    XCTAssertEqual(fixture.alerts.scheduled.count, 2)
    reopened.cancel()
    XCTAssertEqual(fixture.alerts.removals, 2)
    XCTAssertNil(reopened.timer)
    XCTAssertNil(fixture.defaults.data(forKey: CookingTimerStore.storageKey))
  }

  @MainActor func testDeniedPermissionStillStartsTimerAndCanRecoverPermission() async {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    fixture.alerts.allowed = false
    let store = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts)
    await store.start(recipeID: UUID(), title: "Eggs", stepNumber: 1, seconds: 10)
    XCTAssertNotNil(store.timer)
    XCTAssertFalse(store.timer?.hasScheduledAlert ?? true)
    XCTAssertTrue(fixture.alerts.scheduled.isEmpty)
    XCTAssertNotNil(store.notice)
    fixture.alerts.allowed = true
    await store.refreshAlertStatus()
    XCTAssertEqual(fixture.alerts.scheduled.count, 1)
    XCTAssertTrue(store.timer?.hasScheduledAlert ?? false)
    XCTAssertNil(store.notice)
  }

  @MainActor func testFailedSchedulingRetainsWorkingTimerAndReportsFailure() async {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    fixture.alerts.failsScheduling = true
    let store = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts)
    await store.start(recipeID: UUID(), title: "Bread", stepNumber: 2, seconds: 600)
    XCTAssertNotNil(store.timer)
    XCTAssertFalse(store.timer?.hasScheduledAlert ?? true)
    XCTAssertNotNil(store.notice)
    XCTAssertFalse(store.isUpdating)
  }

  @MainActor func testInvalidDurationAndSecondTimerDoNotReplaceCurrentTimer() async throws {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    let store = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts)
    for duration in [0, -1, 86_400, Int.max] {
      await store.start(recipeID: UUID(), title: "Invalid", stepNumber: 1, seconds: duration)
      XCTAssertNil(store.timer)
    }
    XCTAssertEqual(fixture.alerts.permissions, 0)
    await store.start(recipeID: UUID(), title: "First", stepNumber: 1, seconds: 30)
    let first = try XCTUnwrap(store.timer)
    await store.start(recipeID: UUID(), title: "Second", stepNumber: 1, seconds: 10)
    XCTAssertEqual(store.timer, first)
    XCTAssertEqual(fixture.alerts.scheduled.count, 1)
  }

  func testHoursAndInvalidRestoredValues() {
    let now = Date()
    var timer = CookingTimerState(recipeID: UUID(), recipeTitle: "Roast", stepNumber: 1,
                                  seconds: 3_661, now: now)
    XCTAssertEqual(timer.countdown(at: now), "01:01:01")
    XCTAssertEqual(timer.remaining(at: now.addingTimeInterval(-500)), timer.duration)
    timer.pausedRemaining = .infinity
    XCTAssertFalse(timer.isValid)
    timer.pausedRemaining = -1
    XCTAssertFalse(timer.isValid)
  }

  @MainActor private func fixture() -> (name: String, defaults: UserDefaults, alerts: TimerNotificationsFake) {
    let name = "SazliTimerTests.\(UUID().uuidString)"
    return (name, UserDefaults(suiteName: name)!, TimerNotificationsFake())
  }
}

@MainActor private final class TimerNotificationsFake: CookingTimerNotifying {
  var allowed = true
  var failsScheduling = false
  var permissions = 0
  var removals = 0
  var scheduled: [CookingTimerState] = []
  func requestPermission() async throws -> Bool { permissions += 1; return allowed }
  func alertsAllowed() async -> Bool { allowed }
  func schedule(_ timer: CookingTimerState, now: Date) async throws {
    if failsScheduling { throw CocoaError(.fileWriteUnknown) }
    scheduled.append(timer)
  }
  func remove() { removals += 1 }
}
