import AppKit

extension NSColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var statusBarView: StatusBarView!
    private var detailPanel: DetailPanelWindowController!
    private var timer: Timer?
    private let systemMonitor = SystemMonitor()

    override init() {
        super.init()
        detailPanel = DetailPanelWindowController()
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let view = StatusBarView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
            statusBarView = view
            button.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: 200),
                view.heightAnchor.constraint(equalTo: button.heightAnchor),
                view.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])

            button.target = self
            button.action = #selector(togglePanel)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        updateStatusBar()
        startTimer()
    }

    @objc private func togglePanel() {
        if detailPanel.isShown {
            detailPanel.hidePanel()
        } else {
            guard let button = statusItem.button else { return }
            let rect = button.bounds
            detailPanel.showPanel(relativeTo: rect, of: button, preferredEdge: .minY)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStatusBar()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStatusBar() {
        let stats = systemMonitor.getStats()
        statusBarView?.update(
            cpu: "\(Int(stats.cpuUsage))%",
            memory: stats.memoryUsedShort,
            network: "↓\(stats.networkDown)"
        )
    }
}
