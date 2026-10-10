import AppKit
import SwiftUI

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
	private var window: NSWindow!

	static func main() {
		let app = NSApplication.shared
		let delegate = AppDelegate()
		app.delegate = delegate
		app.setActivationPolicy(.regular)
		app.run()
	}

	func applicationDidFinishLaunching(_ notification: Notification) {
		buildMainMenu()

		// SwiftUI root view, with a callback back into AppKit.
		let rootView = ContentView(
			onAction: { [weak self] in
				self?.window.subtitle =
					"Last tap: \(Date.now.formatted(date: .omitted, time: .standard))"
			},
			onShowSheet: { [weak self] in
				self?.showSheet()
			}
		)

		// Host the SwiftUI view inside an AppKit window.
		let hostingController = NSHostingController(rootView: rootView)
		hostingController.sizingOptions = [.minSize]

		window = NSWindow(contentViewController: hostingController)
		window.styleMask = [
			.titled, .closable, .miniaturizable, .resizable,
			.fullSizeContentView,
		]
		window.titlebarAppearsTransparent = true
		window.title = "Glass Demo"
		window.setContentSize(NSSize(width: 560, height: 340))
		window.center()
		window.makeKeyAndOrderFront(nil)

		NSApp.activate()
	}

	/// Presents a SwiftUI view as a native AppKit sheet on the main window.
	private func showSheet() {
		guard let presenter = window.contentViewController,
			presenter.presentedViewControllers?.isEmpty ?? true
		else { return }

		let sheetController = NSHostingController(rootView: SheetView())
		sheetController.sizingOptions = [.preferredContentSize]

		// Wire the callbacks now that the controller exists, so the sheet can dismiss itself.
		sheetController.rootView = SheetView(
			onCancel: { [weak presenter, weak sheetController] in
				guard let presenter, let sheetController else { return }
				presenter.dismiss(sheetController)
			},
			onConfirm: {
				[weak self, weak presenter, weak sheetController] name, symbol
				in
				guard let presenter, let sheetController else { return }
				presenter.dismiss(sheetController)
				self?.window.subtitle = "Created “\(name)” (\(symbol))"
			}
		)

		presenter.presentAsSheet(sheetController)
	}

	func applicationShouldTerminateAfterLastWindowClosed(
		_ sender: NSApplication
	) -> Bool {
		true
	}

	private func buildMainMenu() {
		let mainMenu = NSMenu()
		let appItem = NSMenuItem()
		mainMenu.addItem(appItem)

		let appMenu = NSMenu()
		appMenu.addItem(
			withTitle: "Quit Glass Demo",
			action: #selector(NSApplication.terminate(_:)),
			keyEquivalent: "q"
		)
		appItem.submenu = appMenu

		NSApp.mainMenu = mainMenu
	}
}
