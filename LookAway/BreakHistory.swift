import Foundation

struct BreakRecord: Codable {
    let timestamp: Date
    let scheduledTime: Date
    let wasSkipped: Bool
    let wasDeferred: Bool
}

struct DayRecord: Codable {
    let date: String  // "2026-05-21"
    var breaks: [BreakRecord]

    var complianceRate: Double {
        guard !breaks.isEmpty else { return 0 }
        let taken = breaks.filter { !$0.wasSkipped }.count
        return Double(taken) / Double(breaks.count) * 100
    }
}

struct ComplianceStats: Codable {
    var complianceRate: Double
    var currentStreak: Int
    var bestStreak: Int
    var totalBreaksTaken: Int
    var totalBreaksSkipped: Int
}

final class BreakHistory {
    static let shared = BreakHistory()

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private var historyDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("LookAway/history", isDirectory: true)
    }

    func recordBreak(scheduledTime: Date, wasSkipped: Bool, wasDeferred: Bool = false) {
        let record = BreakRecord(
            timestamp: Date(),
            scheduledTime: scheduledTime,
            wasSkipped: wasSkipped,
            wasDeferred: wasDeferred
        )
        let dateStr = formatDate(scheduledTime)
        var dayRecord = loadDayRecord(dateStr) ?? DayRecord(date: dateStr, breaks: [])
        dayRecord.breaks.append(record)
        saveDayRecord(dayRecord)
    }

    func getDayRecord(_ date: Date) -> DayRecord? {
        loadDayRecord(formatDate(date))
    }

    func getStats(from: Date, to: Date) -> ComplianceStats {
        var allRecords: [DayRecord] = []
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)

        while current <= end {
            if let record = loadDayRecord(formatDate(current)) {
                allRecords.append(record)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        let taken = allRecords.reduce(0) { $0 + $1.breaks.filter { !$0.wasSkipped }.count }
        let total = allRecords.reduce(0) { $0 + $1.breaks.count }
        let skipped = total - taken

        return ComplianceStats(
            complianceRate: total > 0 ? Double(taken) / Double(total) * 100 : 0,
            currentStreak: calculateCurrentStreak(),
            bestStreak: calculateBestStreak(),
            totalBreaksTaken: taken,
            totalBreaksSkipped: skipped
        )
    }

    // MARK: - Private

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func fileForMonth(_ yearMonth: String) -> URL {
        return historyDirectory.appendingPathComponent("\(yearMonth).json")
    }

    private func loadDayRecord(_ dateStr: String) -> DayRecord? {
        let month = String(dateStr.prefix(7)) // "2026-05"
        let url = fileForMonth(month)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let records = try? decoder.decode([DayRecord].self, from: data) else { return nil }
        return records.first { $0.date == dateStr }
    }

    private func saveDayRecord(_ record: DayRecord) {
        let month = String(record.date.prefix(7))
        let url = fileForMonth(month)

        try? fileManager.createDirectory(at: historyDirectory, withIntermediateDirectories: true)

        var records: [DayRecord] = (try? Data(contentsOf: url)).flatMap { try? decoder.decode([DayRecord].self, from: $0) } ?? []
        if let idx = records.firstIndex(where: { $0.date == record.date }) {
            records[idx] = record
        } else {
            records.append(record)
        }

        if let data = try? encoder.encode(records) {
            try? data.write(to: url)
        }
    }

    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var current = calendar.startOfDay(for: Date())
        var streak = 0

        while true {
            if let record = loadDayRecord(formatDate(current)) {
                if record.complianceRate >= 80 {
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return streak
    }

    private func calculateBestStreak() -> Int {
        guard let files = try? fileManager.contentsOfDirectory(at: historyDirectory, includingPropertiesForKeys: nil) else { return 0 }
        let jsonFiles = files.filter { $0.pathExtension == "json" }.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })

        var allRecords: [DayRecord] = []
        for file in jsonFiles {
            if let data = try? Data(contentsOf: file),
               let records = try? decoder.decode([DayRecord].self, from: data) {
                allRecords.append(contentsOf: records)
            }
        }
        allRecords.sort { $0.date < $1.date }

        var bestStreak = 0
        var currentStreak = 0
        for record in allRecords {
            if record.complianceRate >= 80 {
                currentStreak += 1
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return bestStreak
    }
}
