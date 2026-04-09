import AppKit
import Dependencies
import Observation
import SwiftUI

// MARK: - PopoverState

@Observable
@MainActor
final class PopoverState {
	var selectedTab: PopoverTab = .dashboard
}

// MARK: - StatusBarController

@MainActor
final class StatusBarController {
	// MARK: - Properties

	@ObservationIgnored @Dependency(\.analyticsClient) private var analytics
	private var panelSource: PopoverSource = .leftClick

	private let statusItem: NSStatusItem
	private var panel: NSPanel?
	let viewModel: WorkDayViewModel
	private let popoverState = PopoverState()
	private var observationTask: Task<Void, Never>?
	private var eventMonitor: Any?

	var isPanelShown: Bool { panel != nil }

	// MARK: - Initialization

	init() {
		viewModel = WorkDayViewModel()
		statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

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
		dismissPanel()
	}

	// MARK: - Configuration

	private func configureButton() {
		guard let button = statusItem.button else { return }
		button.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
		button.target = self
		button.action = #selector(handleButtonClick)
		button.sendAction(on: [.leftMouseUp, .rightMouseUp])

		// Dismiss panel on outside clicks
		eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
			guard let self, self.isPanelShown else { return }
			self.dismissPanel()
		}
	}

	private func makeContextMenu() -> NSMenu {
		let menu = NSMenu()

		let todayItem = NSMenuItem(title: String(localized: "Today Summary"), action: #selector(openToday), keyEquivalent: "")
		todayItem.target = self
		menu.addItem(todayItem)

		let historyItem = NSMenuItem(title: String(localized: "History"), action: #selector(openHistory), keyEquivalent: "")
		historyItem.target = self
		menu.addItem(historyItem)

		let settingsItem = NSMenuItem(title: String(localized: "Settings"), action: #selector(openSettings), keyEquivalent: ",")
		settingsItem.target = self
		menu.addItem(settingsItem)

		menu.addItem(.separator())

		let quitItem = NSMenuItem(title: String(localized: "Quit worK"), action: #selector(openQuit), keyEquivalent: "q")
		quitItem.target = self
		menu.addItem(quitItem)

		return menu
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

		let tintColor: NSColor? = switch color {
		case .green: .systemGreen
		case .yellow: .systemYellow
		case .red: .systemRed
		case .gray: nil
		}

		// Use labelColor so the text adapts automatically to light/dark menu bars
		// and inverts correctly when the item is highlighted.
		let attributes: [NSAttributedString.Key: Any] = [
			.foregroundColor: NSColor.labelColor,
			.font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)
		]
		let attributedTitle = NSAttributedString(string: " \(text) ", attributes: attributes)
		button.attributedTitle = attributedTitle
		button.contentTintColor = tintColor
	}

	// MARK: - Panel

	private func showPanel() {
		guard let button = statusItem.button,
		      let buttonWindow = button.window else { return }

		let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: AppConstants.popoverWidth, height: AppConstants.popoverHeight),
			styleMask: [.borderless, .nonactivatingPanel],
			backing: .buffered,
			defer: false
		)

		panel.isFloatingPanel = true
		panel.level = .popUpMenu
		panel.backgroundColor = .clear
		panel.isOpaque = false
		panel.hasShadow = true
		panel.appearance = NSAppearance(named: .darkAqua)
		panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

		let contentView = PopoverContentView(viewModel: viewModel, popoverState: popoverState)
		let hostingView = NSHostingView(rootView: contentView)
		hostingView.wantsLayer = true
		hostingView.layer?.backgroundColor = NSColor.clear.cgColor
		panel.contentView = hostingView

		// Position below the status bar button
		let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
		let originX = buttonFrame.midX - AppConstants.popoverWidth / 2
		let originY = buttonFrame.minY - AppConstants.popoverHeight - 4
		panel.setFrameOrigin(NSPoint(x: originX, y: originY))

		panel.alphaValue = 0
		panel.orderFront(nil)

		NSAnimationContext.runAnimationGroup { context in
			context.duration = 0.2
			context.timingFunction = CAMediaTimingFunction(name: .easeOut)
			panel.animator().alphaValue = 1
		}

		self.panel = panel

		analytics.track(.popoverOpened(source: panelSource))

		Task { @MainActor [weak self] in
			await self?.viewModel.refreshStats()
		}
	}

	private func dismissPanel() {
		guard let panel else { return }

		analytics.track(.popoverClosed)

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.15
			context.timingFunction = CAMediaTimingFunction(name: .easeIn)
			panel.animator().alphaValue = 0
		}, completionHandler: { [weak self] in
			MainActor.assumeIsolated {
				panel.orderOut(nil)
				self?.panel = nil
			}
		})
	}

	// MARK: - Actions

	@objc private func openToday() {
		analytics.track(.menuTodayTapped)
		panelSource = .menu
		popoverState.selectedTab = .dashboard
		if !isPanelShown { showPanel() }
	}

	@objc private func openHistory() {
		analytics.track(.menuHistoryTapped)
		panelSource = .menu
		popoverState.selectedTab = .history
		if !isPanelShown { showPanel() }
	}

	@objc private func openSettings() {
		analytics.track(.menuSettingsTapped)
		panelSource = .menu
		popoverState.selectedTab = .settings
		if !isPanelShown { showPanel() }
	}

	@objc private func openQuit() {
		analytics.track(.menuQuitTapped)
		NSApp.terminate(nil)
	}

	@objc private func handleButtonClick() {
		guard let event = NSApp.currentEvent else { return }
		if event.type == .rightMouseUp {
			showContextMenu()
		} else {
			togglePopover()
		}
	}

	private func showContextMenu() {
		dismissPanel()
		statusItem.menu = makeContextMenu()
		statusItem.button?.performClick(nil)
		statusItem.menu = nil
	}

	private func togglePopover() {
		if isPanelShown {
			dismissPanel()
		} else {
			panelSource = .leftClick
			showPanel()
		}
	}
}
