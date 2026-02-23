import Foundation
import SQLiteData

@Table
struct BreakSession: Identifiable, Equatable, Sendable {
	let id: UUID
	var workDayID: WorkDay.ID
	var startedAt: Date
	var endedAt: Date?
}
