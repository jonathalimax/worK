import Dependencies
import DependenciesMacros
import Foundation

// MARK: - ScreenEvent

enum ScreenEvent: Sendable {
	case locked
	case unlocked
}

// MARK: - NotificationClient

@DependencyClient
struct NotificationClient: Sendable {
	/// Returns an AsyncStream of screen lock/unlock events.
	var screenEvents: @Sendable () -> AsyncStream<ScreenEvent> = { .finished }
}

// MARK: - Live Implementation

extension NotificationClient: DependencyKey {
	static let liveValue = NotificationClient(
		screenEvents: {
			AsyncStream { continuation in
				let center = DistributedNotificationCenter.default()

				let lockObserver = center.addObserver(
					forName: .init("com.apple.screenIsLocked"),
					object: nil,
					queue: .main
				) { _ in
					print("📢 NotificationClient: Received com.apple.screenIsLocked")
					continuation.yield(.locked)
				}

				let unlockObserver = center.addObserver(
					forName: .init("com.apple.screenIsUnlocked"),
					object: nil,
					queue: .main
				) { _ in
					print("📢 NotificationClient: Received com.apple.screenIsUnlocked")
					continuation.yield(.unlocked)
				}

				// Fallback: Also listen for session becoming active (covers cases where screenIsUnlocked doesn't fire)
				let sessionActiveObserver = center.addObserver(
					forName: .init("com.apple.sessionDidBecomeActive"),
					object: nil,
					queue: .main
				) { _ in
					print("📢 NotificationClient: Received com.apple.sessionDidBecomeActive (fallback unlock)")
					continuation.yield(.unlocked)
				}

				// Store references for cleanup
				nonisolated(unsafe) let lock = lockObserver
				nonisolated(unsafe) let unlock = unlockObserver
				nonisolated(unsafe) let sessionActive = sessionActiveObserver

				continuation.onTermination = { @Sendable _ in
					let center = DistributedNotificationCenter.default()
					center.removeObserver(lock)
					center.removeObserver(unlock)
					center.removeObserver(sessionActive)
				}
			}
		}
	)

	static let testValue = NotificationClient()
	static let previewValue = NotificationClient(
		screenEvents: { .finished }
	)
}

extension DependencyValues {
	var notificationClient: NotificationClient {
		get { self[NotificationClient.self] }
		set { self[NotificationClient.self] = newValue }
	}
}
