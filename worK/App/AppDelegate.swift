import AppKit
import Dependencies
import SwiftUI
import TelemetryDeck

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusBarController: StatusBarController?
	private var reminderService: ReminderService?

	@MainActor
	func applicationDidFinishLaunching(_ notification: Notification) {
		// Hide dock icon -- this is a menubar-only app
		NSApp.setActivationPolicy(.accessory)

		// Initialize Sparkle auto-updater
		_ = SparkleCoordinator.shared

		// Initialize the status bar
		let controller = StatusBarController()
		statusBarController = controller

		@Dependency(\.analyticsClient) var analytics
		analytics.track(.appLaunched)

		// Initialize break reminder service
		let service = ReminderService()
		service.startMonitoring(viewModel: controller.viewModel)
		reminderService = service

		// Reset reminder timer whenever work resumes after a break
		controller.viewModel.onWorkResumed = { [weak service] in
			service?.resetTimer()
		}
	}

	@MainActor
	func applicationWillTerminate(_ notification: Notification) {
		@Dependency(\.analyticsClient) var analytics
		analytics.track(.appTerminated)
		reminderService?.stopMonitoring()
		reminderService = nil
		statusBarController?.tearDown()
		statusBarController = nil
	}
}
