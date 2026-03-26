import AppKit

class StatusBarView: NSView {
    private var cpuLabel: NSTextField!
    private var memLabel: NSTextField!
    private var netLabel: NSTextField!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        cpuLabel = createLabel(fontSize: 11)
        memLabel = createLabel(fontSize: 11)
        netLabel = createLabel(fontSize: 11)

        let stack = NSStackView(views: [cpuLabel, memLabel, netLabel])
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4)
        ])
    }

    private func createLabel(fontSize: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: "--")
        label.font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .medium)
        label.textColor = .labelColor
        label.backgroundColor = .clear
        label.isBezeled = false
        label.isEditable = false
        return label
    }

    func update(cpu: String, memory: String, network: String) {
        cpuLabel.stringValue = cpu
        memLabel.stringValue = memory
        netLabel.stringValue = network
    }
}
