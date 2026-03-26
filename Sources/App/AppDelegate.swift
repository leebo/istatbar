import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "iStatBar"
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }

        statusItem.menu = menuBarController.menu
        menuBarController.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        menuBarController.stopMonitoring()
    }
}
