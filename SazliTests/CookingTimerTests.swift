import XCTest
@testable import Sazli

final class CookingTimerTests: XCTestCase {
  @MainActor func testLiveActivityFollowsStartPauseResumeAndCancelWithoutNotificationPermission() async throws {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    fixture.alerts.allowed = false
    let activity = TimerActivityFake()
    var now = Date(timeIntervalSince1970: 5_000)
    let store = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts,
                                  activity: activity, now: { now })
    await store.start(recipeID: UUID(), title: "Soup", stepNumber: 2, seconds: 120)
    XCTAssertEqual(activity.latest?.phase, .running)
    XCTAssertEqual(activity.requests, [true])
    now = now.addingTimeInterval(30)
    await store.pause()
    XCTAssertEqual(activity.latest?.phase, .paused)
    XCTAssertEqual(activity.latest?.remainingSeconds, 90)
    XCTAssertNil(activity.latest?.deadline)
    now = now.addingTimeInterval(300)
    await store.resume()
    XCTAssertEqual(activity.latest?.deadline, now.addingTimeInterval(90))
    XCTAssertEqual(activity.requests, [true, false, false])
    await store.cancel()
    XCTAssertEqual(activity.requests, [true, false, false, false])
    XCTAssertNil(activity.latest)
    XCTAssertNil(store.timer)
  }

  @MainActor func testLiveActivityRestoreAndExpiryDoNotRequestAnotherActivity() async {
    let fixture = fixture()
    defer { fixture.defaults.removePersistentDomain(forName: fixture.name) }
    let activity = TimerActivityFake()
    var now = Date(timeIntervalSince1970: 6_000)
    let original = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    await original.start(recipeID: UUID(), title: "Rice", stepNumber: 1, seconds: 60)
    let restored = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts,
                                     activity: activity, now: { now })
    now = now.addingTimeInterval(20)
    await restored.refreshLiveActivity()
    XCTAssertEqual(activity.latest?.remainingSeconds, 40)
    XCTAssertEqual(activity.requests, [false])
    now = now.addingTimeInterval(100)
    await restored.refreshLiveActivity()
    XCTAssertEqual(activity.latest?.phase, .finished)
    XCTAssertEqual(activity.latest?.remainingSeconds, 0)
    XCTAssertEqual(activity.requests, [false, false])
    await restored.cancel()
  }

  func testLiveActivityContentHasStableRangeAndFrozenPausedReadout() {
    let now = Date(timeIntervalSince1970: 7_000)
    var timer = CookingTimerState(recipeID: UUID(), recipeTitle: "Roast", stepNumber: 1,
                                  seconds: 3_661, now: now)
    let running = timer.activityContent(at: now.addingTimeInterval(61))
    XCTAssertEqual(running.countdownRange, now...now.addingTimeInterval(3_661))
    XCTAssertEqual(running.remainingSeconds, 3_600)
    timer.pause(at: now.addingTimeInterval(61))
    let paused = timer.activityContent(at: now.addingTimeInterval(500))
    XCTAssertNil(paused.countdownRange)
    XCTAssertEqual(paused.formattedRemaining, "01:00:00")
    XCTAssertEqual(paused.phase, .paused)
  }

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
    await store.pause()
    XCTAssertEqual(fixture.alerts.removals, 1)
    XCTAssertFalse(try XCTUnwrap(store.timer).hasScheduledAlert)
    now = now.addingTimeInterval(500)
    let reopened = CookingTimerStore(defaults: fixture.defaults, notifications: fixture.alerts, now: { now })
    XCTAssertEqual(reopened.timer?.phase(at: now), .paused)
    XCTAssertEqual(reopened.timer?.remaining(at: now), 75)
    await reopened.resume()
    XCTAssertEqual(reopened.timer?.deadline, now.addingTimeInterval(75))
    XCTAssertEqual(fixture.alerts.scheduled.count, 2)
    await reopened.cancel()
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

@MainActor private final class TimerActivityFake: CookingTimerActivityUpdating {
  var states: [CookingTimerAttributes.ContentState?] = []
  var requests: [Bool] = []
  var latest: CookingTimerAttributes.ContentState? { states.last ?? nil }
  func synchronize(_ timer: CookingTimerState?, now: Date, requestIfNeeded: Bool) async {
    states.append(timer?.activityContent(at: now))
    requests.append(requestIfNeeded)
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
