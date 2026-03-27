# TelemetryDeck Analytics Integration — Design Spec

**Date:** 2026-03-27
**App ID:** `562F4D05-44DA-41BF-B640-671ED4C1EBBE`

---

## Goal

Integrate TelemetryDeck to track every user interaction in the worK macOS menu bar app. Tracking is silent — no opt-out toggle, no consent screen (TelemetryDeck is privacy-first by design: no PII, hashed identifiers, GDPR-compliant).

---

## Architecture

A new `AnalyticsClient` dependency following the existing `Dependencies` pattern (same as `SettingsClient`, `NotificationClient`), using the `@DependencyClient` macro from `DependenciesMacros`.

**Files to create:**
- `worK/Dependencies/AnalyticsClient.swift` — client struct, `AnalyticsEvent` enum, `SettingKey` enum, `DependencyKey` conformance, `DependencyValues` extension, live + test implementations

**Files to modify:**
- `worK/App/worKApp.swift` — add TelemetryDeck SDK initialization in `prepareDependencies`
- `worK/App/AppDelegate.swift` — call `appLaunched` after SDK is ready; call `appTerminated`
- `worK/StatusBar/StatusBarController.swift` — panel open/close, menu actions, quit intercept
- `worK/StatusBar/PopoverContentView.swift` — tab navigation, history expand, registered toggle, chart navigation
- `worK/Features/Tracking/WorkDayViewModel.swift` — work/break lifecycle, day completed
- `worK/Features/Reminder/ReminderService.swift` — reminder shown
- `worK/Features/Reminder/ReminderPanelController.swift` — reminder auto-dismissed
- `worK/Features/Reminder/ReminderOverlayView.swift` — reminder dismissed / take break tapped
- `worK/Features/Settings/SettingsView.swift` — every settings change
- `worK/Features/Dashboard/DashboardView.swift` — AI message refresh

**SDK:** Add `TelemetryDeck/SwiftSDK` via Swift Package Manager (`https://github.com/TelemetryDeck/SwiftSDK`, from `2.0.0`).

**Initialization:** In `worKApp.swift` `prepareDependencies`, register the dependency and call `TelemetryDeck.initialize(...)`. Then fire `appLaunched` in `AppDelegate.applicationDidFinishLaunching` after `StatusBarController` is initialized — guaranteeing the SDK is live before any signal is sent.

---

## AnalyticsClient

Uses the `@DependencyClient` macro, consistent with the codebase pattern:

```swift
@DependencyClient
struct AnalyticsClient {
    var track: (AnalyticsEvent) -> Void = { _ in }
}

extension AnalyticsClient: DependencyKey {
    static let liveValue = AnalyticsClient(
        track: { event in
            TelemetryDeck.signal(event.name, parameters: event.parameters)
        }
    )
    static let testValue = AnalyticsClient()   // no-op via @DependencyClient default
    static let previewValue = AnalyticsClient()
}

extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
```

Usage at any call site:
```swift
@Dependency(\.analyticsClient) private var analytics
analytics.track(.workStarted)
analytics.track(.settingChanged(.targetHours, value: "8.5"))
```

`@Dependency(\.analyticsClient)` must be added to any class that fires events, including `ReminderService` and `ReminderPanelController`.

---

## AnalyticsEvent Enum

```swift
enum AnalyticsEvent {
    // App lifecycle
    case appLaunched
    case appTerminated

    // Panel
    case popoverOpened(source: String)      // "leftClick" | "menu"
    case popoverClosed
    case tabViewed(PopoverTab)

    // Work tracking
    case workStarted
    case workStopped
    case workDayCompleted(hoursWorked: String)

    // Breaks
    case breakStarted(source: String)       // "screenLock" | "manual"
    case breakEnded(source: String)         // "screenUnlock" | "manual"

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
    case historyRegisteredToggled(value: String)    // "true" | "false"
    case chartMonthNavigated(direction: String)     // "previous" | "next"

    // Support / About
    case supportGithubSponsorsTapped
    case updatesCheckTapped
    case aiMessageRefreshed
}
```

