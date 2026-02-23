import Foundation

/// Computed summary of a single work day, derived from sessions.
struct DailySummary: Sendable {
	let workDay: WorkDay
	let sessions: [WorkSession]
	let breaks: [BreakSession]

	/// Total worked seconds across all sessions (active session uses `now`).
	func workedSeconds(now: Date = .now) -> TimeInterval {
		sessions.reduce(0) { total, session in
			let end = session.endedAt ?? now
			return total + end.timeIntervalSince(session.startedAt)
		}
	}

	/// Total break seconds across all breaks (active break uses `now`).
	func breakSeconds(now: Date = .now) -> TimeInterval {
		breaks.reduce(0) { total, breakSession in
			let end = breakSession.endedAt ?? now
			return total + end.timeIntervalSince(breakSession.startedAt)
		}
	}

	/// Number of completed breaks.
	var breakCount: Int {
		breaks.filter { $0.endedAt != nil }.count
	}

	/// Whether there is currently an active work session.
	var isWorking: Bool {
		sessions.contains { $0.endedAt == nil }
	}

	/// Whether there is currently an active break.
	var isOnBreak: Bool {
		breaks.contains { $0.endedAt == nil }
	}

	/// Remaining seconds to reach target hours.
	func remainingSeconds(now: Date = .now) -> TimeInterval {
		let target = workDay.targetHours * 3600
		let worked = workedSeconds(now: now)
		return max(target - worked, 0)
	}

	/// Progress toward target (0.0 to 1.0+).
	func progress(now: Date = .now) -> Double {
		let target = workDay.targetHours * 3600
		guard target > 0 else { return 1.0 }
		return workedSeconds(now: now) / target
	}

	/// The earliest session start time for the day.
	var dayStartTime: Date? {
		sessions.map(\.startedAt).min()
	}

	/// The latest session end time or current time if still working.
	func dayEndTime(now: Date = .now) -> Date? {
		guard !sessions.isEmpty else { return nil }
		if isWorking { return now }
		return sessions.compactMap(\.endedAt).max()
	}
}
