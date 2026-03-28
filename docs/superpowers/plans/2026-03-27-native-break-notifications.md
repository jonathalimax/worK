# Native Break Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the custom NSPanel break reminder with macOS native UNUserNotificationCenter notifications that include a motivational message and a "Take a Break" action button.

**Architecture:** `ReminderService` schedules a `UNNotificationRequest` with a random motivational message. `AppDelegate` registers the notification category + action on every launch, conforms to `UNUserNotificationCenterDelegate`, and calls `viewModel.stopWork()` when the action is tapped. Two old files (`ReminderPanelController.swift`, `ReminderOverlayView.swift`) are deleted entirely.

**Tech Stack:** `UserNotifications` framework (macOS), PointFree swift-dependencies, SwiftUI/AppKit.

---

## File Map

| Action | Path | What changes |
|---|---|---|
| **Modify** | `worK/Features/Reminder/ReminderService.swift` | Remove panelController, replace `checkAndShowReminder`, add `BreakReminderMessages` enum |
| **Modify** | `worK/App/AppDelegate.swift` | Add stored analytics, UNUserNotificationCenter setup, delegate conformance |
| **Delete** | `worK/Features/Reminder/ReminderPanelController.swift` | No longer used |
| **Delete** | `worK/Features/Reminder/ReminderOverlayView.swift` | No longer used |
| **Modify** | `worK.xcodeproj/project.pbxproj` | Remove deleted files from build phases |

---

## Task 1: Update ReminderService

**Files:**
- Modify: `worK/Features/Reminder/ReminderService.swift`

Replace the entire file contents with the following. Key changes from current:
- Add `import UserNotifications`
- Remove `private let panelController = ReminderPanelController()`
- Remove `panelController.dismiss()` from `stopMonitoring()`
- Replace `checkAndShowReminder()` body — schedule a `UNNotificationRequest` instead of showing the panel
- Add `BreakReminderMessages` caseless enum at the bottom of the file

- [ ] **Step 1: Replace the file**

```swift
import Dependencies
import Foundation
import Observation
import UserNotifications

// MARK: - ReminderService

@Observable
@MainActor
final class ReminderService {
	// MARK: - Dependencies

	@ObservationIgnored @Dependency(\.settingsClient) private var settingsClient
	@ObservationIgnored @Dependency(\.continuousClock) private var clock
	@ObservationIgnored @Dependency(\.analyticsClient) private var analytics

	// MARK: - Properties

	private var monitoringTask: Task<Void, Never>?
	private weak var viewModel: WorkDayViewModel?

	// MARK: - Initialization

	init() {}

	// MARK: - Monitoring

	func startMonitoring(viewModel: WorkDayViewModel) {
		self.viewModel = viewModel
		monitoringTask?.cancel()
		monitoringTask = Task { @MainActor [weak self] in
			guard let self else { return }
			while !Task.isCancelled {
				let intervalMinutes = settingsClient.reminderIntervalMinutes()
				let intervalSeconds = max(intervalMinutes, 1) * 60
				try? await clock.sleep(for: .seconds(intervalSeconds))
				guard !Task.isCancelled else { break }
				await self.checkAndShowReminder()
			}
		}
	}

	func stopMonitoring() {
		monitoringTask?.cancel()
		monitoringTask = nil
	}

	/// Resets the reminder countdown. Call when work resumes after a break so the
	/// timer starts fresh from the configured interval.
	func resetTimer() {
		guard let viewModel else { return }
		startMonitoring(viewModel: viewModel)
	}

	// MARK: - Private Helpers

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
			trigger: nil
		)

		try? await UNUserNotificationCenter.current().add(request)
	}
}

// MARK: - BreakReminderMessages

private enum BreakReminderMessages {
	private static let messages: [(String, String)] = [
		(
			String(localized: "Time for a break"),
			String(localized: "You've been focused for {time}. Step away — you'll come back sharper.")
		),
		(
			String(localized: "You've earned it"),
			String(localized: "{time} of deep work. A short pause now pays off later.")
		),
		(
			String(localized: "Rest is productive"),
			String(localized: "After {time}, your brain needs a reset. Take a few minutes.")
		),
		(
			String(localized: "Take a breather"),
			String(localized: "{time} in. A walk, some water, a stretch — pick one.")
		),
		(
			String(localized: "Pause and recharge"),
			String(localized: "Great focus for {time}. Rest is part of the work.")
		),
		(
			String(localized: "Step away for a bit"),
			String(localized: "{time} done. The best ideas come after breaks.")
		),
	]

	static func random(workedTime: String) -> (String, String) {
		let (title, body) = messages.randomElement()!
		return (title, body.replacingOccurrences(of: "{time}", with: workedTime))
	}
}
```

Note: `String(localized:)` is used for title and body strings so they are picked up by the localization system. The `{time}` placeholder is replaced at call time rather than at compile time to keep the strings localizable.