Each case maps to a `name: String` and `parameters: [String: String]` via computed properties on the enum.

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

---

## Event Placement

| Event | Location | Notes |
|---|---|---|
| `appLaunched` | `AppDelegate.applicationDidFinishLaunching` | After `StatusBarController` init, SDK is guaranteed ready |
| `appTerminated` | `AppDelegate.applicationWillTerminate` | |
| `popoverOpened("leftClick")` | `StatusBarController.togglePopover()` | On the show branch |
| `popoverOpened("menu")` | `StatusBarController.openToday/History/Settings()` | Before `showPanel()` |
| `popoverClosed` | `StatusBarController.dismissPanel()` | |
| `tabViewed` | `PopoverContentView` | `.onAppear` for initial tab + `.onChange(of: selectedTab)` |
| `workStarted` | `WorkDayViewModel.startWork()` | After `trackingState = .working` |
| `workStopped` | `WorkDayViewModel.stopWork()` | After `trackingState = .idle` |
| `workDayCompleted` | `WorkDayViewModel.refreshStats()` AND `WorkDayViewModel.tick()` | Both places set `trackingState = .completed`; guard against double-fire with a flag |
| `breakStarted("manual")` | `WorkDayViewModel.takeBreak()` | Fire before `screenLockClient.lockScreen()` — covers both success and fallback paths |
| `breakStarted("screenLock")` | `WorkDayViewModel.handleScreenEvent(.locked)` | Only when not already tracking manually |
| `breakEnded("screenUnlock")` | `WorkDayViewModel.handleScreenEvent(.unlocked)` | |
| `breakEnded("manual")` | `WorkDayViewModel.startWork()` when called from `toggleWork()` | Differentiate by adding a `source` parameter to `startWork()`, or by tracking in `toggleWork()` directly |
| `reminderShown` | `ReminderService.checkAndShowReminder()` | `workedTime` is already computed there |
| `reminderDismissed` | `ReminderOverlayView` dismiss button action | |
| `reminderTakeBreakTapped` | `ReminderOverlayView` take break button action | |
| `reminderAutoDismissed` | `ReminderPanelController` auto-dismiss task, before `dismiss()` | |
| `settingChanged` | Each `onChange` modifier in `SettingsView` | |
| `menuTodayTapped` | `StatusBarController.openToday()` | |
| `menuHistoryTapped` | `StatusBarController.openHistory()` | |
| `menuSettingsTapped` | `StatusBarController.openSettings()` | |
| `menuQuitTapped` | New `@objc openQuit()` method in `StatusBarController` | Replace direct `NSApplication.terminate` target; method fires event then calls `NSApp.terminate(nil)` |
| `historyItemExpanded` | `PopoverContentView` — `onTap` closure in history list | |
| `historyRegisteredToggled` | `PopoverContentView` — `onToggleRegistered` closure | |
| `chartMonthNavigated("previous")` | `PopoverContentView` — prev month button | |
| `chartMonthNavigated("next")` | `PopoverContentView` — next month button | |
| `supportGithubSponsorsTapped` | `SettingsView` GitHub Sponsors button | |
| `updatesCheckTapped` | `SettingsView` Check for Updates button | |
| `aiMessageRefreshed` | `DashboardView` refresh button | |

---

## Known Limitation

`autoStopSection` is defined in `SettingsView` but not rendered in `body` (existing bug — the section is built but never inserted into the view hierarchy). As a result, `settingChanged(.stopRecordingEnabled)` and `settingChanged(.stopRecordingTime)` will never fire until that section is added back to `body`. This is out of scope for this spec but should be noted as a follow-up.

---

## Error Handling

TelemetryDeck signals are fire-and-forget. Failed signals are silently dropped by the SDK. No error handling needed.

---

## Non-Goals

- No opt-out toggle in Settings
- No local event batching or caching layer
- No custom dashboards defined here (TelemetryDeck web UI handles that)
