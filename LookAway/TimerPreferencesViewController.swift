import AppKit

final class TimerPreferencesViewController: NSViewController {

    // MARK: - Controls

    private lazy var breakIntervalSlider: NSSlider = makeSlider(
        minValue: 5, maxValue: 60,
        currentValue: Settings.breakIntervalMinutes,
        action: #selector(breakIntervalChanged(_:))
    )

    private lazy var breakIntervalLabel: NSTextField = makeValueLabel(
        text: formatMinutes(Settings.breakIntervalMinutes)
    )

    private lazy var breakDurationSlider: NSSlider = makeSlider(
        minValue: 5, maxValue: 120,
        currentValue: Settings.breakDurationSeconds,
        action: #selector(breakDurationChanged(_:))
    )

    private lazy var breakDurationLabel: NSTextField = makeValueLabel(
        text: formatSeconds(Settings.breakDurationSeconds)
    )

    private lazy var warningAdvanceSlider: NSSlider = makeSlider(
        minValue: 5, maxValue: 60,
        currentValue: Settings.warningAdvanceSeconds,
        action: #selector(warningAdvanceChanged(_:))
    )

    private lazy var warningAdvanceLabel: NSTextField = makeValueLabel(
        text: formatSeconds(Settings.warningAdvanceSeconds)
    )

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("TimerPreferencesViewController does not support NSCoder")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 260))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    // MARK: - Layout

    private func setupLayout() {
        let rows: [(String, NSSlider, NSTextField)] = [
            ("Break interval:", breakIntervalSlider, breakIntervalLabel),
            ("Break duration:", breakDurationSlider, breakDurationLabel),
            ("Warning before break:", warningAdvanceSlider, warningAdvanceLabel),
        ]

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false

        for (title, slider, valueLabel) in rows {
            let titleLabel = makeTitleLabel(text: title)

            let sliderRow = NSStackView()
            sliderRow.orientation = .horizontal
            sliderRow.alignment = .centerY
            sliderRow.spacing = 8

            sliderRow.addArrangedSubview(slider)
            sliderRow.addArrangedSubview(valueLabel)

            let row = NSStackView()
            row.orientation = .vertical
            row.alignment = .leading
            row.spacing = 4
            row.addArrangedSubview(titleLabel)
            row.addArrangedSubview(sliderRow)

            stackView.addArrangedSubview(row)
        }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            breakIntervalSlider.widthAnchor.constraint(equalToConstant: 260),
            breakDurationSlider.widthAnchor.constraint(equalToConstant: 260),
            warningAdvanceSlider.widthAnchor.constraint(equalToConstant: 260),
        ])
    }

    // MARK: - Actions

    @objc private func breakIntervalChanged(_ sender: NSSlider) {
        Settings.breakIntervalMinutes = sender.integerValue
        breakIntervalLabel.stringValue = formatMinutes(sender.integerValue)
    }

    @objc private func breakDurationChanged(_ sender: NSSlider) {
        Settings.breakDurationSeconds = sender.integerValue
        breakDurationLabel.stringValue = formatSeconds(sender.integerValue)
    }

    @objc private func warningAdvanceChanged(_ sender: NSSlider) {
        Settings.warningAdvanceSeconds = sender.integerValue
        warningAdvanceLabel.stringValue = formatSeconds(sender.integerValue)
    }

    // MARK: - Factory Helpers

    private func makeSlider(minValue: Int, maxValue: Int, currentValue: Int, action: Selector) -> NSSlider {
        let slider = NSSlider(value: Double(currentValue), minValue: Double(minValue), maxValue: Double(maxValue), target: self, action: action)
        slider.isContinuous = true
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }

    private func makeTitleLabel(text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func makeValueLabel(text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        label.alignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        label.widthAnchor.constraint(equalToConstant: 80).isActive = true
        return label
    }

    // MARK: - Formatting

    private func formatMinutes(_ value: Int) -> String {
        value == 1 ? "1 minute" : "\(value) minutes"
    }

    private func formatSeconds(_ value: Int) -> String {
        value == 1 ? "1 second" : "\(value) seconds"
    }
}
