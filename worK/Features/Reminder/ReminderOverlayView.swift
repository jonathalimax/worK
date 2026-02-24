import SwiftUI

// MARK: - ReminderOverlayView

struct ReminderOverlayView: View {
	let workedTime: String
	let onDismiss: () -> Void
	let onTakeBreak: () -> Void

	@State private var opacity: Double = 0

	var body: some View {
		VStack(spacing: 16) {
			headerIcon
			messageSection
			actionButtons
		}
		.padding(24)
		.frame(width: 320)
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.shadow(color: .black.opacity(0.2), radius: 20, y: 10)
		.opacity(opacity)
		.onAppear {
			withAnimation(.easeOut(duration: 0.3)) {
				opacity = 1
			}
		}
	}

	// MARK: - Header

	private var headerIcon: some View {
		LottieView(
			animationName: "coffee-break",
			loopMode: .loop,
			animationSpeed: 1.2
		)
		.frame(width: 80, height: 80)
	}

	// MARK: - Message

	private var messageSection: some View {
		VStack(spacing: 6) {
			Text(String(localized: "Time for a Break"))
				.font(.title3.weight(.semibold))

			Text(String(localized: "You have been working for \(workedTime). A short break will help you stay productive.", comment: "Reminder message with worked time"))
				.font(.callout)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.lineLimit(3)
		}
	}

	// MARK: - Actions

	private var actionButtons: some View {
		HStack(spacing: 12) {
			Button(String(localized: "Dismiss")) {
				withAnimation(.easeIn(duration: 0.2)) {
					opacity = 0
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					onDismiss()
				}
			}
			.buttonStyle(.bordered)
			.controlSize(.regular)

			Button(String(localized: "Take a Break")) {
				withAnimation(.easeIn(duration: 0.2)) {
					opacity = 0
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					onTakeBreak()
				}
			}
			.buttonStyle(.borderedProminent)
			.tint(.orange)
			.controlSize(.regular)
		}
	}
}

#Preview {
	ReminderOverlayView(
		workedTime: "1h 30m",
		onDismiss: {},
		onTakeBreak: {}
	)
	.padding(40)
	.background(.gray.opacity(0.2))
}
