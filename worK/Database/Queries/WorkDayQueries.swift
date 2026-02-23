import Dependencies
import Foundation
import SQLiteData

// MARK: - WorkDay Queries

extension DatabaseWriter {
	/// Finds or creates the WorkDay for a given date.
	@discardableResult
	func ensureWorkDay(
		for date: Date,
		targetHours: Double = AppConstants.defaultTargetHours,
		calendar: Calendar = .current
	) throws -> WorkDay {
		let normalized = calendar.startOfDay(for: date)
		let query = WorkDay.where { col in col.date.eq(normalized) }
		return try write { database in
			if let existing = try query.fetchOne(database) {
				return existing
			}
			@Dependency(\.uuid) var uuid
			let workDay = WorkDay(
				id: uuid(),
				date: normalized,
				isRegistered: false,
				targetHours: targetHours
			)
			try WorkDay.insert { workDay }.execute(database)
			return workDay
		}
	}

	/// Fetches the WorkDay for a given date, if it exists.
	func fetchWorkDay(for date: Date, calendar: Calendar = .current) throws -> WorkDay? {
		let normalized = calendar.startOfDay(for: date)
		let query = WorkDay.where { col in col.date.eq(normalized) }
		return try read { database in
			try query.fetchOne(database)
		}
	}

	/// Fetches all work days in a date range, ordered by date ascending.
	func fetchWorkDays(from start: Date, to end: Date) throws -> [WorkDay] {
		let query = WorkDay
			.where { col in col.date >= start && col.date <= end }
			.order { col in col.date.asc() }
		return try read { database in
			try query.fetchAll(database)
		}
	}

	/// Fetches all work days, ordered by date descending.
	func fetchAllWorkDays() throws -> [WorkDay] {
		let query = WorkDay.order { col in col.date.desc() }
		return try read { database in
			try query.fetchAll(database)
		}
	}

	/// Fetches all months that have work data, ordered by date ascending.
	/// Returns an array of dates representing the first day of each month that contains work logs.
	func fetchMonthsWithData(calendar: Calendar = .current) throws -> [Date] {
		let allWorkDays = try fetchAllWorkDays()
		var monthsSet = Set<Date>()

		for workDay in allWorkDays {
			let monthStart = workDay.date.startOfMonth(calendar: calendar)
			monthsSet.insert(monthStart)
		}

		return Array(monthsSet).sorted()
	}

	/// Toggles the isRegistered flag on a work day.
	func toggleRegistered(for workDayId: UUID) throws {
		try write { database in
			var workDay = try WorkDay.find(database, key: workDayId)
			workDay.isRegistered.toggle()
			try WorkDay.update(workDay).execute(database)
		}
	}

	/// Builds a DailySummary for a given date.
	func dailySummary(for date: Date, calendar: Calendar = .current) throws -> DailySummary? {
		let normalized = calendar.startOfDay(for: date)
		let dayQuery = WorkDay.where { col in col.date.eq(normalized) }
		return try read { database in
			guard let workDay = try dayQuery.fetchOne(database) else {
				return nil
			}

			let sessions = try WorkSession
				.where { col in col.workDayID.eq(workDay.id) }
				.order { col in col.startedAt.asc() }
				.fetchAll(database)

			let breaks = try BreakSession
				.where { col in col.workDayID.eq(workDay.id) }
				.order { col in col.startedAt.asc() }
				.fetchAll(database)

			return DailySummary(workDay: workDay, sessions: sessions, breaks: breaks)
		}
	}
}

// MARK: - WorkSession Queries

extension DatabaseWriter {
	/// Starts a new work session for a given work day.
	@discardableResult
	func startWorkSession(workDayId: UUID, at date: Date) throws -> WorkSession {
		try write { database in
			@Dependency(\.uuid) var uuid
			let session = WorkSession(
				id: uuid(),
				workDayID: workDayId,
				startedAt: date,
				endedAt: nil
			)
			try WorkSession.insert { session }.execute(database)
			return session
		}
	}

	/// Ends the currently active work session for a given work day.
	func endActiveWorkSession(workDayId: UUID, at date: Date) throws {
		let query = WorkSession
			.where { col in col.workDayID.eq(workDayId) && col.endedAt.is(nil) }
		try write { database in
			guard let session = try query.fetchOne(database) else { return }
			var updated = session
			updated.endedAt = date
			try WorkSession.update(updated).execute(database)
		}
	}

	/// Fetches all sessions for a work day.
	func fetchSessions(for workDayId: UUID) throws -> [WorkSession] {
		let query = WorkSession
			.where { col in col.workDayID.eq(workDayId) }
			.order { col in col.startedAt.asc() }
		return try read { database in
			try query.fetchAll(database)
		}
	}

	/// Returns whether there is an active work session for a work day.
	func hasActiveWorkSession(workDayId: UUID) throws -> Bool {
		let query = WorkSession
			.where { col in col.workDayID.eq(workDayId) && col.endedAt.is(nil) }
		return try read { database in
			let count = try query.fetchCount(database)
			return count > 0
		}
	}
}

// MARK: - BreakSession Queries

extension DatabaseWriter {
	/// Starts a new break session for a given work day.
	@discardableResult
	func startBreakSession(workDayId: UUID, at date: Date) throws -> BreakSession {
		try write { database in
			@Dependency(\.uuid) var uuid
			let breakSession = BreakSession(
				id: uuid(),
				workDayID: workDayId,
				startedAt: date,
				endedAt: nil
			)
			try BreakSession.insert { breakSession }.execute(database)
			return breakSession
		}
	}

	/// Ends the currently active break session for a given work day.
	func endActiveBreakSession(workDayId: UUID, at date: Date) throws {
		let query = BreakSession
			.where { col in col.workDayID.eq(workDayId) && col.endedAt.is(nil) }
		try write { database in
			guard let breakSession = try query.fetchOne(database) else { return }
			var updated = breakSession
			updated.endedAt = date
			try BreakSession.update(updated).execute(database)
		}
	}

	/// Fetches all break sessions for a work day.
	func fetchBreaks(for workDayId: UUID) throws -> [BreakSession] {
		let query = BreakSession
			.where { col in col.workDayID.eq(workDayId) }
			.order { col in col.startedAt.asc() }
		return try read { database in
			try query.fetchAll(database)
		}
	}
}
