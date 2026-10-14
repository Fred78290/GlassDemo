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
            }
        )

        // Host the SwiftUI view inside an AppKit window.
        let hostingController = NSHostingController(rootView: rootView)
        // Only a minimum size: the default .standardBounds constraints fight a resizable window and
        // can loop until AppKit raises "needing another Update Constraints in Window pass".
        hostingController.sizingOptions = [.minSize]

        window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.title = "Glass Demo"
        window.setContentSize(NSSize(width: 560, height: 340))
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
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
            keyEquivalent: "q")
        appItem.submenu = appMenu

        NSApp.mainMenu = mainMenu
    }
}
