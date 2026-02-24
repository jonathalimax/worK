import Charts
import SwiftUI

// MARK: - PopoverContentView

struct PopoverContentView: View {
	let viewModel: WorkDayViewModel

	@State private var selectedTab: PopoverTab = .dashboard
	@State private var chartViewModel = MonthlyChartViewModel()
	@State private var historyViewModel = HistoryViewModel()
	@State private var expandedWorkDayID: UUID?

	var body: some View {
		VStack(spacing: 0) {
			tabBar
			tabContent
		}
		.frame(
			width: AppConstants.popoverWidth,
			height: AppConstants.popoverHeight
		)
		.background(.ultraThinMaterial)
	}

	// MARK: - Tab Bar

	private var tabBar: some View {
		HStack(spacing: 8) {
			ForEach(PopoverTab.allCases) { tab in
				Button {
					selectedTab = tab
				} label: {
					VStack(spacing: 5) {
						Image(systemName: tab.iconName)
							.font(.system(size: 15, weight: .semibold))
							.symbolRenderingMode(.hierarchical)

						Text(tab.title)
							.font(.system(size: 10, weight: .medium))
							.tracking(0.2)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 10)
					.background {
						if selectedTab == tab {
							RoundedRectangle(cornerRadius: 12, style: .continuous)
								.fill(.ultraThinMaterial)
								.opacity(0.4)
								.background(
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.fill(Color.accentColor.opacity(0.15))
								)
								.overlay {
									RoundedRectangle(cornerRadius: 12, style: .continuous)
										.strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1.5)
								}
								.shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
						}
					}
					.foregroundStyle(
						selectedTab == tab ? Color.accentColor : Color.secondary
					)
					.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
			}
		}
		.padding(8)
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
						.strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
				}
		}
		.padding(.horizontal, 12)
		.padding(.top, 12)
		.padding(.bottom, 8)
	}

	// MARK: - Tab Content

	@ViewBuilder
	private var tabContent: some View {
		ScrollView(showsIndicators: false) {
			switch selectedTab {
			case .dashboard:
				DashboardView(viewModel: viewModel)
			case .history:
				combinedHistoryChartView
			case .settings:
				SettingsView(viewModel: viewModel)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Combined History & Chart View

	private var combinedHistoryChartView: some View {
		VStack(spacing: 16) {
			chartSection
			historySection
		}
		.padding()
		.task {
			await chartViewModel.loadCurrentMonth()
			await historyViewModel.loadHistory()
		}
	}

	private var chartSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			chartHeader
			chartContent
			summaryCards
		}
	}

	private var chartHeader: some View {
		HStack(spacing: 8) {
			ZStack {
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.blue.opacity(0.15))
					.frame(width: 32, height: 32)
				Image(systemName: "chart.bar.fill")
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(.blue)
			}

			Text(chartViewModel.monthLabel)
				.font(.system(size: 18, weight: .bold))

			Spacer()

			HStack(spacing: 8) {
				Button {
					Task {
						await chartViewModel.navigateToPreviousMonth()
					}
				} label: {
					Image(systemName: "chevron.left")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(chartViewModel.canNavigatePrevious ? Color.primary : Color.secondary.opacity(0.3))
						.frame(width: 28, height: 28)
						.background {
							Circle()
								.fill(.ultraThinMaterial)
								.opacity(0.4)
						}
				}
				.buttonStyle(.plain)
				.disabled(!chartViewModel.canNavigatePrevious)

				Button {
					Task {
						await chartViewModel.navigateToNextMonth()
					}
				} label: {
					Image(systemName: "chevron.right")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(chartViewModel.canNavigateNext ? Color.primary : Color.secondary.opacity(0.3))
						.frame(width: 28, height: 28)
						.background {
							Circle()
								.fill(.ultraThinMaterial)
								.opacity(0.4)
						}
				}
				.buttonStyle(.plain)
				.disabled(!chartViewModel.canNavigateNext)
			}
		}
	}

	private var chartContent: some View {
		Group {
			if chartViewModel.isLoading {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 200)
			} else if chartViewModel.chartData.isEmpty {
				emptyChartState
			} else {
				chart
			}
		}
	}

	private var chart: some View {
		Chart(chartViewModel.chartData) { day in
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

	private var emptyChartState: some View {
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

	private var summaryCards: some View {
		HStack(spacing: 10) {
			StatsCardView(
				title: String(localized: "Total Hours"),
				value: formatHours(chartViewModel.totalHoursThisMonth),
				icon: "sum",
				color: .blue
			)
			StatsCardView(
				title: String(localized: "Daily Average"),
				value: formatHours(chartViewModel.averageHoursPerDay),
				icon: "chart.line.uptrend.xyaxis",
				color: .orange
			)
		}
	}

	private var historySection: some View {
		VStack(alignment: .leading, spacing: 12) {
			historyHeader
			historyList
		}
	}

	private var historyHeader: some View {
		HStack(spacing: 12) {
			HStack(spacing: 8) {
				ZStack {
					RoundedRectangle(cornerRadius: 8)
						.fill(Color.purple.opacity(0.15))
						.frame(width: 32, height: 32)
					Image(systemName: "calendar")
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(.purple)
				}

				Text(String(localized: "Work History"))
					.font(.system(size: 18, weight: .bold))
			}

			Spacer()

			Toggle(isOn: $historyViewModel.showUnregisteredOnly) {
				Text(String(localized: "Unregistered"))
					.font(.system(size: 11, weight: .medium))
			}
			.toggleStyle(.checkbox)
			.tint(.purple)
		}
	}

	private var historyList: some View {
		Group {
			if historyViewModel.isLoading {
				ProgressView()
					.controlSize(.large)
					.frame(maxWidth: .infinity, minHeight: 200)
			} else if historyViewModel.filteredWorkDays.isEmpty {
				emptyHistoryState
			} else {
				VStack(spacing: 8) {
					ForEach(historyViewModel.filteredWorkDays) { workDay in
						VStack(spacing: 0) {
							HistoryRowView(
								workDay: workDay,
								summary: historyViewModel.summary(for: workDay),
								isExpanded: expandedWorkDayID == workDay.id,
								onToggleRegistered: {
									Task { await historyViewModel.toggleRegistered(for: workDay.id) }
								},
								onTap: {
									withAnimation(.smooth(duration: 0.3)) {
										expandedWorkDayID = expandedWorkDayID == workDay.id ? nil : workDay.id
									}
								}
							)

							if expandedWorkDayID == workDay.id {
								WorkDayDetailInlineView(
									workDay: workDay,
									summary: historyViewModel.summary(for: workDay)
								)
								.transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
							}
						}
					}
				}
			}
		}
	}

	private var emptyHistoryState: some View {
		VStack(spacing: 8) {
			Image(systemName: "calendar")
				.font(.largeTitle)
				.foregroundStyle(.secondary)
			Text(String(localized: "No work days recorded yet"))
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, minHeight: 150)
	}

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
