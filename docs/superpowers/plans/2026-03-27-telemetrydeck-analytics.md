# TelemetryDeck Analytics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate TelemetryDeck to silently track every user interaction in the worK macOS menu bar app via a typed `AnalyticsClient` dependency.

**Architecture:** A new `AnalyticsClient` struct using the `@DependencyClient` macro (same pattern as `SettingsClient`) holds a single `track(_ event: AnalyticsEvent) -> Void` function. All event names and parameters are derived from typed Swift enums — no string literals at call sites. The live implementation forwards to `TelemetryDeck.signal(...)`.

**Tech Stack:** TelemetryDeck SwiftSDK 2.x (SPM), PointFree swift-dependencies + DependenciesMacros, SwiftUI, AppKit.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| **Create** | `worK/Dependencies/AnalyticsClient.swift` | Client struct, all event/key enums, live + no-op implementations |
| **Modify** | `worK/App/worKApp.swift` | SDK initialization |
| **Modify** | `worK/App/AppDelegate.swift` | `appLaunched`, `appTerminated` |
| **Modify** | `worK/StatusBar/StatusBarController.swift` | Panel open/close, menu events, quit intercept |
| **Modify** | `worK/StatusBar/PopoverContentView.swift` | Tab view, history, chart events |
| **Modify** | `worK/Features/Tracking/WorkDayViewModel.swift` | Work/break lifecycle, day completed |
| **Modify** | `worK/Features/Reminder/ReminderService.swift` | `reminderShown` |
| **Modify** | `worK/Features/Reminder/ReminderPanelController.swift` | `reminderAutoDismissed` |
| **Modify** | `worK/Features/Reminder/ReminderOverlayView.swift` | `reminderDismissed`, `reminderTakeBreakTapped` |
| **Modify** | `worK/Features/Settings/SettingsView.swift` | All `settingChanged` events |
| **Modify** | `worK/Features/Dashboard/AIMessageView.swift` | `aiMessageRefreshed` |

---

## Task 1: Add TelemetryDeck SDK via Swift Package Manager

**Files:**
- Modify: `worK.xcodeproj/project.pbxproj` (via Xcode SPM UI)

- [ ] **Step 1: Add the package in Xcode**

  In Xcode: File → Add Package Dependencies...
  URL: `https://github.com/TelemetryDeck/SwiftSDK`
  Version rule: "Up to Next Major" from `2.0.0`
  Add to target: `worK`

