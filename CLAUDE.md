# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**worK** is a macOS menu bar application for automatic work time tracking. It lives exclusively in the menu bar (no dock icon) and automatically tracks work time based on computer activity:
- **Screen unlocked** = working (auto-start/resume)
- **Screen locked** = break (auto-pause)

The app uses a popover interface with tabs for Dashboard, Charts, History, and Settings.

## Build & Run Commands

### Build
```bash
xcodebuild -scheme worK -configuration Debug build
```

### Clean Build
```bash
xcodebuild -scheme worK -configuration Debug clean build
```

### Run from Xcode
Open `worK.xcodeproj` and run the `worK` scheme (⌘R). The app will appear in the menu bar.

### Database Location
```
~/Library/Application Support/worK/worK.sqlite
```

## Architecture

### Tech Stack
- **SwiftUI** - UI framework (with AppKit integration for menu bar)
- **SQLiteData** - Database layer (PointFree library, uses GRDB internally)
- **Swift Dependencies** - Dependency injection (PointFree library)
- **Swift Concurrency** - async/await, actors, AsyncStream
- **Observation** - @Observable macro for view models (iOS 17+)

### App Structure

**Entry Point:**
- `worKApp.swift` - SwiftUI app with no visible windows (menu bar only)
- `AppDelegate.swift` - Initializes StatusBarController and ReminderService
  - Sets activation policy to `.accessory` (hides dock icon)

**Core Components:**

1. **StatusBarController** (`StatusBar/StatusBarController.swift`)
   - Manages NSStatusItem and NSPopover
   - Creates and owns WorkDayViewModel
   - Updates status bar button with time remaining and color
   - Shows popover on click

2. **WorkDayViewModel** (`Features/Tracking/WorkDayViewModel.swift`)
   - Main state manager for the app
   - Tracks work/break sessions using TrackingState enum
   - Observes screen lock/unlock events via NotificationClient
   - Auto-starts work tracking on app launch if screen is unlocked
   - Updates every 60 seconds (timerTask)
   - Manages database queries for today's work day

3. **Database Layer** (`Database/`)
   - `AppDatabase.swift` - Database setup, migrations
   - Schema:
     - `workDays` - One record per calendar day (date, targetHours, isRegistered)
     - `workSessions` - Work periods with startedAt/endedAt timestamps
     - `breakSessions` - Break periods with startedAt/endedAt timestamps
   - `WorkDayQueries.swift` - Extension with database query methods
   - Migrations: v1_initial (tables), v1_indexes

4. **Automatic Tracking System**
   - `NotificationClient.swift` - Observes macOS distributed notifications:
     - `com.apple.screenIsLocked` → triggers break
     - `com.apple.screenIsUnlocked` → triggers work
   - `WorkDayViewModel.observeScreenEvents()` - Responds to screen events
   - `WorkDayViewModel.handleScreenEvent()` - Auto-starts work or break based on screen state

5. **UI Views**
   - `PopoverContentView.swift` - Tab container (Dashboard, Chart, History, Settings)
   - `DashboardView.swift` - Progress circle, stats cards, AI message
   - `SettingsView.swift` - Target hours, reminders, auto-stop configuration
   - `MonthlyChartView.swift` - Chart of work hours by day
   - `HistoryView.swift` - List of past work days

### Design System

The UI follows a **glass-morphic Control Center aesthetic**:
- Dark background (`Color(white: 0.08)`)
- Cards with `.ultraThinMaterial` blur and transparency
- Rounded corners (14pt) with gradient borders
- Multi-layer shadows for depth
- Icon badges with colored circular backgrounds
- Material opacity: 0.4 for transparency
- Background opacity: `Color(white: 0.08).opacity(0.2)`

**Key Constants** (`Shared/Constants.swift`):
- Popover size: 380 × 750 pt
- Timer interval: 60 seconds
- Default target: 8.0 hours
- Default reminder: 60 minutes
- Default stop time: 20:00 (8 PM)

### Dependency Injection Pattern

Uses PointFree's Dependencies library with `@Dependency` property wrapper:

```swift
@Dependency(\.defaultDatabase) private var database
@Dependency(\.notificationClient) private var notificationClient
@Dependency(\.settingsClient) private var settingsClient
```

