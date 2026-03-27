import SQLiteData
import SwiftUI
import TelemetryDeck

@main
struct WorkApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	init() {
		prepareDependencies {
			do {
				$0.defaultDatabase = try makeAppDatabase()
			} catch {
				fatalError("Failed to initialize database: \(error)")
			}
		}
		TelemetryDeck.initialize(
			config: TelemetryManagerConfiguration(
				appID: "562F4D05-44DA-41BF-B640-671ED4C1EBBE"
			)
		)
	}

	var body: some Scene {
		// No visible windows -- the app lives entirely in the menu bar.
		// Settings scene provides the standard Preferences window.
		Settings {
			SettingsView()
		}
	}
}
