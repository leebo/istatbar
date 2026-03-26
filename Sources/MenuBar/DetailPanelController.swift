import AppKit

class DetailPanelController: NSObject {
    private var panel: NSPanel!
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
        let panelHeight: CGFloat = 480

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .titled],
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
    }

    private func setupSections() {
        contentView = NSView(frame: panel.contentView!.bounds)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor(hex: "#1e1e1e").cgColor
        panel.contentView = contentView

        let scrollView = NSScrollView(frame: contentView.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.backgroundColor = NSColor(hex: "#1e1e1e")
        contentView.addSubview(scrollView)

        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = containerView

        cpuSection = SectionView(title: "CPU", icon: "cpu")
        memorySection = SectionView(title: "Memory", icon: "memorychip")
        diskSection = SectionView(title: "Disk", icon: "internaldrive")
        networkSection = SectionView(title: "Network", icon: "network")
        systemInfoSection = SectionView(title: "System", icon: "desktopcomputer")

        [cpuSection, memorySection, diskSection, networkSection, systemInfoSection].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 320),

            cpuSection.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            cpuSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            cpuSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            memorySection.topAnchor.constraint(equalTo: cpuSection.bottomAnchor, constant: 8),
            memorySection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            memorySection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            diskSection.topAnchor.constraint(equalTo: memorySection.bottomAnchor, constant: 8),
            diskSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            diskSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            networkSection.topAnchor.constraint(equalTo: diskSection.bottomAnchor, constant: 8),
            networkSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            networkSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            systemInfoSection.topAnchor.constraint(equalTo: networkSection.bottomAnchor, constant: 8),
            systemInfoSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            systemInfoSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            systemInfoSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }

    func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        updateSections()
        panel.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)

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

        cpuSection.setPrimaryValue("\(stats.cpuUsage)%")
        cpuSection.setSubtitle("All Cores")

        let memPercent = stats.memoryPercent
        memorySection.setPrimaryValue("\(stats.memoryUsedShort)")
        memorySection.setSubtitle("Used: \(String(format: "%.1f", memPercent))%")

        diskSection.setPrimaryValue("\(stats.diskUsed)/\(stats.diskTotal)")
        diskSection.setSubtitle("Capacity")

        networkSection.setPrimaryValue("↓ \(stats.networkDown)  ↑ \(stats.networkUp)")
        networkSection.setSubtitle("Speed")

        systemInfoSection.setPrimaryValue(stats.uptime)
        systemInfoSection.setSubtitle(stats.hostname)
    }
}

class SectionView: NSView {
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
