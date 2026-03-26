import AppKit

class DetailPanelWindowController: NSObject {
    var isShown: Bool { panel.isVisible }

    private var panel: NSPanel!
    private var contentView: NSView!
    private var cpuSection: StatSectionView!
    private var memorySection: StatSectionView!
    private var diskSection: StatSectionView!
    private var networkSection: StatSectionView!
    private var systemInfoSection: StatSectionView!
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

        cpuSection = StatSectionView(title: "CPU", icon: "cpu")
        memorySection = StatSectionView(title: "Memory", icon: "memorychip")
        diskSection = StatSectionView(title: "Disk", icon: "internaldrive")
        networkSection = StatSectionView(title: "Network", icon: "network")
        systemInfoSection = StatSectionView(title: "System", icon: "desktopcomputer")

        [cpuSection, memorySection, diskSection, networkSection, systemInfoSection].forEach { mainStack.addArrangedSubview($0) }
    }

    func showPanel(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        updateSections()

        guard let buttonWindow = positioningView.window,
              let screen = buttonWindow.screen ?? NSScreen.main else {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let screenFrame = screen.visibleFrame
        let buttonFrameInScreen = buttonWindow.convertToScreen(positioningRect)

        // Calculate panel origin - below the status bar item
        var origin = CGPoint(
            x: buttonFrameInScreen.origin.x,
            y: buttonFrameInScreen.origin.y - panel.frame.height
        )

        // Ensure panel stays within screen bounds horizontally
        if origin.x + panel.frame.width > screenFrame.origin.x + screenFrame.width {
            origin.x = screenFrame.origin.x + screenFrame.width - panel.frame.width - 8
        }
        if origin.x < screenFrame.origin.x {
            origin.x = screenFrame.origin.x + 8
        }
        // Ensure panel doesn't go below screen
        if origin.y < screenFrame.origin.y {
            origin.y = screenFrame.origin.y
        }

        panel.setFrameOrigin(origin)
        panel.makeKeyAndOrderFront(nil)

        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSections()
        }
    }

    func hidePanel() {
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

class StatSectionView: NSView {
    private var titleLabel: NSTextField!
    private var primaryValueLabel: NSTextField!
    private var subtitleLabel: NSTextField!

    init(title: String, icon: String) {
        super.init(frame: .zero)
        setup(title: title, icon: icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(title: String, icon: String) {
        wantsLayer = true
        layer?.backgroundColor = NSColor(hex: "#2d2d2d").cgColor
        layer?.cornerRadius = 8

        titleLabel = createLabel(text: title.uppercased(), fontSize: 10, color: NSColor(hex: "#888888"))
        primaryValueLabel = createLabel(text: "--", fontSize: 22, color: .white)
        primaryValueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold)
        subtitleLabel = createLabel(text: "", fontSize: 11, color: NSColor(hex: "#666666"))

        let titleRow = NSStackView(views: [titleLabel])
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        let valueStack = NSStackView(views: [primaryValueLabel, subtitleLabel])
        valueStack.orientation = .vertical
        valueStack.alignment = .leading
        valueStack.spacing = 2
        valueStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleRow)
        addSubview(valueStack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            titleRow.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleRow.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            valueStack.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 8),
            valueStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            valueStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            valueStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    private func createLabel(text: String, fontSize: CGFloat, color: NSColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        label.textColor = color
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        return label
    }

    func setPrimaryValue(_ value: String) {
        primaryValueLabel.stringValue = value
    }

    func setSubtitle(_ value: String) {
        subtitleLabel.stringValue = value
    }
}
