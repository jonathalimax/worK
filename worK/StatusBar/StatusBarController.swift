import AppKit
import Observation
import SwiftUI

// MARK: - StatusBarController

@MainActor
final class StatusBarController {
	// MARK: - Properties

	private let statusItem: NSStatusItem
	private let popover: NSPopover
	let viewModel: WorkDayViewModel
	private var observationTask: Task<Void, Never>?
	private var eventMonitor: Any?

	// MARK: - Initialization

	init() {
		viewModel = WorkDayViewModel()

		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		popover = NSPopover()
		popover.contentSize = NSSize(
			width: AppConstants.popoverWidth,
			height: AppConstants.popoverHeight
		)
		popover.behavior = .transient
		popover.animates = true

		let contentView = PopoverContentView(viewModel: viewModel)
		popover.contentViewController = NSHostingController(rootView: contentView)

		configureButton()
		startObserving()
		viewModel.start()
	}

	// MARK: - Cleanup

	func tearDown() {
		observationTask?.cancel()
		observationTask = nil
		if let monitor = eventMonitor {
			NSEvent.removeMonitor(monitor)
			eventMonitor = nil
		}
	}

	// MARK: - Configuration

	private func configureButton() {
		guard let button = statusItem.button else { return }
		button.title = AppConstants.appName
		button.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
		button.target = self
		button.action = #selector(togglePopover)

		// Add global event monitor to close popover on outside clicks
		eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
			guard let self, self.popover.isShown else { return }
			self.popover.performClose(nil)
		}
	}

	// MARK: - Observation

	private func startObserving() {
		observationTask = Task { @MainActor [weak self] in
			guard let self else { return }
			while !Task.isCancelled {
				withObservationTracking {
					self.updateButton(
						text: self.viewModel.statusBarText,
						color: self.viewModel.statusBarColor
					)
				} onChange: {
					// Will be called when observed properties change
				}
				try? await Task.sleep(for: .milliseconds(100))
			}
		}
	}

	private func updateButton(text: String, color: StatusBarColor) {
		guard let button = statusItem.button else { return }

		// Map status bar color to text color and optional tint
		// For .gray (idle), use systemGray text with no tint for visibility
		let (textColor, tintColor): (NSColor, NSColor?) = switch color {
		case .green:
			(.white, .systemGreen)
		case .yellow:
			(.white, .systemYellow)
		case .red:
			(.white, .systemRed)
		case .gray:
			(.systemGray, nil)  // Gray text, no background tint
		}

		let attributes: [NSAttributedString.Key: Any] = [
			.foregroundColor: textColor,
			.font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
		]
		let attributedTitle = NSAttributedString(string: " \(text) ", attributes: attributes)
		button.attributedTitle = attributedTitle
		button.contentTintColor = tintColor
	}

	// MARK: - Actions

	@objc private func togglePopover() {
		if popover.isShown {
			popover.performClose(nil)
		} else {
			guard let button = statusItem.button else { return }
			popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

			// Ensure the popover content refreshes
			Task { @MainActor [weak self] in
				await self?.viewModel.refreshStats()
			}
		}
	}
}
