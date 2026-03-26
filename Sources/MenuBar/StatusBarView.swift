import AppKit

class StatusBarView: NSView {
    private var statusLabel: NSTextField!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        statusLabel = NSTextField(labelWithString: "--")
        statusLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        statusLabel.textColor = .labelColor
        statusLabel.backgroundColor = .clear
        statusLabel.isBezeled = false
        statusLabel.isEditable = false
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.maximumNumberOfLines = 1
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func update(cpu: String, memory: String, network: String) {
        statusLabel.stringValue = "\(cpu) | \(memory) | \(network)"
    }
}
