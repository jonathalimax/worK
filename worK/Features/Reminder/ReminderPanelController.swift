import AppKit
import SwiftUI

// MARK: - ReminderPanelController

@MainActor
final class ReminderPanelController {
	// MARK: - Properties

	private var panel: NSPanel?
	private var autoDismissTask: Task<Void, Never>?

	// MARK: - Show

	func show(workedTime: String, onTakeBreak: @escaping () -> Void) {
		dismiss()

		let panel = NSPanel(
			contentRect: NSRect(x: 0, y: 0, width: 340, height: 280),
			styleMask: [.borderless, .nonactivatingPanel],
			backing: .buffered,
			defer: false
		)

		panel.isFloatingPanel = true
		panel.level = .floating
		panel.backgroundColor = .clear
		panel.isOpaque = false
		panel.hasShadow = false
		panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

		let contentView = ReminderOverlayView(
			workedTime: workedTime,
			onDismiss: { [weak self] in
				self?.dismiss()
			},
			onTakeBreak: { [weak self] in
				onTakeBreak()
				self?.dismiss()
			}
		)

		panel.contentView = NSHostingView(rootView: contentView)

		// Position at top-right of screen
		positionPanel(panel)

		// Animate in
		panel.alphaValue = 0
		panel.orderFront(nil)

		NSAnimationContext.runAnimationGroup { context in
			context.duration = 0.3
			context.timingFunction = CAMediaTimingFunction(name: .easeOut)
			panel.animator().alphaValue = 1
		}

		self.panel = panel

		// Auto-dismiss after 30 seconds
		autoDismissTask?.cancel()
		autoDismissTask = Task { @MainActor [weak self] in
			try? await Task.sleep(for: .seconds(AppConstants.reminderDismissInterval))
			guard !Task.isCancelled else { return }
			self?.dismiss()
		}
	}

	// MARK: - Dismiss

	func dismiss() {
		autoDismissTask?.cancel()
		autoDismissTask = nil

		guard let panel else { return }

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.2
			context.timingFunction = CAMediaTimingFunction(name: .easeIn)
			panel.animator().alphaValue = 0
		}, completionHandler: { [weak self] in
			panel.orderOut(nil)
			self?.panel = nil
		})
	}

	// MARK: - Private Helpers

	private func positionPanel(_ panel: NSPanel) {
		guard let screen = NSScreen.main else { return }
		let screenFrame = screen.visibleFrame
		let panelSize = panel.frame.size

		let originX = screenFrame.maxX - panelSize.width - 16
		let originY = screenFrame.maxY - panelSize.height - 16

		panel.setFrameOrigin(NSPoint(x: originX, y: originY))
	}
}
