import Dependencies
import Foundation
import Observation
import SQLiteData

// MARK: - WorkDayViewModel

@Observable
@MainActor
final class WorkDayViewModel {
	// MARK: - Dependencies

	@ObservationIgnored @Dependency(\.defaultDatabase) private var database
	@ObservationIgnored @Dependency(\.notificationClient) private var notificationClient
	@ObservationIgnored @Dependency(\.settingsClient) private var settingsClient
	@ObservationIgnored @Dependency(\.screenLockClient) private var screenLockClient
	@ObservationIgnored @Dependency(\.date.now) private var now
	@ObservationIgnored @Dependency(\.uuid) private var uuid
	@ObservationIgnored @Dependency(\.continuousClock) private var clock
	@ObservationIgnored @Dependency(\.calendar) private var calendar

	// MARK: - Published State

	var trackingState: TrackingState = .idle
	var statusBarColor: StatusBarColor = .gray
	var statusBarText: String = AppConstants.appName
	var workedSeconds: TimeInterval = 0
	var remainingSeconds: TimeInterval = 0
	var breakCount: Int = 0
	var totalBreakSeconds: TimeInterval = 0
	var progress: Double = 0
	var currentWorkDay: WorkDay?
	var summary: DailySummary?

	// MARK: - Private State

	@ObservationIgnored private var timerTask: Task<Void, Never>?
	@ObservationIgnored private var screenEventTask: Task<Void, Never>?
	@ObservationIgnored private var isStarted = false
	@ObservationIgnored private var lastScreenEventTime: Date?
	@ObservationIgnored private var lastScreenEvent: ScreenEvent?

	// MARK: - Initialization

	init() {}

	deinit {
		timerTask?.cancel()
		screenEventTask?.cancel()
	}

	// MARK: - Lifecycle

	func start() {
		guard !isStarted else { return }
		isStarted = true

		Task { @MainActor in
			await ensureTodayExists()
			await refreshStats()
			startTimer()
			observeScreenEvents()

			// Auto-start work tracking when app launches (screen is unlocked)
			if trackingState == .idle {
				await startWork()
			}
		}
	}

	// MARK: - Actions

	func startWork() async {
		guard let workDay = currentWorkDay else { return }

		do {
			// End any active break
			try database.endActiveBreakSession(workDayId: workDay.id, at: now)

			// Start a new work session
			try database.startWorkSession(workDayId: workDay.id, at: now)

			trackingState = .working
			await refreshStats()
		} catch {
			print("Failed to start work: \(error)")
		}
	}

	func stopWork() async {
		guard let workDay = currentWorkDay else { return }

		do {
			// End active work session
			try database.endActiveWorkSession(workDayId: workDay.id, at: now)

			// End any active break
			try database.endActiveBreakSession(workDayId: workDay.id, at: now)

			trackingState = .idle
			await refreshStats()
		} catch {
			print("Failed to stop work: \(error)")
		}
	}

	func toggleWork() async {
		switch trackingState {
		case .idle, .completed:
			await startWork()
		case .working, .onBreak:
			await stopWork()
		}
	}

	/// Updates the target hours for the current work day.
	func updateTargetHours(_ hours: Double) async {
		guard let workDay = currentWorkDay else { return }

		do {
			try database.updateTargetHours(for: workDay.id, targetHours: hours)
			await refreshStats()
		} catch {
			print("Failed to update target hours: \(error)")
		}
	}

	/// Manually initiates a break by locking the screen.
	/// This triggers the automatic screen lock observer which handles the actual break session.
	func takeBreak() async {
		// Only allow taking break if we're actively working
		guard trackingState == .working else { return }

		do {
			// Lock the screen, which will trigger the automatic break tracking
			try await screenLockClient.lockScreen()
		} catch {
			print("Failed to lock screen: \(error)")
			// Fallback: manually start break if screen lock fails
			await startBreak()
		}
	}

	/// Fallback method to manually start a break without screen lock.
	private func startBreak() async {
		guard let workDay = currentWorkDay else { return }

		do {
			// End active work session
			try database.endActiveWorkSession(workDayId: workDay.id, at: now)

			// Start break session
			try database.startBreakSession(workDayId: workDay.id, at: now)

			trackingState = .onBreak
			await refreshStats()
		} catch {
			print("Failed to start break: \(error)")
		}
	}

	// MARK: - Screen Events

	private func observeScreenEvents() {
		screenEventTask?.cancel()
		screenEventTask = Task { @MainActor [weak self] in
			guard let self else { return }
			print("👀 Started observing screen events")
			for await event in notificationClient.screenEvents() {
				guard !Task.isCancelled else {
					print("⚠️ Screen event observation cancelled")
					break
				}
				await self.handleScreenEvent(event)
			}
			print("⚠️ Screen event observation ended")
		}
	}

