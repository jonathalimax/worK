import Foundation
import SQLiteData

@Table
struct WorkSession: Identifiable, Equatable, Sendable {
	let id: UUID
	var workDayID: WorkDay.ID
	var startedAt: Date
	var endedAt: Date?
}
