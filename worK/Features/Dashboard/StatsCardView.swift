import SwiftUI

// MARK: - StatsCardView

struct StatsCardView: View {
	let title: String
	let value: String
	let icon: String
	let color: Color

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 6) {
				ZStack {
					RoundedRectangle(cornerRadius: 6)
						.fill(color.opacity(0.15))
						.frame(width: 26, height: 26)
					Image(systemName: icon)
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(color)
				}

				Text(title)
					.font(.system(size: 11, weight: .medium))
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
					.tracking(0.3)
			}

			Text(value)
				.font(.system(size: 22, weight: .semibold, design: .rounded))
				.foregroundStyle(.primary)
				.monospacedDigit()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
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
	}
}

#Preview {
	HStack {
		StatsCardView(
			title: "Worked",
			value: "6h 32m",
			icon: "clock.fill",
			color: .blue
		)
		StatsCardView(
			title: "Breaks",
			value: "3",
			icon: "cup.and.saucer.fill",
			color: .orange
		)
	}
	.padding()
}