- [ ] **Step 2: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add worK.xcodeproj/
  git commit -m "chore: add TelemetryDeck SwiftSDK package"
  ```

---

## Task 2: Create AnalyticsClient with All Enums

**Files:**
- Create: `worK/Dependencies/AnalyticsClient.swift`

- [ ] **Step 1: Create the file and add it to the Xcode target**

  After creating the file, open Xcode → select `AnalyticsClient.swift` in the Project Navigator → in the File Inspector (right panel) ensure the `worK` target checkbox is ticked under "Target Membership".

  ```swift
  import Dependencies
  import DependenciesMacros
  import TelemetryDeck

  // MARK: - Supporting Enums

  enum PopoverSource: String {
      case leftClick = "leftClick"
      case menu = "menu"
  }

  enum BreakSource: String {
      case screenLock = "screenLock"
      case manual = "manual"
  }

  enum BreakEndSource: String {
      case screenUnlock = "screenUnlock"
      case manual = "manual"
  }

  enum ChartDirection: String {
      case previous = "previous"
      case next = "next"
  }

  enum SettingKey: String {
      case targetHours = "targetHours"
      case reminderEnabled = "reminderEnabled"
      case reminderInterval = "reminderInterval"
      case launchAtLogin = "launchAtLogin"
      case stopRecordingEnabled = "stopRecordingEnabled"
      case stopRecordingTime = "stopRecordingTime"
      case registerExternally = "registerExternally"
  }

  // MARK: - AnalyticsEvent

  enum AnalyticsEvent {
      // App lifecycle
      case appLaunched
      case appTerminated

      // Panel
      case popoverOpened(source: PopoverSource)
      case popoverClosed
      case tabViewed(PopoverTab)

      // Work tracking
      case workStarted
      case workStopped
      case workDayCompleted(hoursWorked: String)

      // Breaks
      case breakStarted(source: BreakSource)
      case breakEnded(source: BreakEndSource)

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
      case historyRegisteredToggled(Bool)
      case chartMonthNavigated(ChartDirection)

      // Support / About
      case supportGithubSponsorsTapped
      case updatesCheckTapped
      case aiMessageRefreshed

      // MARK: - TelemetryDeck mapping

      var signalName: String {
          switch self {
          case .appLaunched: return "app.launched"
          case .appTerminated: return "app.terminated"
          case .popoverOpened: return "popover.opened"
          case .popoverClosed: return "popover.closed"
          case .tabViewed: return "tab.viewed"
          case .workStarted: return "work.started"
          case .workStopped: return "work.stopped"
          case .workDayCompleted: return "work.dayCompleted"
          case .breakStarted: return "break.started"
          case .breakEnded: return "break.ended"
          case .reminderShown: return "reminder.shown"
          case .reminderDismissed: return "reminder.dismissed"
          case .reminderTakeBreakTapped: return "reminder.takeBreakTapped"
          case .reminderAutoDismissed: return "reminder.autoDismissed"
          case .settingChanged: return "settings.changed"
          case .menuTodayTapped: return "menu.todayTapped"
          case .menuHistoryTapped: return "menu.historyTapped"
          case .menuSettingsTapped: return "menu.settingsTapped"
          case .menuQuitTapped: return "menu.quitTapped"
          case .historyItemExpanded: return "history.itemExpanded"
          case .historyRegisteredToggled: return "history.registeredToggled"
          case .chartMonthNavigated: return "chart.monthNavigated"
          case .supportGithubSponsorsTapped: return "support.githubSponsorsTapped"
          case .updatesCheckTapped: return "updates.checkTapped"
          case .aiMessageRefreshed: return "aiMessage.refreshed"
          }
      }

      var parameters: [String: String] {
          switch self {
          case .popoverOpened(let source):
              return ["source": source.rawValue]
          case .tabViewed(let tab):
              return ["tab": tab.rawValue]
          case .workDayCompleted(let hours):
              return ["hoursWorked": hours]
          case .breakStarted(let source):
              return ["source": source.rawValue]
          case .breakEnded(let source):
              return ["source": source.rawValue]
          case .reminderShown(let time):
              return ["workedTime": time]
          case .settingChanged(let key, let value):
              return ["key": key.rawValue, "value": value]
          case .historyRegisteredToggled(let value):
              return ["value": value ? "true" : "false"]
          case .chartMonthNavigated(let direction):
              return ["direction": direction.rawValue]
          default:
              return [:]
          }
      }
  }

  // MARK: - AnalyticsClient

  @DependencyClient
  struct AnalyticsClient: Sendable {
      var track: @Sendable (AnalyticsEvent) -> Void = { _ in }
  }

  extension AnalyticsClient: DependencyKey {
      static let liveValue = AnalyticsClient(
          track: { event in
              TelemetryDeck.signal(event.signalName, parameters: event.parameters)
          }
      )
  }

  extension DependencyValues {
      var analyticsClient: AnalyticsClient {
          get { self[AnalyticsClient.self] }
          set { self[AnalyticsClient.self] = newValue }
      }
  }
  ```

- [ ] **Step 2: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add worK/Dependencies/AnalyticsClient.swift
  git commit -m "feat: add AnalyticsClient dependency with full event taxonomy"
  ```

---

## Task 3: Initialize SDK in worKApp + Fire appLaunched/appTerminated

**Files:**
- Modify: `worK/App/worKApp.swift`
- Modify: `worK/App/AppDelegate.swift`

- [ ] **Step 1: Initialize SDK in worKApp.swift**

  Add `import TelemetryDeck` at the top of `worKApp.swift` alongside the other imports.

  Inside `prepareDependencies { ... }`, after the database setup, add:
  ```swift
  TelemetryDeck.initialize(
      config: TelemetryManagerConfiguration(
          appID: "562F4D05-44DA-41BF-B640-671ED4C1EBBE"
      )
  )
  ```

