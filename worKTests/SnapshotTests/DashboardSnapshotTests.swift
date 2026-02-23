import Dependencies
import SnapshotTesting
import SwiftUI
import Testing

// MARK: - DashboardSnapshotTests

@MainActor
struct DashboardSnapshotTests {
	// MARK: - Constants

	private static let snapshotSize = CGSize(
		width: AppConstants.popoverWidth,
		height: AppConstants.popoverHeight
	)

	private static let precision: Float = 0.99

	init() {
		TestDependencies.configure()
	}

	// MARK: - Hero Image: 60% Progress (Yellow)

	@Test
	func dashboardProgress60Percent() {
		let view = DashboardSnapshotView(
			workedSeconds: 4.8 * 3600,
			remainingSeconds: 3.2 * 3600,
			breakCount: 3,
			totalBreakSeconds: 45 * 60,
			progress: 0.6,
			trackingState: .working,
			aiMessage: "Small consistent efforts compound into remarkable achievements over time.",
			aiMessageType: .motivational
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
			named: "dashboard_60pct_yellow_hero"
		)
	}

	// MARK: - 100% Progress (Green)

	@Test
	func dashboardProgress100Percent() {
		let view = DashboardSnapshotView(
			workedSeconds: 8.0 * 3600,
			remainingSeconds: 0,
			breakCount: 5,
			totalBreakSeconds: 75 * 60,
			progress: 1.0,
			trackingState: .completed,
			aiMessage: "Excellent work today! Don't forget to register your completed hours in your time tracking system.",
			aiMessageType: .registrationReminder
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
			named: "dashboard_100pct_green"
		)
	}

	// MARK: - AI Motivation Message

	@Test
	func dashboardWithAIMotivation() {
		let view = DashboardSnapshotView(
			workedSeconds: 6.5 * 3600,
			remainingSeconds: 1.5 * 3600,
			breakCount: 4,
			totalBreakSeconds: 60 * 60,
			progress: 0.8125,
			trackingState: .working,
			aiMessage: "Your focus today builds the foundation for tomorrow's success. Keep the momentum going!",
			aiMessageType: .motivational
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
			named: "dashboard_ai_motivation"
		)
	}

	// MARK: - Early Day (Red Progress)

	@Test
	func dashboardProgress20Percent() {
		let view = DashboardSnapshotView(
			workedSeconds: 1.6 * 3600,
			remainingSeconds: 6.4 * 3600,
			breakCount: 1,
			totalBreakSeconds: 15 * 60,
			progress: 0.2,
			trackingState: .working,
			aiMessage: "Every hour of focused work is an investment in your future self.",
			aiMessageType: .motivational
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
			named: "dashboard_20pct_red"
		)
	}
}

// MARK: - DashboardSnapshotView

/// A self-contained dashboard view for snapshot testing.
/// Mirrors DashboardView layout exactly but uses static data instead of
/// observable view model and async `.task` modifiers, preventing
/// detached task crashes in the test environment.
private struct DashboardSnapshotView: View {
	let workedSeconds: TimeInterval
	let remainingSeconds: TimeInterval
	let breakCount: Int
	let totalBreakSeconds: TimeInterval
	let progress: Double
	let trackingState: TrackingState
	let aiMessage: String
	let aiMessageType: MessageType

	var body: some View {
		VStack(spacing: 14) {
			progressSection
			aiMessageView
			statsGrid
		}
		.padding(16)
	}

	// MARK: - AI Message

