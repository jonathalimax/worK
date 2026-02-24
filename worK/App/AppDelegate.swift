import AppKit
import Dependencies
import SwiftUI

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

		// Initialize break reminder service
		let service = ReminderService()
		service.startMonitoring(viewModel: controller.viewModel)
		reminderService = service
	}

	@MainActor
	func applicationWillTerminate(_ notification: Notification) {
		reminderService?.stopMonitoring()
		reminderService = nil
		statusBarController?.tearDown()
		statusBarController = nil
	}
}
