import Charts
import Dependencies
import SnapshotTesting
import SwiftUI
import Testing

// MARK: - ChartSnapshotTests

@MainActor
struct ChartSnapshotTests {
	// MARK: - Constants

	private static let snapshotSize = CGSize(
		width: AppConstants.popoverWidth,
		height: AppConstants.popoverHeight
	)

	private static let precision: Float = 0.99

	init() {
		TestDependencies.configure()
	}

	// MARK: - Helpers

	/// Generates realistic chart data for a full month with varied work patterns.
	private static func generateMonthChartData() -> [DayChartData] {
		let calendar = Calendar.current
		let now = Date()
		let startOfMonth = now.startOfMonth(calendar: calendar)

		var data: [DayChartData] = []

		let hoursPattern: [Double] = [
			7.5, 8.2, 6.3, 8.0, 9.1, // Week 1: mixed
			8.5, 7.8, 4.2, 8.0, 8.3, // Week 2: one short day
			9.0, 8.1, 7.0, 8.6, 7.2, // Week 3: consistent
			8.4, 6.8, 8.0, 7.5, 8.9, // Week 4: varied
			8.0, 7.6, // Extra days
		]

		var dayIndex = 0
		var patternIndex = 0

		while dayIndex < 31, patternIndex < hoursPattern.count {
			guard let date = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonth) else {
				dayIndex += 1
				continue
			}

			let weekday = calendar.component(.weekday, from: date)
			if weekday == 1 || weekday == 7 {
				dayIndex += 1
				continue
			}

			data.append(DayChartData(
				id: UUID(),
				date: date,
				hoursWorked: hoursPattern[patternIndex],
				targetHours: 8.0
			))

			dayIndex += 1
			patternIndex += 1
		}

		return data
	}

	// MARK: - Full Month Chart

	@Test
	func monthlyChartFullMonth() {
		let chartData = Self.generateMonthChartData()
		let totalHours = chartData.reduce(0.0) { $0 + $1.hoursWorked }
		let averageHours = chartData.isEmpty ? 0 : totalHours / Double(chartData.count)

		let view = ChartSnapshotView(
			chartData: chartData,
			monthLabel: Date().formatted(.dateTime.month(.wide).year()),
			totalHours: totalHours,
			averageHours: averageHours
		)
		.frame(
			width: Self.snapshotSize.width,
			height: Self.snapshotSize.height
		)
		.background(.ultraThinMaterial)
		.background(Color(white: 0.08))
		.environment(\.colorScheme, .dark)

		assertSnapshot(
			of: NSHostingController(rootView: view),
			as: .image(
				precision: Self.precision,
				size: Self.snapshotSize
			),
			named: "chart_full_month"
		)
	}
}

// MARK: - ChartSnapshotView

/// A self-contained chart view for snapshot testing that does not depend on async loading.
private struct ChartSnapshotView: View {
	let chartData: [DayChartData]
	let monthLabel: String
	let totalHours: Double
	let averageHours: Double

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				header
				chart
				summaryCards
			}
			.padding()
		}
	}

	// MARK: - Header

	private var header: some View {
		HStack(spacing: 8) {
			ZStack {
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.blue.opacity(0.15))
					.frame(width: 32, height: 32)
				Image(systemName: "chart.bar.fill")
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(.blue)
			}

			Text(monthLabel)
				.font(.system(size: 18, weight: .bold))

			Spacer()

			HStack(spacing: 8) {
				navigationButton(icon: "chevron.left", enabled: true)
				navigationButton(icon: "chevron.right", enabled: false)
			}
		}
	}

	private func navigationButton(icon: String, enabled: Bool) -> some View {
		Image(systemName: icon)
			.font(.system(size: 12, weight: .semibold))
			.foregroundStyle(enabled ? Color.primary : Color.secondary.opacity(0.3))
			.frame(width: 28, height: 28)
			.background {
				Circle()
					.fill(.ultraThinMaterial)
					.opacity(0.4)
			}
	}

	// MARK: - Chart

	private var chart: some View {
		Chart(chartData) { day in
			BarMark(
				x: .value("Day", day.date, unit: .day),
				y: .value("Hours", day.hoursWorked)
			)
			.foregroundStyle(barColor(for: day))
			.cornerRadius(6)

			RuleMark(y: .value("Target", day.targetHours))
				.lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
				.foregroundStyle(.secondary.opacity(0.4))
		}
		.chartXAxis {
			AxisMarks(values: .stride(by: .day, count: 7)) { _ in
				AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
					.foregroundStyle(Color.white.opacity(0.1))
				AxisValueLabel(format: .dateTime.day().month(.abbreviated))
					.font(.system(size: 10, weight: .medium))
					.foregroundStyle(.secondary)
			}
		}
		.chartYAxis {
			AxisMarks { value in
				AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
					.foregroundStyle(Color.white.opacity(0.1))
				AxisValueLabel {
					if let hours = value.as(Double.self) {
						Text("\(Int(hours))h")
							.font(.system(size: 10, weight: .medium))
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.frame(height: 220)
		.padding()
		.background {
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(.ultraThinMaterial)
				.opacity(0.4)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(Color(white: 0.08).opacity(0.2))
				)
				.overlay {
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.strokeBorder(
							LinearGradient(
								colors: [
									Color.white.opacity(0.15),
									Color.white.opacity(0.05),
								],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							),
							lineWidth: 1.5
						)
				}
		}
		.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
		.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
	}

	// MARK: - Summary

	private var summaryCards: some View {
		HStack(spacing: 10) {
			StatsCardView(
				title: String(localized: "Total Hours"),
				value: String(format: "%.1fh", totalHours),
				icon: "sum",
				color: .blue
			)
			StatsCardView(
				title: String(localized: "Daily Average"),
				value: String(format: "%.1fh", averageHours),
				icon: "chart.line.uptrend.xyaxis",
				color: .orange
			)
		}
	}

	// MARK: - Helpers

	private func barColor(for day: DayChartData) -> Color {
		switch day.chartColor {
		case .green: .green
		case .yellow: .yellow
		case .red: .red
		}
	}
}
