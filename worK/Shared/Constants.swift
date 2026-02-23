import Foundation

enum AppConstants {
	static let appName = "worK"
	static let popoverWidth: CGFloat = 380
	static let popoverHeight: CGFloat = 750
	static let timerInterval: TimeInterval = 60
	static let reminderDismissInterval: TimeInterval = 30
	static let defaultTargetHours: Double = 8.0
	static let defaultReminderIntervalMinutes: Int = 60
	static let defaultStopRecordingTime: Int = 20 // hour of day (24h)
	static let databaseFileName = "worK.sqlite"

	enum UserDefaultsKeys {
		static let targetHours = "targetHours"
		static let launchAtLogin = "launchAtLogin"
		static let reminderEnabled = "reminderEnabled"
		static let reminderIntervalMinutes = "reminderIntervalMinutes"
		static let stopRecordingEnabled = "stopRecordingEnabled"
		static let stopRecordingTime = "stopRecordingTime"
		static let registerExternally = "registerExternally"
	}
}
