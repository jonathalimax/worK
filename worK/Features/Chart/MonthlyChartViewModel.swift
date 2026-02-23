import Dependencies
import Foundation
import Observation
import SQLiteData

// MARK: - DayChartData

struct DayChartData: Identifiable, Sendable {
	let id: UUID
	let date: Date
	let hoursWorked: Double
	let targetHours: Double

	var chartColor: ChartBarColor {
		guard targetHours > 0 else { return .green }
		let ratio = hoursWorked / targetHours
		switch ratio {
		case 0..<0.5: return .red
		case 0.5..<0.9: return .yellow
		default: return .green
		}
	}

	var dayLabel: String {
		date.formatted(.dateTime.weekday(.abbreviated))
	}

	var dayNumber: String {
		date.formatted(.dateTime.day())
	}
}

enum ChartBarColor: Sendable {
	case green
	case yellow
	case red
}

// MARK: - MonthlyChartViewModel

@Observable
@MainActor
final class MonthlyChartViewModel {
	// MARK: - Dependencies

	@ObservationIgnored @Dependency(\.defaultDatabase) private var database
	@ObservationIgnored @Dependency(\.date.now) private var now
	@ObservationIgnored @Dependency(\.calendar) private var calendar

	// MARK: - State

	var chartData: [DayChartData] = []
	var monthLabel: String = ""
	var totalHoursThisMonth: Double = 0
	var averageHoursPerDay: Double = 0
	var isLoading = false
	var currentMonthOffset: Int = 0
	var canNavigatePrevious = false
	var canNavigateNext = false
	private var monthsWithData: [Date] = []

	// MARK: - Actions

	func loadCurrentMonth() async {
		currentMonthOffset = 0
		await loadMonthsWithData()
		await loadMonth()
	}

	func navigateToPreviousMonth() async {
		currentMonthOffset -= 1
		await loadMonth()
	}

	func navigateToNextMonth() async {
		currentMonthOffset += 1
		await loadMonth()
	}

	// MARK: - Private Helpers

	private func loadMonthsWithData() async {
		do {
			monthsWithData = try database.fetchMonthsWithData(calendar: calendar)
		} catch {
			print("Failed to load months with data: \(error)")
			monthsWithData = []
		}
	}

	private func loadMonth() async {
		isLoading = true
		defer { isLoading = false }

		guard let targetMonth = calendar.date(byAdding: .month, value: currentMonthOffset, to: now) else {
			return
		}

		let startOfMonth = targetMonth.startOfMonth(calendar: calendar)
		let endOfMonth = targetMonth.endOfMonth(calendar: calendar)

		monthLabel = targetMonth.formatted(.dateTime.month(.wide).year())

		do {
			let workDays = try database.fetchWorkDays(from: startOfMonth, to: endOfMonth)
			var data: [DayChartData] = []
			var totalHours: Double = 0

			for workDay in workDays {
				let summary = try database.dailySummary(for: workDay.date, calendar: calendar)
				let hoursWorked = (summary?.workedSeconds() ?? 0).inHours

				data.append(DayChartData(
					id: workDay.id,
					date: workDay.date,
					hoursWorked: hoursWorked,
					targetHours: workDay.targetHours
				))

				totalHours += hoursWorked
			}

			chartData = data.sorted { $0.date < $1.date }
			totalHoursThisMonth = totalHours
			averageHoursPerDay = data.isEmpty ? 0 : totalHours / Double(data.count)

			updateNavigationState(for: startOfMonth)
		} catch {
			print("Failed to load chart data: \(error)")
			chartData = []
		}
	}

	private func updateNavigationState(for currentMonth: Date) {
		guard !monthsWithData.isEmpty else {
			canNavigatePrevious = false
			canNavigateNext = false
			return
		}

		let earliestMonth = monthsWithData.first!
		let latestMonth = monthsWithData.last!

		let monthsFromEarliest = calendar.dateComponents([.month], from: earliestMonth, to: currentMonth).month ?? 0
		let monthsFromLatest = calendar.dateComponents([.month], from: currentMonth, to: latestMonth).month ?? 0

		canNavigatePrevious = currentMonthOffset > -12 && monthsFromEarliest > 0
		canNavigateNext = currentMonthOffset < 12 && monthsFromLatest > 0
	}
}
