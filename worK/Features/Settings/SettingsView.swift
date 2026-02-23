import AppKit
import Dependencies
import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
	@State private var targetHours: Double = AppConstants.defaultTargetHours
	@State private var launchAtLogin = false
	@State private var reminderEnabled = true
	@State private var reminderIntervalMinutes: Double = Double(AppConstants.defaultReminderIntervalMinutes)
	@State private var stopRecordingEnabled = false
	@State private var stopRecordingTime: Int = AppConstants.defaultStopRecordingTime
	@State private var registerExternally = true

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			workSection
			remindersSection
			generalSection
			aboutSection
			quitButton
		}
		.padding(16)
		.onAppear(perform: loadSettings)
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

					Text("\(targetHours, specifier: "%.1f")h")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.secondary)
						.monospacedDigit()
				}

				Spacer()

				Slider(value: $targetHours, in: 1...12, step: 0.5) {
					Text(String(localized: "Target Hours"))
				}
				.tint(.blue)
				.onChange(of: targetHours) { _, newValue in
					@Dependency(\.settingsClient) var settings
					settings.setTargetHours(newValue)
				}
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
	}

	// MARK: - Reminders Section

	private var remindersSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "Break Reminders"), icon: "bell.fill", color: .orange)

			VStack(alignment: .leading, spacing: 14) {
				Toggle(isOn: $reminderEnabled) {
					Text(String(localized: "Enable Break Reminders"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.orange)
				.onChange(of: reminderEnabled) { _, newValue in
					@Dependency(\.settingsClient) var settings
					settings.setReminderEnabled(newValue)
				}

				if reminderEnabled {
					VStack(alignment: .leading, spacing: 12) {
						HStack {
							Text(String(localized: "Interval"))
								.font(.system(size: 13, weight: .medium))

							Spacer()

							Text("\(Int(reminderIntervalMinutes))min")
								.font(.system(size: 13, weight: .semibold))
								.foregroundStyle(.secondary)
								.monospacedDigit()
						}

						Spacer()

						Slider(value: $reminderIntervalMinutes, in: 15...120, step: 15) {
							Text(String(localized: "Reminder Interval"))
						}
						.tint(.orange)
						.onChange(of: reminderIntervalMinutes) { _, newValue in
							@Dependency(\.settingsClient) var settings
							settings.setReminderIntervalMinutes(Int(newValue))
						}
					}
				}
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
	}

	// MARK: - Auto Stop Section

	private var autoStopSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "Auto Stop"), icon: "stop.circle.fill", color: .red)

			VStack(alignment: .leading, spacing: 14) {
				Toggle(isOn: $stopRecordingEnabled) {
					Text(String(localized: "Stop recording at a set time"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.red)
				.onChange(of: stopRecordingEnabled) { _, newValue in
					@Dependency(\.settingsClient) var settings
					settings.setStopRecordingEnabled(newValue)
				}

				if stopRecordingEnabled {
					Picker(String(localized: "Stop Time"), selection: $stopRecordingTime) {
						ForEach(17...23, id: \.self) { hour in
							Text("\(hour):00").tag(hour)
						}
					}
					.pickerStyle(.menu)
					.onChange(of: stopRecordingTime) { _, newValue in
						@Dependency(\.settingsClient) var settings
						settings.setStopRecordingTime(newValue)
					}
				}
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
	}

	// MARK: - General Section

	private var generalSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			sectionHeader(String(localized: "General"), icon: "gearshape.fill", color: .gray)

			VStack(alignment: .leading, spacing: 14) {
				Toggle(isOn: $launchAtLogin) {
					Text(String(localized: "Launch at Login"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.gray)
				.onChange(of: launchAtLogin) { _, newValue in
					@Dependency(\.settingsClient) var settings
					settings.setLaunchAtLogin(newValue)
				}

				Divider()
					.background(Color.white.opacity(0.08))

				Toggle(isOn: $registerExternally) {
					Text(String(localized: "Remind to register completed work"))
						.font(.system(size: 13, weight: .medium))
				}
				.tint(.gray)
				.onChange(of: registerExternally) { _, newValue in
					@Dependency(\.settingsClient) var settings
					settings.setRegisterExternally(newValue)
				}
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
	}

	// MARK: - Quit Button

	private var quitButton: some View {
		Button {
			NSApplication.shared.terminate(nil)
		} label: {
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
		.buttonStyle(.plain)
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
					Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.secondary)
				}

				Divider()
					.background(Color.white.opacity(0.08))

				HStack {
					Text(String(localized: "Build"))
						.font(.system(size: 13, weight: .medium))
					Spacer()
					Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(.secondary)
				}
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

	private func loadSettings() {
		@Dependency(\.settingsClient) var settings
		targetHours = settings.targetHours()
		launchAtLogin = settings.launchAtLogin()
		reminderEnabled = settings.reminderEnabled()
		reminderIntervalMinutes = Double(settings.reminderIntervalMinutes())
		stopRecordingEnabled = settings.stopRecordingEnabled()
		stopRecordingTime = settings.stopRecordingTime()
		registerExternally = settings.registerExternally()
	}
}

#Preview {
	SettingsView()
		.frame(width: AppConstants.popoverWidth, height: 500)
}
