import Lottie
import SwiftUI

// MARK: - LottieView

struct LottieView: NSViewRepresentable {
	let animationName: String
	let loopMode: LottieLoopMode
	let contentMode: LottieContentMode
	let animationSpeed: CGFloat

	init(
		animationName: String,
		loopMode: LottieLoopMode = .loop,
		contentMode: LottieContentMode = .scaleAspectFit,
		animationSpeed: CGFloat = 1.0
	) {
		self.animationName = animationName
		self.loopMode = loopMode
		self.contentMode = contentMode
		self.animationSpeed = animationSpeed
	}

	func makeNSView(context: Context) -> LottieAnimationView {
		let animationView = LottieAnimationView()
		animationView.contentMode = contentMode
		animationView.loopMode = loopMode
		animationView.animationSpeed = animationSpeed
		animationView.backgroundBehavior = .pauseAndRestore

		// Load animation from bundle - use named resource for proper macOS loading
		if let animation = LottieAnimation.named(animationName, subdirectory: "Animations") {
			animationView.animation = animation
			animationView.play()
		} else {
			print("⚠️ Failed to load Lottie animation: \(animationName)")
		}

		return animationView
	}

	func updateNSView(_ nsView: LottieAnimationView, context: Context) {
		// Update animation if needed - only reload if animation is nil
		if nsView.animation == nil,
		   let animation = LottieAnimation.named(animationName, subdirectory: "Animations") {
			nsView.animation = animation
			nsView.play()
		}
	}
}

// MARK: - Preview

#Preview {
	VStack(spacing: 20) {
		LottieView(animationName: "coffee-break")
			.frame(width: 100, height: 100)

		LottieView(animationName: "success")
			.frame(width: 100, height: 100)

		LottieView(animationName: "clock-idle")
			.frame(width: 100, height: 100)
	}
	.padding()
}
