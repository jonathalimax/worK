import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct ScreenLockClient: Sendable {
    var lockScreen: @Sendable () async throws -> Void
}

extension ScreenLockClient: DependencyKey {
    static let liveValue = ScreenLockClient(
        lockScreen: {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = [
                "-e",
                "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
            ]

            try task.run()
            task.waitUntilExit()

            guard task.terminationStatus == 0 else {
                throw ScreenLockError.lockFailed
            }
        }
    )

    static let testValue = ScreenLockClient(lockScreen: {})
    static let previewValue = ScreenLockClient(lockScreen: {})
}

enum ScreenLockError: Error {
    case lockFailed
}

extension DependencyValues {
    var screenLockClient: ScreenLockClient {
        get { self[ScreenLockClient.self] }
        set { self[ScreenLockClient.self] = newValue }
    }
}
