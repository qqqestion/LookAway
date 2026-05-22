import AppKit

final class PreferencesWindowController: NSWindowController {

    // MARK: - Singleton

    static let shared = PreferencesWindowController()

    // MARK: - Properties

    private let tabView = NSTabView()

    // MARK: - Initialization

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.title = "LookAway Preferences"
        window.minSize = NSSize(width: 480, height: 520)
        window.maxSize = NSSize(width: 480, height: 520)
        super.init(window: window)
        setupTabs()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PreferencesWindowController does not support NSCoder")
    }

    // MARK: - Tab Setup

    private func setupTabs() {
        let timerTab = NSTabViewItem(identifier: "Timer")
        timerTab.label = "Timer"
        timerTab.viewController = TimerPreferencesViewController()

        let appsTab = NSTabViewItem(identifier: "Apps")
        appsTab.label = "Apps"
        appsTab.viewController = AppsPreferencesViewController()

        let generalTab = NSTabViewItem(identifier: "General")
        generalTab.label = "General"
        generalTab.viewController = GeneralPreferencesViewController()

        let statsTab = NSTabViewItem(identifier: "Stats")
        statsTab.label = "Stats"
        statsTab.viewController = StatsPreferencesViewController()

        tabView.addTabViewItem(timerTab)
        tabView.addTabViewItem(appsTab)
        tabView.addTabViewItem(generalTab)
        tabView.addTabViewItem(statsTab)
        tabView.translatesAutoresizingMaskIntoConstraints = false

        guard let contentView = window?.contentView else { return }
        contentView.addSubview(tabView)

        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    // MARK: - Public

    func showPreferences(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(sender)
        window?.center()
    }
}
