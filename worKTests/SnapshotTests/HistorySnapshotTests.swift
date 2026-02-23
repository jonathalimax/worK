import Dependencies
import SnapshotTesting
import SwiftUI
import Testing

// MARK: - HistorySnapshotTests

@MainActor
struct HistorySnapshotTests {
	// MARK: - Constants

	private static let snapshotSize = CGSize(
		width: AppConstants.popoverWidth,
		height: AppConstants.popoverHeight
	)

	private static let precision: Float = 0.99

	init() {
		TestDependencies.configure()
	}

	// MARK: - Helpers

	/// Creates a realistic set of work days for the past 7 days with mixed registered/unregistered states.
	private static func generateHistoryData() -> [(workDay: WorkDay, summary: DailySummary)] {
		let calendar = Calendar.current
		let today = Date()

		let patterns: [(daysAgo: Int, hours: Double, breaks: Int, registered: Bool)] = [
			(0, 5.5, 2, false),   // Today - still working
			(1, 8.2, 4, true),    // Yesterday - registered
			(2, 7.8, 3, true),    // 2 days ago - registered
			(3, 6.5, 2, false),   // 3 days ago - not registered
			(4, 8.0, 5, true),    // 4 days ago - registered
			(5, 9.1, 4, false),   // 5 days ago - not registered
			(6, 7.3, 3, true),    // 6 days ago - registered
		]

		return patterns.compactMap { pattern in
			guard let date = calendar.date(byAdding: .day, value: -pattern.daysAgo, to: today) else {
				return nil
			}

			let startOfDay = calendar.startOfDay(for: date)
			let workDay = WorkDay(
				id: UUID(),
				date: startOfDay,
				isRegistered: pattern.registered,
				targetHours: 8.0
			)

			let workStart = calendar.date(byAdding: .hour, value: 9, to: startOfDay) ?? startOfDay
			let workedSeconds = pattern.hours * 3600
			let workEnd = workStart.addingTimeInterval(workedSeconds + Double(pattern.breaks) * 15 * 60)

			let sessions = [
				WorkSession(
					id: UUID(),
					workDayID: workDay.id,
					startedAt: workStart,
					endedAt: pattern.daysAgo == 0 ? nil : workEnd
				),
			]

			var breakSessions: [BreakSession] = []
			for breakIndex in 0..<pattern.breaks {
				let breakStart = workStart.addingTimeInterval(
					Double(breakIndex + 1) * (workedSeconds / Double(pattern.breaks + 1))
				)
				let breakEnd = breakStart.addingTimeInterval(15 * 60)
				breakSessions.append(BreakSession(
					id: UUID(),
					workDayID: workDay.id,
					startedAt: breakStart,
					endedAt: breakEnd
				))
			}

			let summary = DailySummary(
				workDay: workDay,
				sessions: sessions,
				breaks: breakSessions
			)

			return (workDay, summary)
		}
	}

	// MARK: - History with Mixed Data

	@Test
	func historyMixedRegistration() {
		let historyData = Self.generateHistoryData()

		let view = HistorySnapshotView(historyData: historyData)
			.frame(
				width: Self.snapshotSize.width,
				height: Self.snapshotSize.height
			)
			.background(.ultraThinMaterial)
			.background(Color(white: 0.08))
			.environment(\.colorScheme, .dark)

		assertSnapshot(
			of: NSHostingController(rootView: view),
			as: .image(
				precision: Self.precision,
				size: Self.snapshotSize
			),
			named: "history_mixed_registration"
		)
	}
}

// MARK: - HistorySnapshotView

/// A self-contained history view for snapshot testing without database dependencies.
private struct HistorySnapshotView: View {
	let historyData: [(workDay: WorkDay, summary: DailySummary)]

	var body: some View {
		VStack(spacing: 0) {
			filterBar
			historyList
		}
	}

	// MARK: - Filter Bar

	private var filterBar: some View {
		HStack(spacing: 12) {
			HStack(spacing: 8) {
				ZStack {
					RoundedRectangle(cornerRadius: 8)
						.fill(Color.purple.opacity(0.15))
						.frame(width: 32, height: 32)
					Image(systemName: "calendar")
						.font(.system(size: 14, weight: .semibold))
						.foregroundStyle(.purple)
				}

				Text(String(localized: "Work History"))
					.font(.system(size: 18, weight: .bold))
			}

			Spacer()

			Toggle(isOn: .constant(false)) {
				Text(String(localized: "Unregistered"))
					.font(.system(size: 11, weight: .medium))
			}
			.toggleStyle(.checkbox)
			.tint(.purple)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
	}

	// MARK: - History List

	private var historyList: some View {
		ScrollView {
			VStack(spacing: 8) {
				ForEach(historyData, id: \.workDay.id) { item in
					HistoryRowView(
						workDay: item.workDay,
						summary: item.summary,
						onToggleRegistered: {},
						onTap: {}
					)
				}
			}
			.padding(.horizontal, 16)
			.padding(.bottom, 16)
		}
	}
}
