import AppKit

final class GeneralPreferencesViewController: NSViewController {

    // MARK: - Controls

    private lazy var idleTimeoutSlider: NSSlider = {
        let slider = NSSlider(value: Double(Settings.idleTimeoutMinutes),
                              minValue: 1, maxValue: 30, target: self,
                              action: #selector(idleTimeoutChanged(_:)))
        slider.isContinuous = true
        slider.tickMarkPosition = .below
        slider.numberOfTickMarks = 30
        return slider
    }()

    private lazy var idleTimeoutLabel: NSTextField = {
        let label = NSTextField(labelWithString: "\(Settings.idleTimeoutMinutes) min")
        label.alignment = .right
        label.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return label
    }()

    private lazy var idleActionPopup: NSPopUpButton = {
        let popup = NSPopUpButton()
        popup.addItems(withTitles: ["Pause timer", "Reset timer"])
        popup.selectItem(at: Settings.idleAction == "reset" ? 1 : 0)
        popup.target = self
        popup.action = #selector(idleActionChanged(_:))
        return popup
    }()

    private lazy var meetingDetectionCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: "Meeting detection",
                                target: self,
                                action: #selector(toggleChanged(_:)))
        checkbox.state = Settings.meetingDetectionEnabled ? .on : .off
        return checkbox
    }()

    private lazy var focusModeCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: "Focus mode",
                                target: self,
                                action: #selector(toggleChanged(_:)))
        checkbox.state = Settings.focusModeEnabled ? .on : .off
        return checkbox
    }()

    private lazy var inputDeferCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: "Allow deferring breaks",
                                target: self,
                                action: #selector(toggleChanged(_:)))
        checkbox.state = Settings.inputDeferEnabled ? .on : .off
        return checkbox
    }()

    private lazy var maxDeferSlider: NSSlider = {
        let slider = NSSlider(value: Double(Settings.maxDeferMinutes),
                              minValue: 1, maxValue: 10, target: self,
                              action: #selector(maxDeferChanged(_:)))
        slider.isContinuous = true
        slider.tickMarkPosition = .below
        slider.numberOfTickMarks = 10
        return slider
    }()

    private lazy var maxDeferLabel: NSTextField = {
        let label = NSTextField(labelWithString: "\(Settings.maxDeferMinutes) min")
        label.alignment = .right
        label.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        return label
    }()

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 520))
        self.view = containerView
        layoutSections()
    }

    // MARK: - Layout

    private func layoutSections() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(makeIdleSection())
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(makeMeetingSection())
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(makeFocusModeSection())
        stack.addArrangedSubview(makeSeparator())
        stack.addArrangedSubview(makeInputDeferSection())

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Idle Section

    private func makeIdleSection() -> NSView {
        let section = NSStackView()
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 8

        section.addArrangedSubview(makeSectionHeader("Idle Detection"))

        let sliderRow = NSStackView()
        sliderRow.orientation = .horizontal
        sliderRow.spacing = 8
        sliderRow.alignment = .centerY

        let timeoutLabel = NSTextField(labelWithString: "Idle timeout:")
        idleTimeoutSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        sliderRow.addArrangedSubview(timeoutLabel)
        sliderRow.addArrangedSubview(idleTimeoutSlider)
        sliderRow.addArrangedSubview(idleTimeoutLabel)

        section.addArrangedSubview(sliderRow)

        let actionRow = NSStackView()
        actionRow.orientation = .horizontal
        actionRow.spacing = 8
        actionRow.alignment = .centerY

        let actionLabel = NSTextField(labelWithString: "When idle:")
        actionRow.addArrangedSubview(actionLabel)
        actionRow.addArrangedSubview(idleActionPopup)

        section.addArrangedSubview(actionRow)

        return section
    }

    // MARK: - Meeting Section

    private func makeMeetingSection() -> NSView {
        let section = NSStackView()
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 4

        section.addArrangedSubview(meetingDetectionCheckbox)
        section.addArrangedSubview(makeInfoLabel(
            "Detects when meeting apps (Zoom, Teams, FaceTime) are active"
        ))

        return section
    }

    // MARK: - Focus Mode Section

    private func makeFocusModeSection() -> NSView {
        let section = NSStackView()
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 4

        section.addArrangedSubview(focusModeCheckbox)
        section.addArrangedSubview(makeInfoLabel(
            "Pause timer when macOS Focus mode is active"
        ))

        return section
    }

    // MARK: - Input Defer Section

    private func makeInputDeferSection() -> NSView {
        let section = NSStackView()
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 8

        section.addArrangedSubview(inputDeferCheckbox)
        section.addArrangedSubview(makeInfoLabel(
            "Allow postponing a break by pressing a modifier key"
        ))

        let sliderRow = NSStackView()
        sliderRow.orientation = .horizontal
        sliderRow.spacing = 8
        sliderRow.alignment = .centerY

        let deferLabel = NSTextField(labelWithString: "Max defer time:")
        maxDeferSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        sliderRow.addArrangedSubview(deferLabel)
        sliderRow.addArrangedSubview(maxDeferSlider)
        sliderRow.addArrangedSubview(maxDeferLabel)

        section.addArrangedSubview(sliderRow)

        return section
    }

    // MARK: - Helpers

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        return label
    }

    private func makeInfoLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.textColor = .secondaryLabelColor
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        return label
    }

    private func makeSeparator() -> NSView {
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        return separator
    }

    // MARK: - Actions

    @objc private func idleTimeoutChanged(_ sender: NSSlider) {
        let value = sender.integerValue
        idleTimeoutLabel.stringValue = "\(value) min"
        Settings.idleTimeoutMinutes = value
    }

    @objc private func idleActionChanged(_ sender: NSPopUpButton) {
        Settings.idleAction = sender.indexOfSelectedItem == 1 ? "reset" : "pause"
    }

    @objc private func toggleChanged(_ sender: NSButton) {
        let isOn = sender.state == .on
        switch sender {
        case meetingDetectionCheckbox:
            Settings.meetingDetectionEnabled = isOn
        case focusModeCheckbox:
            Settings.focusModeEnabled = isOn
        case inputDeferCheckbox:
            Settings.inputDeferEnabled = isOn
        default:
            break
        }
    }

    @objc private func maxDeferChanged(_ sender: NSSlider) {
        let value = sender.integerValue
        maxDeferLabel.stringValue = "\(value) min"
        Settings.maxDeferMinutes = value
    }
}
