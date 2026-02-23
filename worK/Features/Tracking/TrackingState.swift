import Foundation

// MARK: - TrackingState

/// Represents the current work tracking state.
enum TrackingState: Sendable, Equatable {
	case idle
	case working
	case onBreak
	case completed

	var statusText: String {
		switch self {
		case .idle:
			String(localized: "Not Working")
		case .working:
			String(localized: "Working")
		case .onBreak:
			String(localized: "On Break")
		case .completed:
			String(localized: "Day Complete")
		}
	}

	var isActive: Bool {
		switch self {
		case .working, .onBreak:
			true
		case .idle, .completed:
			false
		}
	}
}

// MARK: - StatusBarColor

/// Color state for the status bar indicator.
enum StatusBarColor: Sendable {
	case green
	case yellow
	case red
	case gray

	/// Determines color based on progress toward target hours.
	static func from(progress: Double, state: TrackingState) -> StatusBarColor {
		guard state.isActive else { return .gray }
		switch progress {
		case 0..<0.5:
			return .red
		case 0.5..<0.9:
			return .yellow
		default:
			return .green
		}
	}
}