- [ ] **Step 2: Build to verify no errors**

```bash
xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD" | tail -5
```

Expected: `** BUILD SUCCEEDED **` (ReminderPanelController still exists, so there are no missing-type errors yet)

- [ ] **Step 3: Commit**

```bash
git add worK/Features/Reminder/ReminderService.swift
git commit -m "feat: replace panel reminder with UNUserNotificationCenter"
```

---

## Task 2: Update AppDelegate

**Files:**
- Modify: `worK/App/AppDelegate.swift`

Key changes from current:
- Add `import UserNotifications`
- Add `@Dependency(\.analyticsClient) private var analytics` as a **stored property** on the class (replaces the local `@Dependency` vars in each method — remove those)
- Add UNUserNotificationCenter setup in `applicationDidFinishLaunching`
- Add `UNUserNotificationCenterDelegate` extension **in the same file**

- [ ] **Step 1: Replace the file**

```swift
import AppKit
import Dependencies
import SwiftUI
import TelemetryDeck
import UserNotifications

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusBarController: StatusBarController?
	private var reminderService: ReminderService?

	@Dependency(\.analyticsClient) private var analytics

	@MainActor
	func applicationDidFinishLaunching(_ notification: Notification) {
		// Hide dock icon -- this is a menubar-only app
		NSApp.setActivationPolicy(.accessory)

		// Initialize Sparkle auto-updater
		_ = SparkleCoordinator.shared

		// Initialize the status bar
		let controller = StatusBarController()
		statusBarController = controller

		analytics.track(.appLaunched)

		// Initialize break reminder service
		let service = ReminderService()
		service.startMonitoring(viewModel: controller.viewModel)
		reminderService = service

		// Reset reminder timer whenever work resumes after a break
		controller.viewModel.onWorkResumed = { [weak service] in
			service?.resetTimer()
		}

		// Reset reminder timer when the interval setting changes
		controller.viewModel.onReminderIntervalChanged = { [weak service] in
			service?.resetTimer()
		}

		// Set up native notifications
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
	}

	@MainActor
	func applicationWillTerminate(_ notification: Notification) {
		analytics.track(.appTerminated)
		reminderService?.stopMonitoring()
		reminderService = nil
		statusBarController?.tearDown()
		statusBarController = nil
	}
}

// MARK: - UNUserNotificationCenterDelegate

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

- [ ] **Step 2: Build to verify no errors**

```bash
xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add worK/App/AppDelegate.swift
git commit -m "feat: add UNUserNotificationCenter setup and Take a Break action handler"
```

---

## Task 3: Delete Old Reminder Files

**Files:**
- Delete: `worK/Features/Reminder/ReminderPanelController.swift`
- Delete: `worK/Features/Reminder/ReminderOverlayView.swift`
- Modify: `worK.xcodeproj/project.pbxproj` (remove file references)

- [ ] **Step 1: Delete the files from disk**

```bash
rm worK/Features/Reminder/ReminderPanelController.swift
rm worK/Features/Reminder/ReminderOverlayView.swift
```

- [ ] **Step 2: Remove from Xcode project**

Open `worK.xcodeproj/project.pbxproj` and remove all references to both files:
- Search for `ReminderPanelController.swift` — remove the `PBXBuildFile` entry, the `PBXFileReference` entry, and remove it from the `PBXSourcesBuildPhase` files list and the `PBXGroup` children list
- Do the same for `ReminderOverlayView.swift`

There should be 4 entries to remove per file (PBXBuildFile, PBXFileReference, one line in SourcesBuildPhase files array, one line in the PBXGroup children array).

- [ ] **Step 3: Build to verify clean**

```bash
xcodebuild -scheme worK -configuration Debug build 2>&1 | grep -E "error:|BUILD" | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add -A worK/Features/Reminder/ worK.xcodeproj/project.pbxproj
git commit -m "chore: delete ReminderPanelController and ReminderOverlayView"
```

---

## Task 4: Final Verification

- [ ] **Step 1: Clean build**

```bash
xcodebuild -scheme worK -configuration Debug clean build 2>&1 | grep -E "error:|BUILD" | grep -v appintents | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Manual smoke test**

Launch the app. Go to Settings → set reminder interval to 15 minutes. Wait 15 minutes (or temporarily lower `AppConstants.defaultReminderIntervalMinutes` for testing). Verify:
- A native macOS banner notification appears
- It has a "Take a Break" action button
- Tapping "Take a Break" stops the work timer (status bar goes idle)
- The notification appears even while the app is "active" (menu bar apps don't truly foreground, but this confirms the `willPresent` delegate fires)

- [ ] **Step 3: Verify notification permission prompt**

On a fresh install or after resetting notification permissions (`tccutil reset Notifications`), launch the app and confirm macOS shows the permission request dialog.

- [ ] **Step 4: Final commit if any fixups needed**

```bash
git add -A
git commit -m "fix: <describe any fixup>"
```
