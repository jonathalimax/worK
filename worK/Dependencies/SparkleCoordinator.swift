import Foundation
import Sparkle

// MARK: - SparkleCoordinator

/// Coordinates Sparkle auto-update functionality.
/// This is a MainActor-isolated singleton that owns the SPUStandardUpdaterController.
@MainActor
final class SparkleCoordinator: ObservableObject {
	static let shared = SparkleCoordinator()

	private let updaterController: SPUStandardUpdaterController

	private init() {
		// Initialize Sparkle with the default user driver and delegate
		updaterController = SPUStandardUpdaterController(
			startingUpdater: true,
			updaterDelegate: nil,
			userDriverDelegate: nil
		)
	}

	/// Manually check for updates (triggered by "Check for Updates" button)
	func checkForUpdates() {
		updaterController.checkForUpdates(nil)
	}

	/// Access to the underlying updater (useful for testing or advanced configuration)
	var updater: SPUUpdater {
		updaterController.updater
	}
}
