import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
	@State private var viewModel = HistoryViewModel()
	@State private var selectedWorkDay: WorkDay?

	var body: some View {
		VStack(spacing: 0) {
			filterBar
			historyList
		}
		.task {
			await viewModel.loadHistory()
		}
		.sheet(item: $selectedWorkDay) { workDay in
			WorkDayDetailView(
				workDay: workDay,
				summary: viewModel.summary(for: workDay)
			)
		}
	}

	// MARK: - Filter Bar

	private var filterBar: some View {
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

			Toggle(isOn: $viewModel.showUnregisteredOnly) {
				Text(String(localized: "Unregistered"))
					.font(.system(size: 11, weight: .medium))
			}
			.toggleStyle(.checkbox)
			.tint(.purple)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
	}

	// MARK: - History List

	private var historyList: some View {
		Group {
			if viewModel.isLoading {
				ProgressView()
					.controlSize(.large)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			} else if viewModel.filteredWorkDays.isEmpty {
				emptyState
			} else {
				ScrollView {
					VStack(spacing: 8) {
						ForEach(viewModel.filteredWorkDays) { workDay in
							HistoryRowView(
								workDay: workDay,
								summary: viewModel.summary(for: workDay),
								onToggleRegistered: {
									Task { await viewModel.toggleRegistered(for: workDay.id) }
								},
								onTap: {
									selectedWorkDay = workDay
								}
							)
						}
					}
					.padding(.horizontal, 16)
					.padding(.bottom, 16)
				}
			}
		}
	}

	private var emptyState: some View {
		VStack(spacing: 8) {
			Image(systemName: "calendar")
				.font(.largeTitle)
				.foregroundStyle(.secondary)
			Text(String(localized: "No work days recorded yet"))
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// MARK: - HistoryRowView

struct HistoryRowView: View {
	let workDay: WorkDay
	let summary: DailySummary?
	let onToggleRegistered: () -> Void
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			HStack(spacing: 12) {
				dateColumn
				Spacer()
				hoursColumn
				registeredToggle
			}
			.padding(14)
			.background {
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(.ultraThinMaterial)
					.opacity(0.4)
					.background(
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(Color(white: 0.08).opacity(0.2))
					)
					.overlay {
						RoundedRectangle(cornerRadius: 12, style: .continuous)
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
			.shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
			.shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}

	private var dateColumn: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(workDay.date.formatted(.dateTime.weekday(.wide)))
				.font(.system(size: 10, weight: .medium))
				.foregroundStyle(.secondary)
				.textCase(.uppercase)
				.tracking(0.3)

			Text(workDay.date.formatted(.dateTime.day().month(.abbreviated)))
				.font(.system(size: 15, weight: .semibold))
		}
	}

	private var hoursColumn: some View {
		VStack(alignment: .trailing, spacing: 4) {
			let worked = summary?.workedSeconds() ?? 0
			Text(worked.formattedHoursMinutes)
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.monospacedDigit()

			let breakCount = summary?.breakCount ?? 0
			if breakCount > 0 {
				HStack(spacing: 4) {
					Image(systemName: "cup.and.saucer.fill")
						.font(.system(size: 9, weight: .semibold))
					Text("\(breakCount) break\(breakCount == 1 ? "" : "s")")
						.font(.system(size: 10, weight: .medium))
				}
				.foregroundStyle(.secondary)
			}
		}
	}

	private var registeredToggle: some View {
		Button(action: onToggleRegistered) {
			ZStack {
				Circle()
					.fill(workDay.isRegistered ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
					.frame(width: 32, height: 32)

				Image(systemName: workDay.isRegistered ? "checkmark.circle.fill" : "circle")
					.foregroundStyle(workDay.isRegistered ? .green : .secondary)
					.font(.system(size: 18, weight: .semibold))
			}
		}
		.buttonStyle(.plain)
		.help(workDay.isRegistered
			? String(localized: "Marked as registered")
			: String(localized: "Mark as registered"))
	}
}

#Preview {
	HistoryView()
		.frame(width: AppConstants.popoverWidth, height: 400)
}
