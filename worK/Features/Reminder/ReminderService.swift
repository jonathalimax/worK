import Dependencies
import Foundation
import Observation

// MARK: - ReminderService

@Observable
@MainActor
final class ReminderService {
	// MARK: - Dependencies

	@ObservationIgnored @Dependency(\.settingsClient) private var settingsClient
	@ObservationIgnored @Dependency(\.continuousClock) private var clock
	@ObservationIgnored @Dependency(\.analyticsClient) private var analytics

	// MARK: - Properties

	private let panelController = ReminderPanelController()
	private var monitoringTask: Task<Void, Never>?
	private weak var viewModel: WorkDayViewModel?

	var shouldShowReminder = false

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
		panelController.dismiss()
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
		panelController.show(workedTime: workedTime) { [weak self] in
			Task { @MainActor [weak self] in
				guard let self, let viewModel = self.viewModel else { return }
				// Simulate taking a break by stopping work
				await viewModel.stopWork()
			}
		}
	}
}
