# Native Break Notifications — Design Spec

**Date:** 2026-03-27

---

## Goal

Replace the custom `NSPanel` break reminder with macOS native `UNUserNotificationCenter` notifications. The notification includes a motivational message and a "Take a Break" action button that stops work tracking when tapped.

---

## Architecture

`ReminderService` schedules a `UNNotificationRequest` instead of showing an `NSPanel`. `AppDelegate` conforms to `UNUserNotificationCenterDelegate` to handle permission setup and action responses.

**Files deleted:**
- `worK/Features/Reminder/ReminderPanelController.swift`
- `worK/Features/Reminder/ReminderOverlayView.swift`

**Files modified:**
- `worK/Features/Reminder/ReminderService.swift` — replace panel show with notification scheduling
- `worK/App/AppDelegate.swift` — permission request, category registration, delegate conformance + action handling

---

## Notification Design

**Category identifier:** `"BREAK_REMINDER"`

**Action:** `UNNotificationAction(identifier: "TAKE_BREAK", title: "Take a Break", options: [])`

**Content:**
- `title`: random motivational title from a static pool (see below)
- `body`: random motivational body from a static pool, interpolating the worked time
- `sound`: `.default`
- `categoryIdentifier`: `"BREAK_REMINDER"`

**Notification identifier:** `"break-reminder"` (single, overwriting — only one reminder pending at a time)

---

## Motivational Message Pool

Six title/body pairs, chosen by random index:

| Title | Body |
|---|---|
| "Time for a break" | "You've been focused for \(workedTime). Step away — you'll come back sharper." |
| "You've earned it" | "\(workedTime) of deep work. A short pause now pays off later." |
| "Rest is productive" | "After \(workedTime), your brain needs a reset. Take a few minutes." |
| "Take a breather" | "\(workedTime) in. A walk, some water, a stretch — pick one." |
| "Pause and recharge" | "Great focus for \(workedTime). Rest is part of the work." |
| "Step away for a bit" | "\(workedTime) done. The best ideas come after breaks." |

---

## AppDelegate Changes

### Permission request
In `applicationDidFinishLaunching`, after existing setup:
```swift
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
```

### Category + action registration
```swift
let takeBreakAction = UNNotificationAction(
    identifier: "TAKE_BREAK",
    title: String(localized: "Take a Break"),
    options: []
)
let category = UNNotificationCategory(
    identifier: "BREAK_REMINDER",
    actions: [takeBreakAction],
    intentIdentifiers: [],
    options: []
)
UNUserNotificationCenter.current().setNotificationCategories([category])
UNUserNotificationCenter.current().delegate = self  // AppDelegate as delegate
```

### Delegate conformance
```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "TAKE_BREAK" {
            Task { @MainActor in
                await statusBarController?.viewModel.stopWork()
            }
            analytics.track(.reminderTakeBreakTapped)
        }
        completionHandler()
    }

    // Required so notification shows as banner while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
```

---

## ReminderService Changes

Remove `panelController` property. Replace `checkAndShowReminder()` body:

```swift
private func checkAndShowReminder() async {
    guard settingsClient.reminderEnabled() else { return }
    guard let viewModel, viewModel.trackingState == .working else { return }

    let workedTime = viewModel.workedSeconds.formattedHoursMinutes
    analytics.track(.reminderShown(workedTime: workedTime))

    let (title, body) = BreakReminderMessages.random(workedTime: workedTime)

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.categoryIdentifier = "BREAK_REMINDER"

    let request = UNNotificationRequest(
        identifier: "break-reminder",
        content: content,
        trigger: nil  // deliver immediately
    )

    try? await UNUserNotificationCenter.current().add(request)
}
```

`BreakReminderMessages` is a small enum (or struct) with a `static func random(workedTime: String) -> (String, String)` defined in `ReminderService.swift`.

---

## Analytics Changes

- `reminderShown` — unchanged, fires before scheduling
- `reminderTakeBreakTapped` — fires in the delegate action handler
- `reminderDismissed` — **removed** (macOS doesn't reliably fire delegate for banner dismiss)
- `reminderAutoDismissed` — **removed** (no concept of auto-dismiss in UNNotifications)

The `AnalyticsEvent` cases `reminderDismissed` and `reminderAutoDismissed` remain in the enum (removing them would be a broader change) but will simply never be called.

---

## Permission Denied Behavior

If the user has denied notification permission in System Settings, `UNUserNotificationCenter.add(_:)` silently fails. No fallback UI, no error state. The reminder enabled toggle in Settings continues to function normally — it controls the timer, not the permission.

---

## Non-Goals

- No in-app permission prompt or settings deep-link
- No fallback to the old NSPanel if notifications are denied
- No dynamic/AI-generated notification messages