**Custom Dependencies:**
- `\.defaultDatabase` - SQLite DatabaseQueue
- `\.notificationClient` - Screen lock/unlock events
- `\.settingsClient` - UserDefaults wrapper
- `\.aiMessageClient` - AI-generated encouragement messages

Dependencies are registered in `prepareDependencies` (worKApp.swift).

### State Management

- **@Observable** view models (iOS 17+ Observation framework)
- No TCA or Redux - direct SwiftUI binding
- TrackingState enum: `.idle`, `.working`, `.onBreak`, `.paused`, `.dayComplete`
- StatusBarColor enum: `.gray`, `.green`, `.orange`, `.red`

### Time Tracking Logic

**Auto-Start Flow:**
1. App launches → `WorkDayViewModel.start()`
2. Ensures today's WorkDay exists in database
3. If screen unlocked and trackingState is `.idle` → auto-start work
4. Starts 60s timer and screen event observer

**Screen Lock Flow:**
1. macOS sends `com.apple.screenIsLocked` notification
2. NotificationClient emits `.locked` event
3. WorkDayViewModel ends current work session, starts break session
4. Updates UI to show break status

**Screen Unlock Flow:**
1. macOS sends `com.apple.screenIsUnlocked` notification
2. NotificationClient emits `.unlocked` event
3. WorkDayViewModel ends break session, starts work session
4. Updates UI to show working status

**Auto-Stop:**
- Optional: Stop recording at configured time (e.g., 20:00)
- Prevents overnight tracking if computer left unlocked

### UI Implementation Notes

**Popover Background:**
- Uses `.ultraThinMaterial` for transparent blur effect
- No ScrollView in Dashboard or Settings (content fits in 750pt height)
- Tab bar fixed at top, content scrollable below via ScrollView wrapper

**Slider Spacing:**
- VStack spacing: 12pt between label and slider control
- Applied in SettingsView for Daily Target and Reminder Interval sliders

**Tab Switching:**
- Uses `.onTapGesture` with `.contentShape(Rectangle())` on entire tab area
- Not just icon - full tab is tappable

**Status Bar Text Format:**
- Shows remaining time: "7:58 left" (H:MM format)
- Uses `NSAttributedString` with `.foregroundColor: .white`
- Updates on every timer tick (60s)

## Common Development Patterns

### Adding a New Database Migration

1. Create migration function in `AppDatabase.swift`
2. Register in `migrateDatabase()`:
   ```swift
   migrator.registerMigration("v2_feature_name", migrate: addFeatureColumn)
   ```
3. In DEBUG builds, `eraseDatabaseOnSchemaChange = true` drops DB on schema changes

### Adding a New Dependency

1. Define dependency in `Dependencies/` folder
2. Register in `prepareDependencies` (worKApp.swift)
3. Use with `@Dependency(\.yourDependency)` in view models

### Screen Event Handling

Screen events are handled via `WorkDayViewModel.handleScreenEvent()`:
- Only acts when NOT in `.dayComplete` state
- `.locked` → ends work, starts break
- `.unlocked` → ends break, starts work (even from `.idle`)

### Database Queries

All queries go through `WorkDayQueries.swift` extension methods:
- Pattern: `database.methodName(params)` throws errors
- Always use `@MainActor` context for UI updates after queries
- Wrap in `do-catch` and handle errors appropriately

## Swift Package Dependencies

- **sqlite-data** (PointFree) - ~1.6.0 - Database layer
- **swift-dependencies** (PointFree) - ~1.11.0 - Dependency injection

Dependencies are managed via Swift Package Manager in Xcode.

## Debugging

### Enable SQL Logging

In DEBUG builds, SQL statements are automatically logged:
```swift
config.prepareDatabase { database in
    database.trace { print("SQL: \($0)") }
}
```

### Check Work Day State

Inspect `WorkDayViewModel` properties:
- `trackingState` - Current state (.idle, .working, .onBreak, etc.)
- `currentWorkDay` - Today's WorkDay record
- `summary` - DailySummary with total worked/break times
- `workedSeconds`, `remainingSeconds`, `progress`

### Screen Event Issues

If auto-tracking isn't working:
1. Check Console.app for distributed notification logs
2. Verify `NotificationClient.screenEvents` AsyncStream is active
3. Check `WorkDayViewModel.screenEventTask` is not nil
4. Ensure `observeScreenEvents()` was called in `start()`
