import Dependencies
import DependenciesMacros
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AIMessageClient

enum MessageType: Sendable {
	case motivational
	case registrationReminder
}

@DependencyClient
struct AIMessageClient: Sendable {
	/// Generates a message based on type. Falls back to static pool on failure.
	var generateMessage: @Sendable (MessageType) async -> String = { type in
		Self.randomFallbackMessage(for: type)
	}
}

// MARK: - Live Implementation

extension AIMessageClient: DependencyKey {
	static let liveValue = AIMessageClient(
		generateMessage: { type in
			// FoundationModels (Apple Intelligence) is only available on macOS 26+.
			// When available, use it for AI-generated messages; otherwise fall back
			// to a curated static pool.
			#if canImport(FoundationModels)
			if #available(macOS 26, *) {
				do {
					let session = LanguageModelSession()
					let prompt: String
                    let languageName = Locale.current.localizedString(forLanguageCode: Locale.current.languageCode ?? "en") ?? "English"

					switch type {
					case .motivational:
						let tones = ["encouraging", "humorous", "philosophical", "energetic", "calm"]
						let tone = tones.randomElement() ?? "encouraging"
						prompt = """
							Generate a short motivational message (max 2 sentences) about productivity \
							and work-life balance. Use a \(tone) tone. Do not use hashtags or emojis. \
							Be genuine and specific, not generic.
							The message must be in \(languageName).
							"""
					case .registrationReminder:
						prompt = """
							Generate a short, encouraging reminder message (max 2 sentences) to register \
							completed work hours in an external system. The tone should be friendly and \
							congratulatory about completing the daily work goal, while gently reminding \
							them to log their hours. Do not use hashtags or emojis.
							The message must be in \(languageName).
							"""
					}

					let response = try await session.respond(to: prompt)
					let text = String(describing: response).trimmingCharacters(in: .whitespacesAndNewlines)
					if !text.isEmpty {
						return text
					}
				} catch {
					// Fall through to static pool
				}
			}
			#endif
			return randomFallbackMessage(for: type)
		}
	)

	static let testValue = AIMessageClient()
	static let previewValue = AIMessageClient(
		generateMessage: { type in
			switch type {
			case .motivational:
				"Stay focused, but remember to breathe. Great work happens in sustainable rhythms."
			case .registrationReminder:
				"Excellent work today! Don't forget to register your completed hours in your time tracking system."
			}
		}
	)
}

// MARK: - Fallback Messages

extension AIMessageClient {
	static func randomFallbackMessage(for type: MessageType) -> String {
		switch type {
		case .motivational:
			motivationalMessages.randomElement() ?? motivationalMessages[0]
		case .registrationReminder:
			reminderMessages.randomElement() ?? reminderMessages[0]
		}
	}

	private static let motivationalMessages: [String] = [
		String(localized: "Small consistent efforts compound into remarkable achievements over time."),
		String(localized: "Your focus today builds the foundation for tomorrow's success."),
		String(localized: "Take a moment to appreciate how far you've come this week."),
		String(localized: "Progress, not perfection, is what drives meaningful change."),
		String(localized: "The best work happens when you balance intensity with rest."),
		String(localized: "Every hour of focused work is an investment in your future self."),
		String(localized: "Remember: sustainable pace beats burnout every single time."),
		String(localized: "Your dedication today is writing the story of your career."),
		String(localized: "Deep work requires deep rest. Honor both equally."),
		String(localized: "The most productive people know when to stop and recharge."),
		String(localized: "Your attention is your most valuable resource. Spend it wisely."),
		String(localized: "Great ideas need space to breathe. Take breaks without guilt."),
		String(localized: "Consistency over intensity. Show up every day and the results follow."),
		String(localized: "You are building something meaningful, one focused session at a time."),
		String(localized: "The quality of your rest determines the quality of your work."),
		String(localized: "Trust the process. Each day adds another layer to your expertise."),
		String(localized: "Working smart means knowing when to push and when to pause."),
		String(localized: "Your future self will thank you for the boundaries you set today."),
		String(localized: "Excellence is a habit, not an act. Keep showing up."),
		String(localized: "The rhythm of work and rest creates the music of achievement.")
	]

	private static let reminderMessages: [String] = [
		String(localized: "Great work today! Don't forget to register your completed hours in your time tracking system."),
		String(localized: "You've hit your daily goal! Remember to log these hours in your external system before signing off."),
		String(localized: "Excellent job reaching your target! Time to register your work hours for the day."),
		String(localized: "Daily target achieved! Make sure to record your completed hours in your tracking system."),
		String(localized: "Well done on completing your work goal! Don't forget to update your time logs."),
		String(localized: "Target hours reached! Remember to register today's work in your external tracking system."),
		String(localized: "Success! You've completed your daily hours. Time to log them in your system."),
		String(localized: "Fantastic work today! Please remember to register your hours externally."),
		String(localized: "You've met your daily goal! Don't forget to document your hours in the tracking system."),
		String(localized: "Great day of work! Make sure to register your completed hours before you finish.")
	]
}

extension DependencyValues {
	var aiMessageClient: AIMessageClient {
		get { self[AIMessageClient.self] }
		set { self[AIMessageClient.self] = newValue }
	}
}
