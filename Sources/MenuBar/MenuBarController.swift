import Foundation
import AppKit

class MenuBarController {
    private var menu: NSMenu!
    private var cpuItem: NSMenuItem!
    private var memoryItem: NSMenuItem!
    private var diskItem: NSMenuItem!
    private var networkItem: NSMenuItem!
    private var timer: Timer?
    private let systemMonitor = SystemMonitor()

    init() {
        buildMenu()
    }

    private func buildMenu() {
        menu = NSMenu()
        menu.autoenablesItems = false

        cpuItem = NSMenuItem(title: "CPU: --%", action: nil, keyEquivalent: "")
        memoryItem = NSMenuItem(title: "Memory: --%", action: nil, keyEquivalent: "")
        diskItem = NSMenuItem(title: "Disk: --%", action: nil, keyEquivalent: "")
        networkItem = NSMenuItem(title: "Network: --", action: nil, keyEquivalent: "")

        [cpuItem, memoryItem, diskItem, networkItem].forEach { menu.addItem($0) }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit iStatBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    func startMonitoring() {
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        let stats = systemMonitor.getStats()

        cpuItem.title = "CPU: \(stats.cpuUsage)%"
        memoryItem.title = "Memory: \(stats.memoryUsed) / \(stats.memoryTotal)"

        if let diskUsed = stats.diskUsed, let diskTotal = stats.diskTotal {
            diskItem.title = "Disk: \(diskUsed) / \(diskTotal)"
        }

        networkItem.title = "Network: \(stats.networkDown)↓ \(stats.networkUp)↑"

        let button = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength).button
        button?.title = "\(stats.cpuUsage)% | \(stats.memoryShort)"
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
