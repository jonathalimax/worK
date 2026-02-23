import Foundation
import SQLiteData

@Table
struct WorkDay: Identifiable, Equatable, Sendable {
	let id: UUID
	var date: Date
	var isRegistered = false
	var targetHours: Double = 8.0
}
