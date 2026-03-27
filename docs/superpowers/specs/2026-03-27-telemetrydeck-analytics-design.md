# TelemetryDeck Analytics Integration — Design Spec

**Date:** 2026-03-27
**App ID:** `562F4D05-44DA-41BF-B640-671ED4C1EBBE`

---

## Goal

Integrate TelemetryDeck to track every user interaction in the worK macOS menu bar app. Tracking is silent — no opt-out toggle, no consent screen (TelemetryDeck is privacy-first by design: no PII, hashed identifiers, GDPR-compliant).

---

## Architecture

A new `AnalyticsClient` dependency following the existing `Dependencies` pattern (same as `SettingsClient`, `NotificationClient`).

**Files to create:**
- `worK/Dependencies/AnalyticsClient.swift` — client struct, `AnalyticsEvent` enum, `SettingKey` enum, live + test implementations

**Files to modify:**
- `worK/App/worKApp.swift` — register `analyticsClient` in `prepareDependencies`, call `app.launched`
- `worK/App/AppDelegate.swift` — call `app.terminated`
- `worK/StatusBar/StatusBarController.swift` — panel open/close, menu actions
- `worK/StatusBar/PopoverContentView.swift` — tab navigation
- `worK/Features/Tracking/WorkDayViewModel.swift` — work/break lifecycle
- `worK/Features/Reminder/ReminderService.swift` — reminder shown
- `worK/Features/Reminder/ReminderOverlayView.swift` — reminder dismissed / take break tapped / auto-dismissed
- `worK/Features/Settings/SettingsView.swift` — every settings change
- `worK/Features/Dashboard/DashboardView.swift` — AI message refresh
- `worK/StatusBar/PopoverContentView.swift` — history item expanded, registered toggled, chart month navigated

**SDK:** Add `TelemetryDeck/SwiftSDK` via Swift Package Manager (`https://github.com/TelemetryDeck/SwiftSDK`, from `2.0.0`).

**Initialization:** In `worKApp.swift` `prepareDependencies`:
```swift
TelemetryDeck.initialize(config: TelemetryManagerConfiguration(appID: "562F4D05-44DA-41BF-B640-671ED4C1EBBE"))
```

---

## AnalyticsClient

```swift
struct AnalyticsClient {
    var track: (AnalyticsEvent) -> Void
}
```

Injected via `@Dependency(\.analyticsClient)`. The live implementation calls:
```swift
TelemetryDeck.signal(event.name, parameters: event.parameters)
```

The test/preview implementation is a no-op.

---

## AnalyticsEvent Enum

```swift
enum AnalyticsEvent {
    // App lifecycle
    case appLaunched
    case appTerminated

    // Panel
    case popoverOpened(source: String)   // "leftClick" | "menu"
    case popoverClosed
    case tabViewed(PopoverTab)

    // Work tracking
    case workStarted
    case workStopped
    case workDayCompleted(hoursWorked: String)

    // Breaks
    case breakStarted(source: String)    // "screenLock" | "manual"
    case breakEnded(source: String)      // "screenUnlock" | "manual"

    // Reminders
    case reminderShown(workedTime: String)
    case reminderDismissed
    case reminderTakeBreakTapped
    case reminderAutoDismissed

    // Settings
    case settingChanged(SettingKey, value: String)

    // Right-click menu
    case menuTodayTapped
    case menuHistoryTapped
    case menuSettingsTapped
    case menuQuitTapped

    // History & Charts
    case historyItemExpanded
    case historyRegisteredToggled(value: String)   // "true" | "false"
    case chartMonthNavigated(direction: String)    // "previous" | "next"

    // Support / About
    case supportGithubSponsorsTapped
    case updatesCheckTapped
    case aiMessageRefreshed
}
```

Each case maps to a `name: String` and `parameters: [String: String]` computed on the enum.

---

## SettingKey Enum

```swift
enum SettingKey {
    case targetHours
    case reminderEnabled
    case reminderInterval
    case launchAtLogin
    case stopRecordingEnabled
    case stopRecordingTime
    case registerExternally

    var name: String { ... }
}
```

Usage: `analytics.track(.settingChanged(.targetHours, value: "8.5"))`

---

## Event Placement

| Event | Location |
|---|---|
| `appLaunched` | `worKApp.init` or `prepareDependencies` |
| `appTerminated` | `AppDelegate.applicationWillTerminate` |
| `popoverOpened(source:)` | `StatusBarController.showPanel()` — "leftClick" for toggle, "menu" for context menu actions |
| `popoverClosed` | `StatusBarController.dismissPanel()` |
| `tabViewed` | `PopoverContentView` — `.onChange(of: selectedTab)` + `.onAppear` |
| `workStarted` | `WorkDayViewModel.startWork()` |
| `workStopped` | `WorkDayViewModel.stopWork()` |
| `workDayCompleted` | `WorkDayViewModel.refreshStats()` when target reached |
| `breakStarted(source:)` | `WorkDayViewModel.startBreak()` ("manual") + `handleScreenEvent(.locked)` ("screenLock") |
| `breakEnded(source:)` | `WorkDayViewModel.startWork()` from unlock ("screenUnlock") + manual resume ("manual") |
| `reminderShown` | `ReminderService.checkAndShowReminder()` |
| `reminderDismissed` | `ReminderOverlayView` dismiss button |
| `reminderTakeBreakTapped` | `ReminderOverlayView` take break button |
| `reminderAutoDismissed` | `ReminderPanelController` auto-dismiss task |
| `settingChanged` | Each `onChange` in `SettingsView` |
| `menuTodayTapped` | `StatusBarController.openToday()` |
| `menuHistoryTapped` | `StatusBarController.openHistory()` |
| `menuSettingsTapped` | `StatusBarController.openSettings()` |
| `menuQuitTapped` | `StatusBarController.makeContextMenu()` quit item |
| `historyItemExpanded` | `PopoverContentView` — `onTap` in history list |
| `historyRegisteredToggled` | `PopoverContentView` — `onToggleRegistered` callback |
| `chartMonthNavigated` | `PopoverContentView` — prev/next month buttons |
| `supportGithubSponsorsTapped` | `SettingsView` GitHub Sponsors button |
| `updatesCheckTapped` | `SettingsView` Check for Updates button |
| `aiMessageRefreshed` | `DashboardView` refresh button |

---

## Error Handling

TelemetryDeck signals fire-and-forget. No error handling needed — failed signals are silently dropped by the SDK.

---

## Non-Goals

- No opt-out toggle in Settings
- No local event batching or caching layer
- No custom dashboards defined here (TelemetryDeck web UI handles that)
