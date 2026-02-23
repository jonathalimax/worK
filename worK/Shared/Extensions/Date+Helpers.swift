import Foundation

extension Date {
	/// Returns the date normalized to midnight (start of day) in the current calendar.
	func startOfDay(calendar: Calendar = .current) -> Date {
		calendar.startOfDay(for: self)
	}

	/// Returns true if this date falls on the same calendar day as the other date.
	func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
		calendar.isDate(self, inSameDayAs: other)
	}

	/// Returns the hour component of this date.
	func hour(calendar: Calendar = .current) -> Int {
		calendar.component(.hour, from: self)
	}

	/// Returns a date representing the start of the month containing this date.
	func startOfMonth(calendar: Calendar = .current) -> Date {
		let components = calendar.dateComponents([.year, .month], from: self)
		return calendar.date(from: components) ?? self
	}

	/// Returns a date representing the end of the month containing this date.
	func endOfMonth(calendar: Calendar = .current) -> Date {
		guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth(calendar: calendar)) else {
			return self
		}
		return calendar.date(byAdding: .second, value: -1, to: nextMonth) ?? self
	}

	/// Returns a formatted string for display in the status bar (e.g. "6h 32m").
	func shortTimeString(from start: Date) -> String {
		let interval = timeIntervalSince(start)
		return interval.formattedHoursMinutes
	}
}
