import Dependencies
import DependenciesMacros
import TelemetryDeck

// MARK: - Supporting Enums

enum PopoverSource: String {
    case leftClick = "leftClick"
    case menu = "menu"
}

enum BreakSource: String {
    case screenLock = "screenLock"
    case manual = "manual"
}

enum BreakEndSource: String {
    case screenUnlock = "screenUnlock"
    case manual = "manual"
}

enum ChartDirection: String {
    case previous = "previous"
    case next = "next"
}

enum SettingKey: String {
    case targetHours = "targetHours"
    case reminderEnabled = "reminderEnabled"
    case reminderInterval = "reminderInterval"
    case launchAtLogin = "launchAtLogin"
    case stopRecordingEnabled = "stopRecordingEnabled"
    case stopRecordingTime = "stopRecordingTime"
    case registerExternally = "registerExternally"
}

// MARK: - AnalyticsEvent

enum AnalyticsEvent {
    // App lifecycle
    case appLaunched
    case appTerminated

    // Panel
    case popoverOpened(source: PopoverSource)
    case popoverClosed
    case tabViewed(PopoverTab)

    // Work tracking
    case workStarted
    case workStopped
    case workDayCompleted(hoursWorked: String)

    // Breaks
    case breakStarted(source: BreakSource)
    case breakEnded(source: BreakEndSource)

    // Reminders
    case reminderShown(workedTime: String)
    case reminderDismissed
    case reminderTakeBreakTapped
    case reminderAutoDismissed

    // Settings
    case settingChanged(SettingKey, value: String)

    // Right-click menu
    case menuTodayTapped
    case menuHistoryTapped
    case menuSettingsTapped
    case menuQuitTapped

    // History & Charts
    case historyItemExpanded
    case historyRegisteredToggled(Bool)
    case chartMonthNavigated(ChartDirection)

    // Support / About
    case supportGithubSponsorsTapped
    case updatesCheckTapped
    case aiMessageRefreshed

    // MARK: - TelemetryDeck mapping

    var signalName: String {
        switch self {
        case .appLaunched: return "app.launched"
        case .appTerminated: return "app.terminated"
        case .popoverOpened: return "popover.opened"
        case .popoverClosed: return "popover.closed"
        case .tabViewed: return "tab.viewed"
        case .workStarted: return "work.started"
        case .workStopped: return "work.stopped"
        case .workDayCompleted: return "work.dayCompleted"
        case .breakStarted: return "break.started"
        case .breakEnded: return "break.ended"
        case .reminderShown: return "reminder.shown"
        case .reminderDismissed: return "reminder.dismissed"
        case .reminderTakeBreakTapped: return "reminder.takeBreakTapped"
        case .reminderAutoDismissed: return "reminder.autoDismissed"
        case .settingChanged: return "settings.changed"
        case .menuTodayTapped: return "menu.todayTapped"
        case .menuHistoryTapped: return "menu.historyTapped"
        case .menuSettingsTapped: return "menu.settingsTapped"
        case .menuQuitTapped: return "menu.quitTapped"
        case .historyItemExpanded: return "history.itemExpanded"
        case .historyRegisteredToggled: return "history.registeredToggled"
        case .chartMonthNavigated: return "chart.monthNavigated"
        case .supportGithubSponsorsTapped: return "support.githubSponsorsTapped"
        case .updatesCheckTapped: return "updates.checkTapped"
        case .aiMessageRefreshed: return "aiMessage.refreshed"
        }
    }

    var parameters: [String: String] {
        switch self {
        case .popoverOpened(let source):
            return ["source": source.rawValue]
        case .tabViewed(let tab):
            return ["tab": tab.rawValue]
        case .workDayCompleted(let hours):
            return ["hoursWorked": hours]
        case .breakStarted(let source):
            return ["source": source.rawValue]
        case .breakEnded(let source):
            return ["source": source.rawValue]
        case .reminderShown(let time):
            return ["workedTime": time]
        case .settingChanged(let key, let value):
            return ["key": key.rawValue, "value": value]
        case .historyRegisteredToggled(let value):
            return ["value": value ? "true" : "false"]
        case .chartMonthNavigated(let direction):
            return ["direction": direction.rawValue]
        default:
            return [:]
        }
    }
}

// MARK: - AnalyticsClient

@DependencyClient
struct AnalyticsClient: Sendable {
    var track: @Sendable (AnalyticsEvent) -> Void = { _ in }
}

extension AnalyticsClient: DependencyKey {
    static let liveValue = AnalyticsClient(
        track: { event in
            TelemetryDeck.signal(event.signalName, parameters: event.parameters)
        }
    )
}

extension DependencyValues {
    var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}
