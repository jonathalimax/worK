import Dependencies
import Foundation
import Observation
import SQLiteData

// MARK: - HistoryViewModel

@Observable
@MainActor
final class HistoryViewModel {
	// MARK: - Dependencies

	@ObservationIgnored @Dependency(\.defaultDatabase) private var database
	@ObservationIgnored @Dependency(\.calendar) private var calendar

	// MARK: - State

	var workDays: [WorkDay] = []
	var showUnregisteredOnly = false
	var isLoading = false

	var filteredWorkDays: [WorkDay] {
		if showUnregisteredOnly {
			return workDays.filter { !$0.isRegistered }
		}
		return workDays
	}

	// MARK: - Actions

	func loadHistory() async {
		isLoading = true
		defer { isLoading = false }

		do {
			workDays = try database.fetchAllWorkDays()
		} catch {
			print("Failed to load history: \(error)")
			workDays = []
		}
	}

	func toggleRegistered(for workDayId: UUID) async {
		do {
			try database.toggleRegistered(for: workDayId)
			await loadHistory()
		} catch {
			print("Failed to toggle registered: \(error)")
		}
	}

	func summary(for workDay: WorkDay) -> DailySummary? {
		try? database.dailySummary(for: workDay.date, calendar: calendar)
	}
}
