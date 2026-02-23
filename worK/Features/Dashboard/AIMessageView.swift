import Dependencies
import SwiftUI

// MARK: - AIMessageView

struct AIMessageView: View {
	let messageType: MessageType
	@State private var message: String = ""
	@State private var isLoading = true

	init(messageType: MessageType = .motivational) {
		self.messageType = messageType
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(spacing: 6) {
				ZStack {
					RoundedRectangle(cornerRadius: 6)
						.fill(Color.purple.opacity(0.15))
						.frame(width: 26, height: 26)
					Image(systemName: "sparkles")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(.purple)
				}

				Text(headerText)
					.font(.system(size: 11, weight: .medium))
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
					.tracking(0.3)

				Spacer()

				Button {
					Task { await loadMessage() }
				} label: {
					Image(systemName: "arrow.clockwise")
						.font(.system(size: 11, weight: .semibold))
						.foregroundStyle(.secondary)
						.frame(width: 24, height: 24)
						.background(Color.white.opacity(0.05))
						.clipShape(Circle())
				}
				.buttonStyle(.plain)
			}

			if isLoading {
				HStack(spacing: 8) {
					ProgressView()
						.controlSize(.small)
					Text(String(localized: "Generating..."))
						.font(.system(size: 13, weight: .regular))
						.foregroundStyle(.secondary)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			} else {
				Text(message)
					.font(.system(size: 14, weight: .regular))
					.foregroundStyle(.primary)
					.lineSpacing(2)
					.lineLimit(3)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(14)
		.background {
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(.ultraThinMaterial)
				.opacity(0.4)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(Color(white: 0.08).opacity(0.2))
				)
				.overlay {
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.strokeBorder(
							LinearGradient(
								colors: [
									Color.white.opacity(0.15),
									Color.white.opacity(0.05)
								],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							),
							lineWidth: 1.5
						)
				}
		}
		.shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
		.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
		.task {
			await loadMessage()
		}
	}

	// MARK: - Private Helpers

	private var headerText: String {
		switch messageType {
		case .motivational:
			String(localized: "Daily Motivation")
		case .registrationReminder:
			String(localized: "Registration Reminder")
		}
	}

	private func loadMessage() async {
		isLoading = true
		@Dependency(\.aiMessageClient) var aiMessageClient
		message = await aiMessageClient.generateMessage(messageType)
		isLoading = false
	}
}

#Preview {
	AIMessageView()
		.frame(width: 350)
		.padding()
}
