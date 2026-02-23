import SQLiteData
import SwiftUI

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
	}

	var body: some Scene {
		// No visible windows -- the app lives entirely in the menu bar.
		// Settings scene provides the standard Preferences window.
		Settings {
			SettingsView()
		}
	}
}