- [ ] **Step 2: Fire appLaunched and appTerminated in AppDelegate.swift**

  Add `@Dependency(\.analyticsClient) private var analytics` to `AppDelegate`.

  In `applicationDidFinishLaunching`, after `StatusBarController()` init:
  ```swift
  analytics.track(.appLaunched)
  ```

  In `applicationWillTerminate`:
  ```swift
  analytics.track(.appTerminated)
  ```

- [ ] **Step 3: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add worK/App/worKApp.swift worK/App/AppDelegate.swift
  git commit -m "feat: initialize TelemetryDeck and track app lifecycle events"
  ```

---

## Task 4: Track Panel and Menu Events in StatusBarController

**Files:**
- Modify: `worK/StatusBar/StatusBarController.swift`

- [ ] **Step 1: Add dependency and panel tracking**

  Add to `StatusBarController`:
  ```swift
  @ObservationIgnored @Dependency(\.analyticsClient) private var analytics
  ```

  In `showPanel()`, after `self.panel = panel`:
  ```swift
  analytics.track(.popoverOpened(source: panelSource))
  ```

  Add a stored property `private var panelSource: PopoverSource = .leftClick`.

  In `togglePopover()` (show branch), set `panelSource = .leftClick` before `showPanel()`.

  In `dismissPanel()`, before `NSAnimationContext.runAnimationGroup`:
  ```swift
  analytics.track(.popoverClosed)
  ```

- [ ] **Step 2: Track menu open source**

  In `openToday()`, set `panelSource = .menu` before calling `showPanel()`:
  ```swift
  analytics.track(.menuTodayTapped)
  panelSource = .menu
  ```

  Same pattern for `openHistory()`:
  ```swift
  analytics.track(.menuHistoryTapped)
  panelSource = .menu
  ```

  Same for `openSettings()`:
  ```swift
  analytics.track(.menuSettingsTapped)
  panelSource = .menu
  ```

- [ ] **Step 3: Add openQuit() to intercept quit for tracking**

  Replace the quit `NSMenuItem` target from `NSApplication.terminate` to a new method:

  ```swift
  @objc private func openQuit() {
      analytics.track(.menuQuitTapped)
      NSApp.terminate(nil)
  }
  ```

  In `makeContextMenu()`, change:
  ```swift
  // Before:
  let quitItem = NSMenuItem(title: ..., action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

  // After:
  let quitItem = NSMenuItem(title: ..., action: #selector(openQuit), keyEquivalent: "q")
  quitItem.target = self
  ```

- [ ] **Step 4: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

  ```bash
  git add worK/StatusBar/StatusBarController.swift
  git commit -m "feat: track panel open/close and menu events"
  ```

---

## Task 5: Track Tab Navigation, History, and Chart Events in PopoverContentView

**Files:**
- Modify: `worK/StatusBar/PopoverContentView.swift`

- [ ] **Step 1: Add dependency**

  `PopoverContentView` is a SwiftUI `View` struct. Use `@Dependency` inline at call sites (same pattern as `DashboardView.shouldShowReminder`):
  ```swift
  @Dependency(\.analyticsClient) private var analytics
  ```
  Add this as a property on the struct.

- [ ] **Step 2: Track initial tab and tab changes**

  In `body`, add after the `VStack`:
  ```swift
  .onAppear {
      analytics.track(.tabViewed(selectedTab))
  }
  .onChange(of: selectedTab) { _, newTab in
      analytics.track(.tabViewed(newTab))
  }
  ```

- [ ] **Step 3: Track history item expanded**

  In `historyList`, inside the `onTap` closure:
  ```swift
  onTap: {
      analytics.track(.historyItemExpanded)
      withAnimation(.smooth(duration: 0.3)) { ... }
  }
  ```

- [ ] **Step 4: Track registered toggled**

  In `historyList`, inside `onToggleRegistered`:
  ```swift
  onToggleRegistered: {
      let newValue = !workDay.isRegistered
      analytics.track(.historyRegisteredToggled(newValue))
      Task { await historyViewModel.toggleRegistered(for: workDay.id) }
  }
  ```
  Note: `workDay.isRegistered` is the current value before toggle, so `!workDay.isRegistered` is the new value.

- [ ] **Step 5: Track chart month navigation**

  In the previous month button action:
  ```swift
  analytics.track(.chartMonthNavigated(.previous))
  Task { await chartViewModel.navigateToPreviousMonth() }
  ```

  In the next month button action:
  ```swift
  analytics.track(.chartMonthNavigated(.next))
  Task { await chartViewModel.navigateToNextMonth() }
  ```

- [ ] **Step 6: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

  ```bash
  git add worK/StatusBar/PopoverContentView.swift
  git commit -m "feat: track tab navigation, history, and chart events"
  ```

---

## Task 6: Track Work and Break Lifecycle in WorkDayViewModel

**Files:**
- Modify: `worK/Features/Tracking/WorkDayViewModel.swift`

- [ ] **Step 1: Add dependency and dayCompleted guard**

  Add to `WorkDayViewModel`:
  ```swift
  @ObservationIgnored @Dependency(\.analyticsClient) private var analytics
  @ObservationIgnored private var didTrackDayCompleted = false
  ```

  Reset `didTrackDayCompleted` in `ensureTodayExists()` (called on day change) or at the start of `start()`.

- [ ] **Step 2: Track workStarted and workStopped**

  In `startWork()`, after `trackingState = .working`:
  ```swift
  analytics.track(.workStarted)
  ```

  In `stopWork()`, after `trackingState = .idle`:
  ```swift
  analytics.track(.workStopped)
  ```

- [ ] **Step 3: Track workDayCompleted (both paths)**

  In `refreshStats()`, where `trackingState = .completed` is set, wrap with the guard:
  ```swift
  if !didTrackDayCompleted {
      didTrackDayCompleted = true
      analytics.track(.workDayCompleted(hoursWorked: String(format: "%.1f", workedSeconds / 3600)))
  }
  trackingState = .completed
  ```

  Apply the same guard in `tick()` where auto-stop sets `trackingState = .completed`.

- [ ] **Step 4: Track break events**

  In `takeBreak()`, before `screenLockClient.lockScreen()`:
  ```swift
  analytics.track(.breakStarted(source: .manual))
  ```

  In `handleScreenEvent(.locked)`:
  ```swift
  analytics.track(.breakStarted(source: .screenLock))
  ```

  In `handleScreenEvent(.unlocked)`:
  ```swift
  analytics.track(.breakEnded(source: .screenUnlock))
  ```

  In `toggleWork()`, in the `.onBreak` case before calling `stopWork()` (manual resume):
  ```swift
  case .working, .onBreak:
      analytics.track(.breakEnded(source: .manual))
      await stopWork()
  ```
  Note: `.onBreak` in `toggleWork()` is the only manual "end break" path distinct from a screen unlock.

- [ ] **Step 5: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

  ```bash
  git add worK/Features/Tracking/WorkDayViewModel.swift
  git commit -m "feat: track work and break lifecycle events"
  ```

---

## Task 7: Track Reminder Events

**Files:**
- Modify: `worK/Features/Reminder/ReminderService.swift`
- Modify: `worK/Features/Reminder/ReminderPanelController.swift`
- Modify: `worK/Features/Reminder/ReminderOverlayView.swift`

- [ ] **Step 1: Track reminderShown in ReminderService**

  Add to `ReminderService`:
  ```swift
  @ObservationIgnored @Dependency(\.analyticsClient) private var analytics
  ```

  In `checkAndShowReminder()`, after computing `workedTime`:
  ```swift
  analytics.track(.reminderShown(workedTime: workedTime))
  ```

- [ ] **Step 2: Track reminderAutoDismissed in ReminderPanelController**

  Add to `ReminderPanelController`:
  ```swift
  @Dependency(\.analyticsClient) private var analytics
  ```

  In the auto-dismiss task, before calling `self?.dismiss()`:
  ```swift
  analytics.track(.reminderAutoDismissed)
  self?.dismiss()
  ```

- [ ] **Step 3: Track reminderDismissed and reminderTakeBreakTapped in ReminderOverlayView**

  Add to `ReminderOverlayView`:
  ```swift
  @Dependency(\.analyticsClient) private var analytics
  ```

  In the Dismiss button action:
  ```swift
  analytics.track(.reminderDismissed)
  withAnimation(.easeIn(duration: 0.2)) { opacity = 0 }
  ...
  ```

  In the Take a Break button action:
  ```swift
  analytics.track(.reminderTakeBreakTapped)
  withAnimation(.easeIn(duration: 0.2)) { opacity = 0 }
  ...
  ```

- [ ] **Step 4: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

  ```bash
  git add worK/Features/Reminder/ReminderService.swift worK/Features/Reminder/ReminderPanelController.swift worK/Features/Reminder/ReminderOverlayView.swift
  git commit -m "feat: track reminder shown, dismissed, and auto-dismissed events"
  ```

---

## Task 8: Track Settings Changes in SettingsView

**Files:**
- Modify: `worK/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Add dependency**

  Add to `SettingsView`:
  ```swift
  @Dependency(\.analyticsClient) private var analytics
  ```

- [ ] **Step 2: Add tracking to each onChange**

  In `workSection` — target hours slider:
  ```swift
  .onChange(of: targetHours) { _, newValue in
      analytics.track(.settingChanged(.targetHours, value: String(format: "%.1f", newValue)))
      // existing code
  }
  ```

  In `remindersSection` — register externally toggle:
  ```swift
  .onChange(of: registerExternally) { _, newValue in
      analytics.track(.settingChanged(.registerExternally, value: String(newValue)))
      // existing code
  }
  ```

  Reminder enabled toggle:
  ```swift
  .onChange(of: reminderEnabled) { _, newValue in
      analytics.track(.settingChanged(.reminderEnabled, value: String(newValue)))
      // existing code
  }
  ```

  Reminder interval slider:
  ```swift
  .onChange(of: reminderIntervalMinutes) { _, newValue in
      analytics.track(.settingChanged(.reminderInterval, value: "\(Int(newValue))"))
      // existing code
  }
  ```

  In `generalSection` — launch at login toggle:
  ```swift
  .onChange(of: launchAtLogin) { _, newValue in
      analytics.track(.settingChanged(.launchAtLogin, value: String(newValue)))
      // existing code
  }
  ```

  Note: `stopRecordingEnabled` and `stopRecordingTime` are in `autoStopSection` which is currently not rendered in `body` (existing bug). Add tracking to those `onChange` handlers anyway for when the section is re-enabled.

- [ ] **Step 3: Track support and about actions**

  In the GitHub Sponsors button:
  ```swift
  analytics.track(.supportGithubSponsorsTapped)
  if let url = URL(string: AppConstants.githubSponsorsURL) { ... }
  ```

  In the Check for Updates button:
  ```swift
  analytics.track(.updatesCheckTapped)
  updateClient.checkForUpdates()
  ```

- [ ] **Step 4: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

  ```bash
  git add worK/Features/Settings/SettingsView.swift
  git commit -m "feat: track all settings changes and support actions"
  ```

---

## Task 9: Track AI Message Refresh in AIMessageView

**Files:**
- Modify: `worK/Features/Dashboard/AIMessageView.swift`

  Note: The spec lists `DashboardView.swift` but the refresh button lives in `AIMessageView.swift` (the subcomponent). `AIMessageView` is the correct target.

- [ ] **Step 1: Add dependency and tracking**

  Add to `AIMessageView`:
  ```swift
  @Dependency(\.analyticsClient) private var analytics
  ```

  In the refresh button action:
  ```swift
  Button {
      analytics.track(.aiMessageRefreshed)
      Task { await loadMessage() }
  }
  ```

- [ ] **Step 2: Verify build**

  ```bash
  xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD"
  ```
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

  ```bash
  git add worK/Features/Dashboard/AIMessageView.swift
  git commit -m "feat: track AI message refresh event"
  ```

---

## Task 10: Final Verification

- [ ] **Step 1: Full clean build**

  ```bash
  xcodebuild -scheme worK -configuration Debug clean build 2>&1 | grep -E "error:|warning:|BUILD" | grep -v appintents
  ```
  Expected: `** BUILD SUCCEEDED **` with no new warnings.

- [ ] **Step 2: Run the app and verify signals in TelemetryDeck**

  Launch the app. Open the panel (left-click) → switch tabs → open Settings → change a setting → right-click menu → dismiss. Then check the TelemetryDeck dashboard (Signal Explorer) to confirm events are arriving.

- [ ] **Step 3: Final commit**

  ```bash
  git add docs/
  git commit -m "chore: mark analytics plan complete"
  ```
