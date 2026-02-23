import SwiftUI

// MARK: - WorkDayDetailView

struct WorkDayDetailView: View {
	let workDay: WorkDay
	let summary: DailySummary?

	@Environment(\.dismiss) private var dismiss

	var body: some View {
		VStack(alignment: .leading, spacing: 18) {
			header
			statsSection
			sessionsSection
			Spacer()
			closeButton
		}
		.padding(20)
		.frame(width: 360, height: 480)
		.background(Color(white: 0.08))
	}

	// MARK: - Header

	private var header: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 8) {
				ZStack {
					RoundedRectangle(cornerRadius: 8)
						.fill(Color.purple.opacity(0.15))
						.frame(width: 32, height: 32)
					Image(systemName: "calendar")
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(.purple)
				}

				Text(workDay.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
					.font(.system(size: 18, weight: .bold))
			}

			HStack(spacing: 6) {
				ZStack {
					Circle()
						.fill(workDay.isRegistered ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
						.frame(width: 22, height: 22)

					Image(systemName: workDay.isRegistered ? "checkmark.circle.fill" : "circle")
						.foregroundStyle(workDay.isRegistered ? .green : .secondary)
						.font(.system(size: 12, weight: .semibold))
				}

				Text(workDay.isRegistered
					? String(localized: "Registered")
					: String(localized: "Not registered"))
					.font(.system(size: 12, weight: .medium))
					.foregroundStyle(.secondary)
			}
		}
	}

	// MARK: - Stats

	private var statsSection: some View {
		LazyVGrid(
			columns: [
				GridItem(.flexible(), spacing: 10),
				GridItem(.flexible(), spacing: 10)
			],
			spacing: 10
		) {
			StatsCardView(
				title: String(localized: "Worked"),
				value: (summary?.workedSeconds() ?? 0).formattedHoursMinutes,
				icon: "clock.fill",
				color: .blue
			)
			StatsCardView(
				title: String(localized: "Target"),
				value: (workDay.targetHours * 3600).formattedHoursMinutes,
				icon: "target",
				color: .orange
			)
			StatsCardView(
				title: String(localized: "Breaks"),
				value: "\(summary?.breakCount ?? 0)",
				icon: "cup.and.saucer.fill",
				color: .purple
			)
			StatsCardView(
				title: String(localized: "Break Time"),
				value: (summary?.breakSeconds() ?? 0).formattedHoursMinutes,
				icon: "pause.circle.fill",
				color: .teal
			)
		}
	}

	// MARK: - Sessions

	private var sessionsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			HStack(spacing: 6) {
				ZStack {
					RoundedRectangle(cornerRadius: 6)
						.fill(Color.blue.opacity(0.15))
						.frame(width: 24, height: 24)
					Image(systemName: "list.bullet")
						.font(.system(size: 11, weight: .semibold))
						.foregroundStyle(.blue)
				}

				Text(String(localized: "Sessions"))
					.font(.system(size: 12, weight: .semibold))
					.foregroundStyle(.primary)
					.textCase(.uppercase)
					.tracking(0.5)
			}

			VStack(spacing: 8) {
				if let sessions = summary?.sessions, !sessions.isEmpty {
					ForEach(sessions) { session in
						HStack(spacing: 10) {
							Image(systemName: "play.circle.fill")
								.foregroundStyle(.green)
								.font(.system(size: 12, weight: .semibold))

							Text(session.startedAt.formatted(.dateTime.hour().minute()))
								.font(.system(size: 12, weight: .medium))
								.monospacedDigit()

							Image(systemName: "arrow.right")
								.font(.system(size: 10, weight: .semibold))
								.foregroundStyle(.secondary)

							if let endedAt = session.endedAt {
								Text(endedAt.formatted(.dateTime.hour().minute()))
									.font(.system(size: 12, weight: .medium))
									.monospacedDigit()
							} else {
								Text(String(localized: "Active"))
									.font(.system(size: 11, weight: .medium))
									.foregroundStyle(.green)
							}

							Spacer()

							let duration = (session.endedAt ?? .now).timeIntervalSince(session.startedAt)
							Text(duration.formattedHoursMinutes)
								.font(.system(size: 12, weight: .semibold))
								.monospacedDigit()
								.foregroundStyle(.secondary)
						}
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
				} else {
					HStack {
						Image(systemName: "tray")
							.font(.system(size: 12, weight: .semibold))
							.foregroundStyle(.secondary)
						Text(String(localized: "No sessions"))
							.font(.system(size: 12, weight: .medium))
							.foregroundStyle(.secondary)
					}
					.frame(maxWidth: .infinity)
					.padding(10)
					.background {
						RoundedRectangle(cornerRadius: 10, style: .continuous)
							.fill(Color.white.opacity(0.03))
							.overlay {
								RoundedRectangle(cornerRadius: 10, style: .continuous)
									.strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
							}
					}
				}
			}
		}
	}

	// MARK: - Close

	private var closeButton: some View {
		Button {
			dismiss()
		} label: {
			Text(String(localized: "Close"))
				.font(.system(size: 14, weight: .semibold))
				.frame(maxWidth: .infinity)
				.padding(.vertical, 12)
				.background {
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.fill(.blue)
						.shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
				}
				.foregroundStyle(.white)
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	WorkDayDetailView(
		workDay: WorkDay(
			id: UUID(),
			date: .now,
			isRegistered: true,
			targetHours: 8.0
		),
		summary: nil
	)
}
