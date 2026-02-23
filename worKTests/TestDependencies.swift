import Dependencies
import Foundation

/// Configures default test dependencies for all snapshot tests.
/// Call `TestDependencies.configure()` before running any snapshot test
/// to prevent crashes from SwiftUI `.task` modifiers that fire
/// asynchronously after the `withDependencies` scope has exited.
@MainActor
enum TestDependencies {
	private static var isConfigured = false

	static func configure() {
		guard !isConfigured else { return }
		isConfigured = true

		prepareDependencies {
			$0.settingsClient = SettingsClient(
				targetHours: { 8.0 },
				setTargetHours: { _ in },
				launchAtLogin: { false },
				setLaunchAtLogin: { _ in },
				reminderEnabled: { true },
				setReminderEnabled: { _ in },
				reminderIntervalMinutes: { 60 },
				setReminderIntervalMinutes: { _ in },
				stopRecordingEnabled: { false },
				setStopRecordingEnabled: { _ in },
				stopRecordingTime: { 20 },
				setStopRecordingTime: { _ in },
				registerExternally: { false },
				setRegisterExternally: { _ in }
			)
			$0.aiMessageClient = AIMessageClient(
				generateMessage: { @Sendable _ in
					"Stay focused, but remember to breathe. Great work happens in sustainable rhythms."
				}
			)
		}
	}
}
