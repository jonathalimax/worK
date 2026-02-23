import Dependencies
import DependenciesMacros
import Foundation
import ServiceManagement

// MARK: - SettingsClient

@DependencyClient
struct SettingsClient: Sendable {
	var targetHours: @Sendable () -> Double = { AppConstants.defaultTargetHours }
	var setTargetHours: @Sendable (Double) -> Void
	var launchAtLogin: @Sendable () -> Bool = { false }
	var setLaunchAtLogin: @Sendable (Bool) -> Void
	var reminderEnabled: @Sendable () -> Bool = { true }
	var setReminderEnabled: @Sendable (Bool) -> Void
	var reminderIntervalMinutes: @Sendable () -> Int = { AppConstants.defaultReminderIntervalMinutes }
	var setReminderIntervalMinutes: @Sendable (Int) -> Void
	var stopRecordingEnabled: @Sendable () -> Bool = { false }
	var setStopRecordingEnabled: @Sendable (Bool) -> Void
	var stopRecordingTime: @Sendable () -> Int = { AppConstants.defaultStopRecordingTime }
	var setStopRecordingTime: @Sendable (Int) -> Void
	var registerExternally: @Sendable () -> Bool = { true }
	var setRegisterExternally: @Sendable (Bool) -> Void
}

// MARK: - Live Implementation

extension SettingsClient: DependencyKey {
	static let liveValue: SettingsClient = {
		// Register defaults once
		UserDefaults.standard.register(defaults: [
			AppConstants.UserDefaultsKeys.targetHours: AppConstants.defaultTargetHours,
			AppConstants.UserDefaultsKeys.launchAtLogin: false,
			AppConstants.UserDefaultsKeys.reminderEnabled: true,
			AppConstants.UserDefaultsKeys.reminderIntervalMinutes: AppConstants.defaultReminderIntervalMinutes,
			AppConstants.UserDefaultsKeys.stopRecordingEnabled: false,
			AppConstants.UserDefaultsKeys.stopRecordingTime: AppConstants.defaultStopRecordingTime,
			AppConstants.UserDefaultsKeys.registerExternally: true
		])

		return SettingsClient(
			targetHours: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.double(forKey: AppConstants.UserDefaultsKeys.targetHours)
			},
			setTargetHours: { value in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(value, forKey: AppConstants.UserDefaultsKeys.targetHours)
			},
			launchAtLogin: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.bool(forKey: AppConstants.UserDefaultsKeys.launchAtLogin)
			},
			setLaunchAtLogin: { enabled in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(enabled, forKey: AppConstants.UserDefaultsKeys.launchAtLogin)
				do {
					if enabled {
						try SMAppService.mainApp.register()
					} else {
						try SMAppService.mainApp.unregister()
					}
				} catch {
					print("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
				}
			},
			reminderEnabled: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.bool(forKey: AppConstants.UserDefaultsKeys.reminderEnabled)
			},
			setReminderEnabled: { value in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(value, forKey: AppConstants.UserDefaultsKeys.reminderEnabled)
			},
			reminderIntervalMinutes: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.integer(forKey: AppConstants.UserDefaultsKeys.reminderIntervalMinutes)
			},
			setReminderIntervalMinutes: { value in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(value, forKey: AppConstants.UserDefaultsKeys.reminderIntervalMinutes)
			},
			stopRecordingEnabled: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.bool(forKey: AppConstants.UserDefaultsKeys.stopRecordingEnabled)
			},
			setStopRecordingEnabled: { value in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(value, forKey: AppConstants.UserDefaultsKeys.stopRecordingEnabled)
			},
			stopRecordingTime: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.integer(forKey: AppConstants.UserDefaultsKeys.stopRecordingTime)
			},
			setStopRecordingTime: { value in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(value, forKey: AppConstants.UserDefaultsKeys.stopRecordingTime)
			},
			registerExternally: {
				nonisolated(unsafe) let defaults = UserDefaults.standard
				return defaults.bool(forKey: AppConstants.UserDefaultsKeys.registerExternally)
			},
			setRegisterExternally: { value in
				nonisolated(unsafe) let defaults = UserDefaults.standard
				defaults.set(value, forKey: AppConstants.UserDefaultsKeys.registerExternally)
			}
		)
	}()

	static let testValue = SettingsClient()
	static let previewValue = SettingsClient()
}

extension DependencyValues {
	var settingsClient: SettingsClient {
		get { self[SettingsClient.self] }
		set { self[SettingsClient.self] = newValue }
	}
}
