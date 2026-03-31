import AppKit
import Dependencies
import SwiftUI
import TelemetryDeck
import UserNotifications

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusBarController: StatusBarController?
	private var reminderService: ReminderService?

	@Dependency(\.analyticsClient) private var analytics

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

		// Send a local notification when the work day is completed
		controller.viewModel.onDayCompleted = {
			@Dependency(\.settingsClient) var settings
			guard settings.registerExternally() else { return }

			let content = UNMutableNotificationContent()
			content.title = String(localized: "Daily goal reached!")
			content.body = String(localized: "Time to register your completed work hours.")
			content.sound = .default
			content.categoryIdentifier = "REGISTER_REMINDER"

			let request = UNNotificationRequest(
				identifier: "register-reminder",
				content: content,
				trigger: nil
			)

			UNUserNotificationCenter.current().add(request) { _ in }
			Task {
				try? await Task.sleep(for: .seconds(30))
				UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["register-reminder"])
			}
		}

		// Set up native notifications
		UNUserNotificationCenter.current().delegate = self
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
			if !granted {
				print("⚠️ Notification permission not granted. Enable in System Settings > Notifications > worK")
			}
		}

		let takeBreakAction = UNNotificationAction(
			identifier: "TAKE_BREAK",
			title: String(localized: "Take a Break"),
			options: []
		)
		let breakCategory = UNNotificationCategory(
			identifier: "BREAK_REMINDER",
			actions: [takeBreakAction],
			intentIdentifiers: [],
			options: []
		)
		let registerCategory = UNNotificationCategory(
			identifier: "REGISTER_REMINDER",
			actions: [],
			intentIdentifiers: [],
			options: []
		)
		UNUserNotificationCenter.current().setNotificationCategories([breakCategory, registerCategory])
	}

	func applicationWillTerminate(_ notification: Notification) {
		analytics.track(.appTerminated)
		reminderService?.stopMonitoring()
		reminderService = nil
		statusBarController?.tearDown()
		statusBarController = nil
	}
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		didReceive response: UNNotificationResponse,
		withCompletionHandler completionHandler: @escaping () -> Void
	) {
		if response.actionIdentifier == "TAKE_BREAK" {
			Task { @MainActor in
				await self.statusBarController?.viewModel.stopWork()
				self.analytics.track(.reminderTakeBreakTapped)
				completionHandler()
			}
		} else {
			completionHandler()
		}
	}

	func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		willPresent notification: UNNotification,
		withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
	) {
		completionHandler([.banner, .sound])
	}
}
