import Dependencies
import SnapshotTesting
import SwiftUI
import Testing

// MARK: - SettingsSnapshotTests

@MainActor
struct SettingsSnapshotTests {
	// MARK: - Constants

	private static let snapshotSize = CGSize(
		width: AppConstants.popoverWidth,
		height: AppConstants.popoverHeight
	)

	private static let precision: Float = 0.99

	init() {
		TestDependencies.configure()
	}

	// MARK: - Default State

	@Test
	func settingsDefaultState() {
		let view = ScrollView {
			SettingsSnapshotView()
		}
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
			named: "settings_default"
		)
	}
}

// MARK: - SettingsSnapshotView

/// A self-contained settings view for snapshot testing.
/// Mirrors SettingsView layout with static default values, avoiding
/// dependency resolution issues from SettingsClient in `.onAppear`.
private struct SettingsSnapshotView: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			workSection
			remindersSection
			generalSection
			aboutSection
			quitButton
		}
		.padding(16)
	}

	// MARK: - Work Section

	private var workSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "Work"), icon: "clock.fill", color: .blue)

			VStack(alignment: .leading, spacing: 12) {
				HStack {
					Text(String(localized: "Daily Target"))
						.font(.system(size: 13, weight: .medium))

					Spacer()

					Text("8.0h")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.secondary)
						.monospacedDigit()
				}

				Spacer()

				Slider(value: .constant(8.0), in: 1...12, step: 0.5) {
					Text(String(localized: "Target Hours"))
				}
				.tint(.blue)
			}
			.padding(14)
			.background { cardBackground(cornerRadius: 14) }
			.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
			.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
		}
	}

	// MARK: - Reminders Section

	private var remindersSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "Break Reminders"), icon: "bell.fill", color: .orange)

			VStack(alignment: .leading, spacing: 14) {
				Toggle(isOn: .constant(true)) {
					Text(String(localized: "Enable Break Reminders"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.orange)

				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Text(String(localized: "Interval"))
							.font(.system(size: 13, weight: .medium))

						Spacer()

						Text("60min")
							.font(.system(size: 13, weight: .semibold))
							.foregroundStyle(.secondary)
							.monospacedDigit()
					}

					Spacer()

					Slider(value: .constant(60.0), in: 15...120, step: 15) {
						Text(String(localized: "Reminder Interval"))
					}
					.tint(.orange)
				}
			}
			.padding(14)
			.background { cardBackground(cornerRadius: 14) }
			.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
			.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
		}
	}

	// MARK: - General Section

	private var generalSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "General"), icon: "gearshape.fill", color: .gray)

			VStack(alignment: .leading, spacing: 14) {
				Toggle(isOn: .constant(false)) {
					Text(String(localized: "Launch at Login"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.gray)

				Divider()
					.background(Color.white.opacity(0.08))

				Toggle(isOn: .constant(true)) {
					Text(String(localized: "Remind to register completed work"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.gray)
			}
			.padding(14)
			.background { cardBackground(cornerRadius: 14) }
			.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
			.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
		}
	}

	// MARK: - About Section

	private var aboutSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "About"), icon: "info.circle.fill", color: .cyan)

			VStack(alignment: .leading, spacing: 10) {
				HStack {
					Text(String(localized: "Version"))
						.font(.system(size: 13, weight: .medium))
					Spacer()
					Text("1.0.0")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.secondary)
				}

				Divider()
					.background(Color.white.opacity(0.08))

				HStack {
					Text(String(localized: "Build"))
						.font(.system(size: 13, weight: .medium))
					Spacer()
					Text("1")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.secondary)
				}
			}
			.padding(14)
			.background { cardBackground(cornerRadius: 14) }
			.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
			.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
		}
	}

	// MARK: - Quit Button

	private var quitButton: some View {
		HStack(spacing: 8) {
			Image(systemName: "power")
				.font(.system(size: 14, weight: .semibold))
			Text(String(localized: "Quit worK"))
				.font(.system(size: 14, weight: .medium))
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical, 12)
		.background {
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(.ultraThinMaterial)
				.opacity(0.4)
				.background(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.fill(Color.red.opacity(0.1))
				)
				.overlay {
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.strokeBorder(Color.red.opacity(0.3), lineWidth: 1.5)
				}
		}
		.foregroundStyle(.red)
	}

	// MARK: - Helpers

	private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
		HStack(spacing: 6) {
			ZStack {
				RoundedRectangle(cornerRadius: 6)
					.fill(color.opacity(0.15))
					.frame(width: 24, height: 24)
				Image(systemName: icon)
					.font(.system(size: 11, weight: .semibold))
					.foregroundStyle(color)
			}

			Text(title)
				.font(.system(size: 12, weight: .semibold))
				.foregroundStyle(.primary)
				.textCase(.uppercase)
				.tracking(0.5)
		}
	}

	private func cardBackground(cornerRadius: CGFloat) -> some View {
		RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
			.fill(.ultraThinMaterial)
			.opacity(0.4)
			.background(
				RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
					.fill(Color(white: 0.08).opacity(0.2))
			)
			.overlay {
				RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
}
