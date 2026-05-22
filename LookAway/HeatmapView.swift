import AppKit

final class HeatmapView: NSView {

    // MARK: - Constants

    private let columns = 12
    private let rows = 7
    private let cellSize: CGFloat = 12
    private let cellSpacing: CGFloat = 2

    // MARK: - Data

    private var cellData: [[Double]] = []

    // MARK: - Colors

    private let emptyColor = NSColor(white: 0.16, alpha: 1.0)
    private let level1Color = NSColor(red: 0.18, green: 0.55, blue: 0.24, alpha: 1.0)
    private let level2Color = NSColor(red: 0.30, green: 0.68, blue: 0.28, alpha: 1.0)
    private let level3Color = NSColor(red: 0.47, green: 0.80, blue: 0.32, alpha: 1.0)
    private let level4Color = NSColor(red: 0.64, green: 0.90, blue: 0.40, alpha: 1.0)

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("HeatmapView does not support NSCoder")
    }

    private func commonInit() {
        let width = CGFloat(columns) * (cellSize + cellSpacing) - cellSpacing
        let height = CGFloat(rows) * (cellSize + cellSpacing) - cellSpacing
        frame.size = NSSize(width: width, height: height)
        wantsLayer = true
        loadHeatmapData()
    }

    // MARK: - Data Loading

    func reloadData() {
        loadHeatmapData()
        needsDisplay = true
    }

    private func loadHeatmapData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)

        // weekday: 1=Sun, 2=Mon,..., 7=Sat → row: (weekday + 5) % 7 gives Mon=0,...,Sun=6
        let daysSinceMonday = (weekday + 5) % 7
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else { return }
        guard let startMonday = calendar.date(byAdding: .weekOfYear, value: -(columns - 1), to: thisMonday) else { return }

        cellData = []
        var weekStart = startMonday

        for _ in 0..<columns {
            var weekColumn: [Double] = []
            for dayOffset in 0..<rows {
                guard let cellDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    weekColumn.append(-1)
                    continue
                }
                if cellDate > today {
                    weekColumn.append(-1)
                } else if let record = BreakHistory.shared.getDayRecord(cellDate) {
                    weekColumn.append(record.complianceRate)
                } else {
                    weekColumn.append(-1)
                }
            }
            cellData.append(weekColumn)
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = nextWeek
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current else { return }

        for col in 0..<cellData.count {
            for row in 0..<rows {
                let x = CGFloat(col) * (cellSize + cellSpacing)
                let y = CGFloat(row) * (cellSize + cellSpacing)
                let cellRect = NSRect(x: x, y: y, width: cellSize, height: cellSize)
                let path = NSBezierPath(roundedRect: cellRect, xRadius: 2, yRadius: 2)

                let compliance = cellData[col][row]
                colorForLevel(compliance).setFill()
                path.fill()
            }
        }
    }

    override var intrinsicContentSize: NSSize {
        let width = CGFloat(columns) * (cellSize + cellSpacing) - cellSpacing
        let height = CGFloat(rows) * (cellSize + cellSpacing) - cellSpacing
        return NSSize(width: width, height: height)
    }

    // MARK: - Color Mapping

    private func colorForLevel(_ compliance: Double) -> NSColor {
        guard compliance >= 0 else { return emptyColor }
        if compliance == 0 { return emptyColor }
        if compliance < 25 { return level1Color }
        if compliance < 50 { return level2Color }
        if compliance < 75 { return level3Color }
        return level4Color
    }
}
