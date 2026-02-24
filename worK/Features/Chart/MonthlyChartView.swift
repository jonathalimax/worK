import Charts
import SwiftUI

// MARK: - MonthlyChartView

struct MonthlyChartView: View {
	@State private var viewModel = MonthlyChartViewModel()

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				header
				chartSection
				summaryCards
			}
			.padding()
		}
		.task {
			await viewModel.loadCurrentMonth()
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

			Text(viewModel.monthLabel)
				.font(.system(size: 18, weight: .bold))

			Spacer()

			HStack(spacing: 8) {
				Button {
					Task {
						await viewModel.navigateToPreviousMonth()
					}
				} label: {
					Image(systemName: "chevron.left")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(viewModel.canNavigatePrevious ? Color.primary : Color.secondary.opacity(0.3))
						.frame(width: 28, height: 28)
						.background {
							Circle()
								.fill(.ultraThinMaterial)
								.opacity(0.4)
						}
				}
				.buttonStyle(.plain)
				.disabled(!viewModel.canNavigatePrevious)

				Button {
					Task {
						await viewModel.navigateToNextMonth()
					}
				} label: {
					Image(systemName: "chevron.right")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(viewModel.canNavigateNext ? Color.primary : Color.secondary.opacity(0.3))
						.frame(width: 28, height: 28)
						.background {
							Circle()
								.fill(.ultraThinMaterial)
								.opacity(0.4)
						}
				}
				.buttonStyle(.plain)
				.disabled(!viewModel.canNavigateNext)
			}
		}
	}

	// MARK: - Chart

	private var chartSection: some View {
		Group {
			if viewModel.isLoading {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 200)
			} else if viewModel.chartData.isEmpty {
				emptyState
			} else {
				chart
			}
		}
	}

	private var chart: some View {
		Chart(viewModel.chartData) { day in
			BarMark(
				x: .value("Day", day.date, unit: .day),
				y: .value("Hours", day.hoursWorked)
			)
			.foregroundStyle(barColor(for: day))
			.cornerRadius(6)

			// Target line
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
						let measurement = Measurement(value: hours, unit: UnitDuration.hours)
						Text(measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided)))
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
									Color.white.opacity(0.05)
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

	private var emptyState: some View {
		VStack(spacing: 8) {
			Image(systemName: "chart.bar")
				.font(.largeTitle)
				.foregroundStyle(.secondary)
			Text(String(localized: "No work data this month"))
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, minHeight: 200)
	}

	// MARK: - Summary

	private var summaryCards: some View {
		HStack(spacing: 10) {
			StatsCardView(
				title: String(localized: "Total Hours"),
				value: formatHours(viewModel.totalHoursThisMonth),
				icon: "sum",
				color: .blue
			)
			StatsCardView(
				title: String(localized: "Daily Average"),
				value: formatHours(viewModel.averageHoursPerDay),
				icon: "chart.line.uptrend.xyaxis",
				color: .orange
			)
		}
	}

	// MARK: - Helpers

	private func formatHours(_ hours: Double) -> String {
		let totalSeconds: TimeInterval = hours * 3600
		return totalSeconds.formattedHoursMinutes
	}

	private func barColor(for day: DayChartData) -> Color {
		switch day.chartColor {
		case .green: .green
		case .yellow: .yellow
		case .red: .red
		}
	}
}

#Preview {
	MonthlyChartView()
		.frame(width: AppConstants.popoverWidth, height: 400)
}