	private var aiMessageView: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 6) {
				ZStack {
					RoundedRectangle(cornerRadius: 6)
						.fill(Color.purple.opacity(0.15))
						.frame(width: 26, height: 26)
					Image(systemName: "sparkles")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(.purple)
				}

				Text(aiHeaderText)
					.font(.system(size: 11, weight: .medium))
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
					.tracking(0.3)

				Spacer()

				Image(systemName: "arrow.clockwise")
					.font(.system(size: 11, weight: .semibold))
					.foregroundStyle(.secondary)
					.frame(width: 24, height: 24)
					.background(Color.white.opacity(0.05))
					.clipShape(Circle())
			}

			Text(aiMessage)
				.font(.system(size: 14, weight: .regular))
				.foregroundStyle(.primary)
				.lineSpacing(2)
				.lineLimit(3)
				.fixedSize(horizontal: false, vertical: true)
		}
		.padding(14)
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

	private var aiHeaderText: String {
		switch aiMessageType {
		case .motivational:
			String(localized: "Daily Motivation")
		case .registrationReminder:
			String(localized: "Registration Reminder")
		}
	}

	// MARK: - Progress Section

	private var progressSection: some View {
		VStack(spacing: 16) {
			ZStack {
				Circle()
					.stroke(Color.white.opacity(0.08), lineWidth: 12)

				Circle()
					.trim(from: 0, to: min(progress, 1.0))
					.stroke(
						LinearGradient(
							colors: [progressColor, progressColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						style: StrokeStyle(lineWidth: 12, lineCap: .round)
					)
					.rotationEffect(.degrees(-90))
					.shadow(color: progressColor.opacity(0.3), radius: 8, x: 0, y: 4)

				VStack(spacing: 6) {
					Text(workedSeconds.formattedHoursMinutes)
						.font(.system(size: 36, weight: .bold, design: .rounded))
						.monospacedDigit()
						.foregroundStyle(.primary)

					Text(trackingState.statusText)
						.font(.system(size: 11, weight: .medium))
						.foregroundStyle(.secondary)
						.textCase(.uppercase)
						.tracking(0.5)
				}
			}
			.frame(width: 160, height: 160)
			.padding(20)
			.background {
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(.ultraThinMaterial)
					.opacity(0.4)
					.background(
						RoundedRectangle(cornerRadius: 20, style: .continuous)
							.fill(Color(white: 0.08).opacity(0.2))
					)
					.overlay {
						RoundedRectangle(cornerRadius: 20, style: .continuous)
							.strokeBorder(
								LinearGradient(
									colors: [
										Color.white.opacity(0.2),
										Color.white.opacity(0.08),
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1.5
							)
					}
			}
			.shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
			.shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

			if remainingSeconds > 0 {
				HStack(spacing: 6) {
					Image(systemName: "clock")
						.font(.system(size: 11, weight: .semibold))
					Text("\(remainingSeconds.formattedHoursMinutes) remaining")
						.font(.system(size: 12, weight: .medium))
				}
				.foregroundStyle(.secondary)
			} else {
				HStack(spacing: 6) {
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 11, weight: .semibold))
					Text(String(localized: "Target reached"))
						.font(.system(size: 12, weight: .medium))
				}
				.foregroundStyle(.green)
			}
		}
	}

	// MARK: - Stats Grid

	private var statsGrid: some View {
		LazyVGrid(
			columns: [
				GridItem(.flexible(), spacing: 10),
				GridItem(.flexible(), spacing: 10),
			],
			spacing: 10
		) {
			StatsCardView(
				title: String(localized: "Worked"),
				value: workedSeconds.formattedHoursMinutes,
				icon: "clock.fill",
				color: .blue
			)

			StatsCardView(
				title: String(localized: "Breaks"),
				value: "\(breakCount)",
				icon: "cup.and.saucer.fill",
				color: .orange
			)

			StatsCardView(
				title: String(localized: "Break Time"),
				value: totalBreakSeconds.formattedHoursMinutes,
				icon: "pause.circle.fill",
				color: .purple
			)

			StatsCardView(
				title: String(localized: "Progress"),
				value: "\(Int(progress * 100))%",
				icon: "chart.line.uptrend.xyaxis",
				color: progressColor
			)
		}
	}

	// MARK: - Helpers

	private var progressColor: Color {
		switch progress {
		case 0..<0.5: .red
		case 0.5..<0.9: .yellow
		default: .green
		}
	}
}
