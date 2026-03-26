import AppKit

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var statusBarView: StatusBarView!
    private var detailPanel: DetailPanelController!
    private var timer: Timer?
    private let systemMonitor = SystemMonitor()

    override init() {
        super.init()
        detailPanel = DetailPanelController()
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
        if let panel = (detailPanel as? DetailPanelController)?.panel, panel.isVisible {
            detailPanel.hide()
        } else {
            guard let button = statusItem.button else { return }
            let rect = button.bounds
            detailPanel.show(relativeTo: rect, of: button, preferredEdge: .minY)
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

class DetailPanelController: NSObject {
    var panel: NSPanel!
    private var contentView: NSView!
    private var cpuSection: SectionView!
    private var memorySection: SectionView!
    private var diskSection: SectionView!
    private var networkSection: SectionView!
    private var systemInfoSection: SectionView!
    private let systemMonitor = SystemMonitor()
    private var updateTimer: Timer?

    override init() {
        super.init()
        setupPanel()
        setupSections()
    }

    private func setupPanel() {
        let panelWidth: CGFloat = 320
        let panelHeight: CGFloat = 420

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor(hex: "#1e1e1e")
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
    }

    private func setupSections() {
        contentView = NSView(frame: panel.contentView!.bounds)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(hex: "#1e1e1e").cgColor
        panel.contentView = contentView

        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.edgeInsets = NSEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        contentView.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        cpuSection = SectionView(title: "CPU", icon: "cpu")
        memorySection = SectionView(title: "Memory", icon: "memorychip")
        diskSection = SectionView(title: "Disk", icon: "internaldrive")
        networkSection = SectionView(title: "Network", icon: "network")
        systemInfoSection = SectionView(title: "System", icon: "desktopcomputer")

        [cpuSection, memorySection, diskSection, networkSection, systemInfoSection].forEach { mainStack.addArrangedSubview($0) }
    }

    func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        updateSections()
        panel.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)

        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSections()
        }
    }

    func hide() {
        updateTimer?.invalidate()
        updateTimer = nil
        panel.orderOut(nil)
    }

    private func updateSections() {
        let stats = systemMonitor.getStats()

        cpuSection.setPrimaryValue("\(Int(stats.cpuUsage))%")
        cpuSection.setSubtitle("All Cores Active")

        memorySection.setPrimaryValue(stats.memoryUsedShort)
        memorySection.setSubtitle("\(String(format: "%.1f", stats.memoryPercent))% of \(stats.memoryTotal)")

        diskSection.setPrimaryValue(stats.diskUsed)
        diskSection.setSubtitle("of \(stats.diskTotal)")

        networkSection.setPrimaryValue("↓ \(stats.networkDown)")
        networkSection.setSubtitle("↑ \(stats.networkUp)")

        systemInfoSection.setPrimaryValue(stats.uptime)
        systemInfoSection.setSubtitle(stats.hostname)
    }
}
