import UIKit

@MainActor
final class CookingScreenSession {
    private var previousIdleTimerValue: Bool?

    func activate() {
        guard previousIdleTimerValue == nil else { return }
        previousIdleTimerValue = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func restore() {
        guard let previousIdleTimerValue else { return }
        UIApplication.shared.isIdleTimerDisabled = previousIdleTimerValue
        self.previousIdleTimerValue = nil
    }
}
