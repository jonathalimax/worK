import Foundation

// MARK: - PopoverTab

enum PopoverTab: String, CaseIterable, Identifiable {
	case dashboard
	case history
	case settings

	var id: String { rawValue }

	var title: String {
		switch self {
		case .dashboard: String(localized: "Today")
		case .history: String(localized: "History")
		case .settings: String(localized: "Settings")
		}
	}

	var iconName: String {
		switch self {
		case .dashboard: "clock.fill"
		case .history: "chart.bar.fill"
		case .settings: "gearshape.fill"
		}
	}
}
