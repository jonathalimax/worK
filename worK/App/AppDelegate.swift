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
