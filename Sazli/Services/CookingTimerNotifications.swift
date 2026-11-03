import UserNotifications

@MainActor
final class CookingTimerNotifications: NSObject, CookingTimerNotifying, UNUserNotificationCenterDelegate {
  static let shared = CookingTimerNotifications()
  static let identifier = "sazli.cooking.timer"
  private let center = UNUserNotificationCenter.current()

  private override init() {
    super.init()
    center.delegate = self
  }

  func requestPermission() async throws -> Bool {
    let settings = await center.notificationSettings()
    if settings.authorizationStatus == .notDetermined {
      return try await center.requestAuthorization(options: [.alert, .sound])
    }
    return Self.isAllowed(settings.authorizationStatus)
  }

  func alertsAllowed() async -> Bool {
    Self.isAllowed(await center.notificationSettings().authorizationStatus)
  }

  func schedule(_ timer: CookingTimerState, now: Date) async throws {
    let remaining = timer.remaining(at: now)
    guard remaining > 0, timer.deadline != nil else { return }
    let content = UNMutableNotificationContent()
    content.title = "Timer finished"
    content.body = "\(timer.recipeTitle) · Step \(timer.stepNumber) is ready to check."
    content.sound = .default
    content.userInfo = ["cookingTimerID": timer.id.uuidString]
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, remaining), repeats: false)
    try await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
  }

  func remove() {
    center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
    center.removeDeliveredNotifications(withIdentifiers: [Self.identifier])
  }

  private static func isAllowed(_ status: UNAuthorizationStatus) -> Bool {
    status == .authorized || status == .provisional || status == .ephemeral
  }

  nonisolated func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler(notification.request.identifier == "sazli.cooking.timer" ? [.banner, .list, .sound] : [])
  }
}
