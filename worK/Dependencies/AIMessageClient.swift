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

					switch type {
					case .motivational:
						let tones = ["encouraging", "humorous", "philosophical", "energetic", "calm"]
						let tone = tones.randomElement() ?? "encouraging"
						prompt = """
							Generate a short motivational message (max 2 sentences) about productivity \
							and work-life balance. Use a \(tone) tone. Do not use hashtags or emojis. \
							Be genuine and specific, not generic.
							"""
					case .registrationReminder:
						prompt = """
							Generate a short, encouraging reminder message (max 2 sentences) to register \
							completed work hours in an external system. The tone should be friendly and \
							congratulatory about completing the daily work goal, while gently reminding \
							them to log their hours. Do not use hashtags or emojis.
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
		"Small consistent efforts compound into remarkable achievements over time.",
		"Your focus today builds the foundation for tomorrow's success.",
		"Take a moment to appreciate how far you've come this week.",
		"Progress, not perfection, is what drives meaningful change.",
		"The best work happens when you balance intensity with rest.",
		"Every hour of focused work is an investment in your future self.",
		"Remember: sustainable pace beats burnout every single time.",
		"Your dedication today is writing the story of your career.",
		"Deep work requires deep rest. Honor both equally.",
		"The most productive people know when to stop and recharge.",
		"Your attention is your most valuable resource. Spend it wisely.",
		"Great ideas need space to breathe. Take breaks without guilt.",
		"Consistency over intensity. Show up every day and the results follow.",
		"You are building something meaningful, one focused session at a time.",
		"The quality of your rest determines the quality of your work.",
		"Trust the process. Each day adds another layer to your expertise.",
		"Working smart means knowing when to push and when to pause.",
		"Your future self will thank you for the boundaries you set today.",
		"Excellence is a habit, not an act. Keep showing up.",
		"The rhythm of work and rest creates the music of achievement."
	]

	private static let reminderMessages: [String] = [
		"Great work today! Don't forget to register your completed hours in your time tracking system.",
		"You've hit your daily goal! Remember to log these hours in your external system before signing off.",
		"Excellent job reaching your target! Time to register your work hours for the day.",
		"Daily target achieved! Make sure to record your completed hours in your tracking system.",
		"Well done on completing your work goal! Don't forget to update your time logs.",
		"Target hours reached! Remember to register today's work in your external tracking system.",
		"Success! You've completed your daily hours. Time to log them in your system.",
		"Fantastic work today! Please remember to register your hours externally.",
		"You've met your daily goal! Don't forget to document your hours in the tracking system.",
		"Great day of work! Make sure to register your completed hours before you finish."
	]
}

extension DependencyValues {
	var aiMessageClient: AIMessageClient {
		get { self[AIMessageClient.self] }
		set { self[AIMessageClient.self] = newValue }
	}
}
