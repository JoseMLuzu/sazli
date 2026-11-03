# Cooking timer

Open a recipe, choose **Start cooking**, and tap the timer icon in the navigation bar.

1. Enter minutes and seconds, or choose a 1-, 5-, or 10-minute preset.
2. Tap **Start timer**. On first use, iOS asks whether Sazli may send notifications.
3. Use **Pause timer**, **Resume timer**, or **Cancel timer** as needed. **Done** closes the controls and keeps the timer running.
4. Continue reading steps, close cooking mode, or leave the app. A timer summary in cooking and the library opens the same controls.
5. At zero, the summary shows **Timer finished** and the controls show **Time's up**. **Dismiss timer** clears it.

There is one timer at a time across Sazli, labeled with its original recipe and step. Changing steps does not restart or reassign it. Opening another recipe lets you manage the existing timer; cancel it before starting another. Duration can be changed after canceling. Valid durations are at least one second and less than 24 hours, with seconds from 0 through 59. Times are entered manually and are not inferred from recipe text.

The timer stores its deadline or paused remaining time locally in UserDefaults. Closing the controls, leaving cooking, and restarting the app do not reset it. An expired timer stays visible until dismissed. No recipe fields or cooking checklist data are modified.

## Alerts

Sazli schedules a single local notification with a default sound. It does not need a server, remote-notification entitlement, or continuous background execution. Pausing/canceling removes its pending and delivered notification; resuming schedules the remaining duration. Notifications can appear while Sazli is open or in the background. The first permission request occurs only after an explicit Start timer action.

If permission is denied or scheduling fails, the countdown still works and the controls explain that an outside-app alert is unavailable. Changing permission in iOS Settings and reopening the controls refreshes the alert status. iOS notification settings, Focus, and sound settings control delivery and audibility; this is a normal app notification, not a critical alarm.

## Implementation and verification

- `CookingTimerStore.swift`: Codable timer state, deadline calculations, explicit transitions, local persistence, and notification coordination.
- `CookingTimerNotifications.swift`: UserNotifications permission, scheduling, cancellation, and foreground presentation.
- `CookingTimerView.swift`: duration entry, countdown controls, and a reusable summary.
- `CookingModeView.swift` and `LibraryView.swift`: entry points and shared timer presentation.
- `CookingTimerTests.swift`: deterministic elapsed-time, pause/resume, restoration, expiry, denial, scheduling failure, validation, single-timer checks.. Test notification requests are faked and never prompt or schedule real alerts.

See the [verification record](VERIFICATION.md) for performed native checks. Full lock-screen notification sound and Focus behavior on physical devices remain part of release acceptance.

Apple references: [local notifications](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app), [notification authorization](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)), and [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview).
