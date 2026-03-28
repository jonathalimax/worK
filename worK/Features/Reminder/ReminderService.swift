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

		guard let (title, body) = BreakReminderMessages.random(workedTime: workedTime) else { return }

		let content = UNMutableNotificationContent()
		content.title = title
		content.body = body
		content.sound = .default
		content.categoryIdentifier = "BREAK_REMINDER"

		// Fixed identifier: intentionally overwrites any previous pending reminder
		// so at most one reminder is ever outstanding at a time.
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

	static func random(workedTime: String) -> (String, String)? {
		guard let (title, body) = messages.randomElement() else { return nil }
		return (title, body.replacingOccurrences(of: "{time}", with: workedTime))
	}
}
