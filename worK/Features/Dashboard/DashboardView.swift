import Dependencies
import SwiftUI

// MARK: - DashboardView

struct DashboardView: View {
	let viewModel: WorkDayViewModel

	var body: some View {
		VStack(spacing: 14) {
			progressSection
			aiMessageView

			statsGrid

			// Show Take a Break button only when working
			if viewModel.trackingState == .working {
				takeBreakButton
					.padding(.bottom)
			}
		}
		.padding()
	}

	// MARK: - AI Message View

	private var aiMessageView: some View {
		AIMessageView(messageType: shouldShowReminder ? .registrationReminder : .motivational)
	}

	private var shouldShowReminder: Bool {
		@Dependency(\.settingsClient) var settingsClient
		let registerEnabled = settingsClient.registerExternally()
		let targetReached = viewModel.progress >= 1.0
		return registerEnabled && targetReached
	}

	// MARK: - Take Break Button

	private var takeBreakButton: some View {
		Button {
			Task { @MainActor in
				await viewModel.takeBreak()
			}
		} label: {
			HStack(spacing: 8) {
				Image(systemName: "cup.and.saucer.fill")
					.font(.system(size: 14, weight: .semibold))
				Text(String(localized: "Take a Break"))
					.font(.system(size: 14, weight: .semibold))
			}
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity)
			.frame(height: 44)
			.background {
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(
						LinearGradient(
							colors: [
								Color.orange,
								Color.orange.opacity(0.8)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.overlay {
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.strokeBorder(
								Color.white.opacity(0.2),
								lineWidth: 1
							)
					}
			}
			.shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
			.shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
		}
		.buttonStyle(.plain)
	}

	// MARK: - Progress Section

	private var progressSection: some View {
		VStack(spacing: 16) {
			ZStack {
				// Background circle
				Circle()
					.stroke(Color.white.opacity(0.08), lineWidth: 12)

				// Progress circle
				Circle()
					.trim(from: 0, to: min(viewModel.progress, 1.0))
					.stroke(
						LinearGradient(
							colors: [progressColor, progressColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						style: StrokeStyle(lineWidth: 12, lineCap: .round)
					)
					.rotationEffect(.degrees(-90))
					.animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.progress)
					.shadow(color: progressColor.opacity(0.3), radius: 8, x: 0, y: 4)

				// Center content
				VStack(spacing: 6) {
					if viewModel.trackingState == .idle && viewModel.workedSeconds == 0 {
						LottieView(
							animationName: "clock-idle",
							loopMode: .loop,
							animationSpeed: 0.8
						)
						.frame(width: 60, height: 60)
					} else {
						Text(viewModel.workedSeconds.formattedHoursMinutes)
							.font(.system(size: 36, weight: .bold, design: .rounded))
							.monospacedDigit()
							.foregroundStyle(.primary)
					}

					Text(viewModel.trackingState.statusText)
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
										Color.white.opacity(0.08)
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

			// Status text
			if viewModel.remainingSeconds > 0 {
				HStack(spacing: 6) {
					Image(systemName: "clock")
						.font(.system(size: 11, weight: .semibold))
					Text("\(viewModel.remainingSeconds.formattedHoursMinutes) \(String(localized: "remaining"))")
						.font(.system(size: 12, weight: .medium))
				}
				.foregroundStyle(.secondary)
			} else {
				VStack(spacing: 8) {
					LottieView(
						animationName: "success",
						loopMode: .playOnce,
						animationSpeed: 1.5
					)
					.frame(width: 50, height: 50)

					HStack(spacing: 6) {
						Text(String(localized: "Target reached"))
							.font(.system(size: 12, weight: .medium))
					}
					.foregroundStyle(.green)
				}
			}
		}
	}

	// MARK: - Stats Grid

	private var statsGrid: some View {
		LazyVGrid(
			columns: [
				GridItem(.flexible(), spacing: 10),
				GridItem(.flexible(), spacing: 10)
			],
			spacing: 10
		) {
			StatsCardView(
				title: String(localized: "Worked"),
				value: viewModel.workedSeconds.formattedHoursMinutes,
				icon: "clock.fill",
				color: .blue
			)

			StatsCardView(
				title: String(localized: "Breaks"),
				value: "\(viewModel.breakCount)",
				icon: "cup.and.saucer.fill",
				color: .orange
			)

			StatsCardView(
				title: String(localized: "Break Time"),
				value: viewModel.totalBreakSeconds.formattedHoursMinutes,
				icon: "pause.circle.fill",
				color: .purple
			)

			StatsCardView(
				title: String(localized: "Progress"),
				value: "\(Int(viewModel.progress * 100))%",
				icon: "chart.line.uptrend.xyaxis",
				color: progressColor
			)
		}
	}

	// MARK: - Helpers

	private var progressColor: Color {
		switch viewModel.progress {
		case 0..<0.5: .red
		case 0.5..<0.9: .yellow
		default: .green
		}
	}
}

#Preview {
	DashboardView(viewModel: WorkDayViewModel())
		.frame(width: AppConstants.popoverWidth)
}
