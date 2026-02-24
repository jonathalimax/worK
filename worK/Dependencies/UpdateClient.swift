import Dependencies
import DependenciesMacros
import Foundation

// MARK: - UpdateClient

@DependencyClient
struct UpdateClient: Sendable {
	var checkForUpdates: @Sendable @MainActor () -> Void
}

// MARK: - Live Implementation

extension UpdateClient: DependencyKey {
	static let liveValue: UpdateClient = {
		@MainActor
		func checkForUpdates() {
			SparkleCoordinator.shared.checkForUpdates()
		}

		return UpdateClient(
			checkForUpdates: checkForUpdates
		)
	}()

	static let testValue = UpdateClient()
	static let previewValue = UpdateClient()
}

extension DependencyValues {
	var updateClient: UpdateClient {
		get { self[UpdateClient.self] }
		set { self[UpdateClient.self] = newValue }
	}
}
