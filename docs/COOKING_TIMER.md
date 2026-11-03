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

## Dynamic Island and Lock Screen

Starting a timer also requests a local Live Activity when iOS permits it. Compatible iPhones show the remaining time in Dynamic Island, with a minimal timer icon when space is shared. Touch and hold the island for the expanded recipe/step view. Other supported devices can show the Lock Screen card. Tapping the activity opens Sazli; pause, resume, and cancel remain in the app's timer controls.

Live Activity permission is separate from notification permission. iOS may ask **Allow Live Activities from Sazli?** on the Lock Screen card. If Live Activities are disabled, the existing countdown and notification continue working. There is no backend, ActivityKit push token, App Group, or extension access to the recipe database.

The system draws a countdown from the same deadline used by Sazli. Pausing updates it to a frozen value; resuming updates the deadline. Canceling ends it immediately. Expiry ends the activity while Sazli is executing, and foreground reconciliation removes expired or orphaned activities. When iOS suspends or terminates Sazli, the system countdown stops at zero and stale content indicates **Time's up** until the app can reconcile or iOS removes it. No continuous background execution or exact background removal is claimed. Reopening the app updates an existing activity without recreating one the user dismissed.

Apple limits Live Activity duration; it can stop before a timer longer than eight hours completes. The saved timer and its local notification remain independent. See [Apple's Live Activity constraints](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).

## Implementation and verification

- `CookingTimerStore.swift`: Codable timer state, deadline calculations, explicit transitions, local persistence, and notification coordination.
- `CookingTimerNotifications.swift`: UserNotifications permission, scheduling, cancellation, and foreground presentation.
- `CookingTimerView.swift`: duration entry, countdown controls, and a reusable summary.
- `CookingTimerAttributes.swift`: the shared, small ActivityKit payload compiled into both targets.
- `CookingTimerLiveActivity.swift`: native authorization, activity reconciliation, updates, and ending.
- `SazliLiveActivity/`: the embedded WidgetKit extension for compact/minimal/expanded Dynamic Island and Lock Screen layouts.
- `CookingModeView.swift` and `LibraryView.swift`: entry points and shared timer presentation.
- `CookingTimerTests.swift`: deterministic elapsed-time, pause/resume, restoration, expiry, denial, scheduling failure, validation, single-timer, and Live Activity transition/payload checks. Test notification/activity adapters are faked and never prompt, schedule real alerts, or create Live Activities.

See the [verification record](VERIFICATION.md) for performed native checks. Full lock-screen notification sound and Focus behavior on physical devices remain part of release acceptance.

Apple references: [local notifications](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app), [notification authorization](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)), and [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview).
