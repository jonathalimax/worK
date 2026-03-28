# Native Break Notifications — Design Spec

**Date:** 2026-03-27

---

## Goal

Replace the custom `NSPanel` break reminder with macOS native `UNUserNotificationCenter` notifications. The notification includes a motivational message and a "Take a Break" action button that stops work tracking when tapped.

---

## Architecture

`ReminderService` schedules a `UNNotificationRequest` instead of showing an `NSPanel`. `AppDelegate` conforms to `UNUserNotificationCenterDelegate` to handle permission setup and action responses. Both files need `import UserNotifications`.

**Files deleted:**
- `worK/Features/Reminder/ReminderPanelController.swift`
- `worK/Features/Reminder/ReminderOverlayView.swift`

**Files modified:**
- `worK/Features/Reminder/ReminderService.swift`
- `worK/App/AppDelegate.swift`

---

## Notification Design

**Category identifier:** `"BREAK_REMINDER"`

**Action:** `UNNotificationAction(identifier: "TAKE_BREAK", title: "Take a Break", options: [])`

**Content:**
- `title`: random motivational title from pool (see below)
- `body`: random motivational body from pool, interpolating the worked time
- `sound`: `.default`
- `categoryIdentifier`: `"BREAK_REMINDER"`

**Notification identifier:** `"break-reminder"` — single fixed identifier so each new reminder overwrites the previous one; only one reminder is ever pending or visible.

---

## Motivational Message Pool

A caseless `enum BreakReminderMessages` with a `static func random(workedTime: String) -> (String, String)` defined at the bottom of `ReminderService.swift`. Six title/body pairs:

| Title | Body |
|---|---|
| "Time for a break" | "You've been focused for \(workedTime). Step away — you'll come back sharper." |
| "You've earned it" | "\(workedTime) of deep work. A short pause now pays off later." |
| "Rest is productive" | "After \(workedTime), your brain needs a reset. Take a few minutes." |
| "Take a breather" | "\(workedTime) in. A walk, some water, a stretch — pick one." |
| "Pause and recharge" | "Great focus for \(workedTime). Rest is part of the work." |
| "Step away for a bit" | "\(workedTime) done. The best ideas come after breaks." |

---

## ReminderService Changes

Add `import UserNotifications` at the top.

Remove the `private let panelController = ReminderPanelController()` property.

Remove `panelController.dismiss()` from `stopMonitoring()`.

Replace `checkAndShowReminder()` body:

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

---

## AppDelegate Changes

Add `import UserNotifications` at the top.

Add a stored analytics property to the class body (so the delegate extension can access it):
```swift
@Dependency(\.analyticsClient) private var analytics
```

In `applicationDidFinishLaunching`, after existing setup, add permission request and category registration. `setNotificationCategories` is called unconditionally on every launch — this is required to ensure the category and action are always registered:

```swift
UNUserNotificationCenter.current().delegate = self

UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

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
```

Add `UNUserNotificationCenterDelegate` conformance as an extension **in the same file** (`AppDelegate.swift`) so it has access to the `private` `statusBarController` and `analytics` properties:

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "TAKE_BREAK" {
            Task { @MainActor in
                await self.statusBarController?.viewModel.stopWork()
            }
            analytics.track(.reminderTakeBreakTapped)
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
```

The `willPresent` override is needed so the notification banner appears even when worK is the active process (menu bar apps still receive this callback).

---

## Analytics Changes

- `reminderShown` — unchanged, fires before scheduling
- `reminderTakeBreakTapped` — fires in the delegate action handler
- `reminderDismissed` — **no longer called** (macOS doesn't reliably fire delegate for banner dismiss)
- `reminderAutoDismissed` — **no longer called** (no concept of auto-dismiss with UNNotifications)

The `AnalyticsEvent` cases `reminderDismissed` and `reminderAutoDismissed` remain in the enum but are dead code going forward.

---

## Permission Denied Behavior

If the user has denied notification permission in System Settings, `UNUserNotificationCenter.add(_:)` silently fails. No fallback UI, no error state. The reminder enabled toggle in Settings continues to control the timer — it just never fires a visible notification.

---

## Non-Goals

- No in-app permission prompt or settings deep-link
- No fallback to the old NSPanel if notifications are denied
- No dynamic/AI-generated notification messages
