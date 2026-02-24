import Foundation

extension TimeInterval {
	/// Formats the interval as "H:MM" (e.g. "7:58", "0:45").
	var formattedHoursMinutes: String {
		let totalSeconds = Int(max(self, 0))
		let hours = totalSeconds / 3600
		let minutes = (totalSeconds % 3600) / 60
		return "\(hours):\(String(format: "%02d", minutes))"
	}

	/// Formats the interval as "X hours Y minutes" for accessibility.
	var formattedAccessible: String {
		let totalSeconds = Int(max(self, 0))
		let hours = totalSeconds / 3600
		let minutes = (totalSeconds % 3600) / 60
		var parts: [String] = []
		if hours > 0 {
			parts.append(String(localized: "^\(hours) hour(s)"))
		}
		if minutes > 0 || parts.isEmpty {
			parts.append(String(localized: "^\(minutes) minute(s)"))
		}
		return parts.joined(separator: " ")
	}

	/// Returns the interval in hours as a Double.
	var inHours: Double {
		self / 3600.0
	}

	/// Returns the interval in minutes as a Double.
	var inMinutes: Double {
		self / 60.0
	}
}
