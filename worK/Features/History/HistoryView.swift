import SwiftUI

// MARK: - HistoryView

struct HistoryView: View {
	@State private var viewModel = HistoryViewModel()
	@State private var expandedWorkDayID: UUID?

	var body: some View {
		VStack(spacing: 0) {
			filterBar
			historyList
		}
		.task {
			await viewModel.loadHistory()
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
				ScrollViewReader { proxy in
					ScrollView {
						VStack(spacing: 8) {
							ForEach(viewModel.filteredWorkDays) { workDay in
								VStack(spacing: 0) {
									HistoryRowView(
										workDay: workDay,
										summary: viewModel.summary(for: workDay),
										isExpanded: expandedWorkDayID == workDay.id,
										onToggleRegistered: {
											Task { await viewModel.toggleRegistered(for: workDay.id) }
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
											summary: viewModel.summary(for: workDay)
										)
										.transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
									}
								}
								.id(workDay.id)
							}
						}
						.padding(.horizontal, 16)
						.padding(.bottom, 16)
					}
					.onChange(of: expandedWorkDayID) { _, newID in
						if let id = newID {
							withAnimation(.smooth(duration: 0.3)) {
								proxy.scrollTo(id, anchor: .top)
							}
						}
					}
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
	let isExpanded: Bool
	let onToggleRegistered: () -> Void
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			HStack(spacing: 12) {
				dateColumn
				Spacer()
				hoursColumn
				registeredToggle

				// Chevron indicator
				Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
					.font(.system(size: 12, weight: .semibold))
					.foregroundStyle(.secondary)
					.frame(width: 20)
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
										Color.white.opacity(isExpanded ? 0.25 : 0.15),
										Color.white.opacity(isExpanded ? 0.15 : 0.05)
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
					Text(String(localized: "^\(breakCount) break(s)"))
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

// MARK: - WorkDayDetailInlineView

struct WorkDayDetailInlineView: View {
	let workDay: WorkDay
	let summary: DailySummary?

	@State private var isSessionsExpanded: Bool = false

	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			// Stats grid
			LazyVGrid(
				columns: [
					GridItem(.flexible(), spacing: 8),
					GridItem(.flexible(), spacing: 8)
				],
				spacing: 8
			) {
				DetailStatCard(
					title: String(localized: "Worked"),
					value: (summary?.workedSeconds() ?? 0.0).formattedHoursMinutes,
					icon: "clock.fill",
					color: .blue
				)
				DetailStatCard(
					title: String(localized: "Target"),
					value: (workDay.targetHours * 3600).formattedHoursMinutes,
					icon: "target",
					color: .orange
				)
				DetailStatCard(
					title: String(localized: "Breaks"),
					value: "\(summary?.breakCount ?? 0)",
					icon: "cup.and.saucer.fill",
					color: .purple
				)
				DetailStatCard(
					title: String(localized: "Break Time"),
					value: (summary?.breakSeconds() ?? 0.0).formattedHoursMinutes,
					icon: "pause.circle.fill",
					color: .teal
				)
			}

			// Sessions section
			if let sessions = summary?.sessions, !sessions.isEmpty {
				VStack(alignment: .leading, spacing: 8) {
					HStack(spacing: 6) {
						Image(systemName: "list.bullet")
							.font(.system(size: 10, weight: .semibold))
							.foregroundStyle(.blue)

						Text(String(localized: "Sessions"))
							.font(.system(size: 10, weight: .semibold))
							.foregroundStyle(.secondary)
							.textCase(.uppercase)
							.tracking(0.5)
					}

					VStack(spacing: 6) {
						let displayedSessions = isSessionsExpanded ? sessions : Array(sessions.prefix(3))

						ForEach(displayedSessions) { session in
							HStack(spacing: 8) {
								Image(systemName: "play.circle.fill")
									.foregroundStyle(.green)
									.font(.system(size: 10, weight: .semibold))

								Text(session.startedAt.formatted(.dateTime.hour().minute()))
									.font(.system(size: 11, weight: .medium))
									.monospacedDigit()

								Image(systemName: "arrow.right")
									.font(.system(size: 9, weight: .semibold))
									.foregroundStyle(.secondary)

								if let endedAt = session.endedAt {
									Text(endedAt.formatted(.dateTime.hour().minute()))
										.font(.system(size: 11, weight: .medium))
										.monospacedDigit()
								} else {
									Text(String(localized: "Active"))
										.font(.system(size: 10, weight: .medium))
										.foregroundStyle(.green)
								}

								Spacer()

								let duration = (session.endedAt ?? .now).timeIntervalSince(session.startedAt)
								Text(duration.formattedHoursMinutes)
									.font(.system(size: 11, weight: .semibold))
									.monospacedDigit()
									.foregroundStyle(.secondary)
							}
							.padding(.horizontal, 10)
							.padding(.vertical, 8)
							.background {
								RoundedRectangle(cornerRadius: 8, style: .continuous)
									.fill(Color.white.opacity(0.03))
									.overlay {
										RoundedRectangle(cornerRadius: 8, style: .continuous)
											.strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
									}
							}
						}

						if sessions.count > 3 {
							Button {
								withAnimation(.smooth) {
									isSessionsExpanded.toggle()
								}
							} label: {
								HStack(spacing: 4) {
									Text(isSessionsExpanded
										? String(localized: "Show less")
										: String(localized: "Show \(sessions.count - 3) more...")
									)
									.font(.system(size: 10, weight: .medium))

									Image(systemName: isSessionsExpanded ? "chevron.up" : "chevron.down")
										.font(.system(size: 8, weight: .semibold))
								}
								.foregroundStyle(.blue)
								.frame(maxWidth: .infinity)
								.padding(.vertical, 8)
								.padding(.horizontal, 12)
								.contentShape(Rectangle())
							}
							.buttonStyle(.plain)
							.padding(.top, 2)
						}
					}
					.animation(.smooth, value: isSessionsExpanded)
				}
			}
		}
		.padding(14)
		.background {
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(Color(white: 0.05))
				.overlay {
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
				}
		}
		.padding(.top, 8)
	}
}

// MARK: - DetailStatCard

struct DetailStatCard: View {
	let title: String
	let value: String
	let icon: String
	let color: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(spacing: 6) {
				ZStack {
					RoundedRectangle(cornerRadius: 6)
						.fill(color.opacity(0.15))
						.frame(width: 22, height: 22)
					Image(systemName: icon)
						.font(.system(size: 10, weight: .semibold))
						.foregroundStyle(color)
				}

				Text(title)
					.font(.system(size: 10, weight: .medium))
					.foregroundStyle(.secondary)
			}

			Text(value)
				.font(.system(size: 14, weight: .bold, design: .rounded))
				.monospacedDigit()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(10)
		.background {
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.fill(.ultraThinMaterial)
				.opacity(0.3)
				.background(
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(Color.white.opacity(0.02))
				)
				.overlay {
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
				}
		}
	}
}

// MARK: - Preview

#Preview {
	HistoryView()
		.frame(width: AppConstants.popoverWidth, height: 400)
}
