import AppKit

final class StatsPreferencesViewController: NSViewController {

    // MARK: - Controls

    private let complianceLabel = NSTextField(labelWithString: "0%")
    private let complianceCaptionLabel = NSTextField(labelWithString: "Today's Compliance")
    private let currentStreakLabel = NSTextField(labelWithString: "Current Streak: 0 days")
    private let bestStreakLabel = NSTextField(labelWithString: "Best: 0 days")
    private let breakdownLabel = NSTextField(labelWithString: "")
    private let heatmapView = HeatmapView()

    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("StatsPreferencesViewController does not support NSCoder")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 420, height: 340))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        updateStats()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateStats()
    }

    // MARK: - Layout

    private func setupLayout() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        complianceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 42, weight: .bold)
        complianceLabel.textColor = .textColor
        complianceCaptionLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        complianceCaptionLabel.textColor = .secondaryLabelColor

        let complianceSection = NSStackView()
        complianceSection.orientation = .vertical
        complianceSection.alignment = .centerX
        complianceSection.spacing = 2
        complianceSection.addArrangedSubview(complianceLabel)
        complianceSection.addArrangedSubview(complianceCaptionLabel)

        currentStreakLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        bestStreakLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        bestStreakLabel.textColor = .secondaryLabelColor

        let streakSection = NSStackView()
        streakSection.orientation = .horizontal
        streakSection.spacing = 16
        streakSection.alignment = .centerY
        streakSection.addArrangedSubview(currentStreakLabel)
        streakSection.addArrangedSubview(bestStreakLabel)

        breakdownLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        breakdownLabel.textColor = .secondaryLabelColor

        let heatmapHeader = NSTextField(labelWithString: "Last 12 Weeks")
        heatmapHeader.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        heatmapHeader.textColor = .tertiaryLabelColor

        let heatmapSection = NSStackView()
        heatmapSection.orientation = .vertical
        heatmapSection.alignment = .leading
        heatmapSection.spacing = 4
        heatmapSection.addArrangedSubview(heatmapHeader)
        heatmapSection.addArrangedSubview(heatmapView)

        stack.addArrangedSubview(complianceSection)
        stack.addArrangedSubview(streakSection)
        stack.addArrangedSubview(breakdownLabel)
        stack.addArrangedSubview(heatmapSection)

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            complianceSection.centerXAnchor.constraint(equalTo: stack.centerXAnchor),
        ])
    }

    // MARK: - Data

    private func updateStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayRecord = BreakHistory.shared.getDayRecord(today)
        let rate = todayRecord?.complianceRate ?? 0
        complianceLabel.stringValue = String(format: "%.0f%%", rate)

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let stats = BreakHistory.shared.getStats(from: thirtyDaysAgo, to: today)

        currentStreakLabel.stringValue = "Current Streak: \(stats.currentStreak) day\(stats.currentStreak == 1 ? "" : "s")"
        bestStreakLabel.stringValue = "Best: \(stats.bestStreak) day\(stats.bestStreak == 1 ? "" : "s")"

        let deferredCount = countDeferred(from: thirtyDaysAgo, to: today)
        breakdownLabel.stringValue = "Taken: \(stats.totalBreaksTaken) · Skipped: \(stats.totalBreaksSkipped) · Deferred: \(deferredCount)"

        heatmapView.reloadData()
    }

    private func countDeferred(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        var count = 0

        while current <= end {
            if let record = BreakHistory.shared.getDayRecord(current) {
                count += record.breaks.filter { $0.wasDeferred && !$0.wasSkipped }.count
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return count
    }
}