	private func handleScreenEvent(_ event: ScreenEvent) async {
		print("🔔 Screen event received: \(event), current state: \(trackingState)")

		// Deduplicate events: ignore if same event within 2 seconds
		if let lastEvent = lastScreenEvent,
		   let lastTime = lastScreenEventTime,
		   lastEvent == event,
		   now.timeIntervalSince(lastTime) < 2.0 {
			print("⚠️ Ignoring duplicate \(event) event (within 2 seconds)")
			return
		}

		lastScreenEvent = event
		lastScreenEventTime = now

		guard let workDay = currentWorkDay else {
			print("⚠️ No current work day, ignoring screen event")
			return
		}

		// Don't track if work day is already completed
		guard trackingState != .completed else {
			print("⚠️ Work day already completed, ignoring screen event")
			return
		}

		do {
			switch event {
			case .locked:
				print("🔒 Handling screen lock")
				// Screen locked: end work session, start break (if we were working)
				if trackingState == .working || trackingState == .onBreak {
					try database.endActiveWorkSession(workDayId: workDay.id, at: now)
					try database.startBreakSession(workDayId: workDay.id, at: now)
					trackingState = .onBreak
					print("✅ Break session started")
				} else {
					print("⚠️ Not working or on break, ignoring lock event")
				}

			case .unlocked:
				print("🔓 Handling screen unlock")
				// Screen unlocked: automatically start/resume work
				// End any active break first
				try database.endActiveBreakSession(workDayId: workDay.id, at: now)
				print("✅ Ended active break session")

				// Start new work session
				try database.startWorkSession(workDayId: workDay.id, at: now)
				trackingState = .working
				print("✅ Work session started, state set to .working")
			}

			await refreshStats()
			print("📊 Stats refreshed, final state: \(trackingState)")
		} catch {
			print("❌ Failed to handle screen event: \(error)")
		}
	}

	// MARK: - Timer

	private func startTimer() {
		timerTask?.cancel()
		timerTask = Task { @MainActor [weak self] in
			guard let self else { return }
			while !Task.isCancelled {
				try? await clock.sleep(for: .seconds(AppConstants.timerInterval))
				guard !Task.isCancelled else { break }
				await self.tick()
			}
		}
	}

	private func tick() async {
		// Check for day change
		if let workDay = currentWorkDay,
		   !now.isSameDay(as: workDay.date, calendar: calendar) {
			// Day changed: stop current work and reset
			await stopWork()
			await ensureTodayExists()
		}

		// Check stop recording time
		if settingsClient.stopRecordingEnabled(),
		   trackingState == .working || trackingState == .onBreak {
			let stopHour = settingsClient.stopRecordingTime()
			if now.hour(calendar: calendar) >= stopHour {
				await stopWork()
				trackingState = .completed
			}
		}

		await refreshStats()
	}

	// MARK: - Data

	private func ensureTodayExists() async {
		let targetHours = settingsClient.targetHours()
		do {
			let workDay = try database.ensureWorkDay(
				for: now,
				targetHours: targetHours,
				calendar: calendar
			)
			currentWorkDay = workDay
		} catch {
			print("Failed to ensure work day: \(error)")
		}
	}

	func refreshStats() async {
		guard let workDay = currentWorkDay else {
			resetStats()
			return
		}

		do {
			let dailySummary = try database.dailySummary(for: workDay.date, calendar: calendar)
			guard let dailySummary else {
				resetStats()
				return
			}

			summary = dailySummary
			let currentTime = now
			workedSeconds = dailySummary.workedSeconds(now: currentTime)
			remainingSeconds = dailySummary.remainingSeconds(now: currentTime)
			breakCount = dailySummary.breakCount
			totalBreakSeconds = dailySummary.breakSeconds(now: currentTime)
			progress = dailySummary.progress(now: currentTime)

			// Update tracking state based on active sessions
			// Only update state if we're currently idle (initial state) or if we need to detect completion
			let previousState = trackingState
			if trackingState == .idle {
				// When idle, set state based on what's actually happening in the database
				if dailySummary.isOnBreak {
					trackingState = .onBreak
				} else if dailySummary.isWorking {
					trackingState = .working
				}
			} else {
				// When already tracking, only check for completion state
				// Don't override explicit state changes from screen events
				if workedSeconds > 0, remainingSeconds <= 0, trackingState != .completed {
					trackingState = .completed
				}
			}

			if previousState != trackingState {
				print("📊 refreshStats changed state from \(previousState) to \(trackingState) (isWorking: \(dailySummary.isWorking), isOnBreak: \(dailySummary.isOnBreak))")
			}

			// Update status bar
			updateStatusBar()
		} catch {
			print("Failed to refresh stats: \(error)")
		}
	}

	private func resetStats() {
		workedSeconds = 0
		remainingSeconds = settingsClient.targetHours() * 3600
		breakCount = 0
		totalBreakSeconds = 0
		progress = 0
		trackingState = .idle
		statusBarColor = .gray
		statusBarText = AppConstants.appName
		summary = nil
	}

	private func updateStatusBar() {
		statusBarColor = StatusBarColor.from(progress: progress, state: trackingState)

		switch trackingState {
		case .idle:
			statusBarText = AppConstants.appName
		case .working:
			if remainingSeconds > 0 {
				statusBarText = String(localized: "\(remainingSeconds.formattedHoursMinutes) left")
			} else {
				statusBarText = String(localized: "Goal reached!")
			}
		case .onBreak:
			if remainingSeconds > 0 {
				statusBarText = String(localized: "\(remainingSeconds.formattedHoursMinutes) left (break)")
			} else {
				statusBarText = String(localized: "Goal reached! (break)")
			}
		case .completed:
			statusBarText = String(localized: "Day complete")
		}
	}
}
