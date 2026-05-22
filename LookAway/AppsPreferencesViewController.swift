import AppKit

final class AppsPreferencesViewController: NSViewController {

    // MARK: - Constants

    /// Mirrors AppPauseDetector.basePauseBundleIDs.
    /// Not imported directly to avoid coupling to detector internals.
    private static let basePauseBundleIDs: Set<String> = [
        "com.valvesoftware.steam",
        "org.videolan.vlc",
        "com.apple.iWork.Keynote",
        "com.microsoft.Powerpoint",
        "com.apple.QuickTimePlayer",
        "com.apple.tv",
        "com.spotify.client"
    ]

    private static let disabledPauseAppsKey = "disabledPauseApps"

    // MARK: - App Row View

    private final class AppRowView: NSStackView {
        let bundleID: String
        let isBasePreset: Bool

        init(bundleID: String, isBasePreset: Bool) {
            self.bundleID = bundleID
            self.isBasePreset = isBasePreset
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) is not supported")
        }
    }

    // MARK: - Properties

    private let scrollView = NSScrollView()
    private let contentStackView = NSStackView()
    private let addButton = NSButton(title: "Add Application\u{2026}", target: nil, action: nil)

    private var disabledPauseApps: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: Self.disabledPauseAppsKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Self.disabledPauseAppsKey)
            NotificationCenter.default.post(name: Settings.didChangeNotification, object: nil)
        }
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        rebuildRows()
    }

    // MARK: - UI Setup

    private func setupUI() {
        contentStackView.orientation = .vertical
        contentStackView.alignment = .leading
        contentStackView.spacing = 2
        contentStackView.edgeInsets = NSEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

        scrollView.hasVerticalScroller = true
        scrollView.documentView = contentStackView
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addButton.bezelStyle = .rounded
        addButton.target = self
        addButton.action = #selector(addApplicationClicked)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        view.addSubview(addButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -8),

            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),

            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - Row Building

    private func rebuildRows() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        contentStackView.addArrangedSubview(makeSectionHeader("Built-in Pause Apps"))

        for bundleID in Self.basePauseBundleIDs.sorted() {
            let row = makeAppRow(
                bundleID: bundleID,
                isBasePreset: true,
                isEnabled: !disabledPauseApps.contains(bundleID)
            )
            contentStackView.addArrangedSubview(row)
        }

        let userApps = Settings.pausedApps
        if !userApps.isEmpty {
            contentStackView.addArrangedSubview(makeSpacer(12))
            contentStackView.addArrangedSubview(makeSectionHeader("Custom Apps"))

            for bundleID in userApps {
                let row = makeAppRow(
                    bundleID: bundleID,
                    isBasePreset: false,
                    isEnabled: !disabledPauseApps.contains(bundleID)
                )
                contentStackView.addArrangedSubview(row)
            }
        }
    }

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func makeSpacer(_ height: CGFloat) -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacer
    }

    private func makeAppRow(bundleID: String, isBasePreset: Bool, isEnabled: Bool) -> AppRowView {
        let row = AppRowView(bundleID: bundleID, isBasePreset: isBasePreset)
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY
        row.edgeInsets = NSEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)

        let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
        let icon: NSImage
        let appName: String

        if let url = appURL {
            icon = NSWorkspace.shared.icon(forFile: url.path)
            appName = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent
        } else {
            icon = NSWorkspace.shared.icon(forFileType: "app")
            appName = bundleID
        }

        let toggle = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleChanged(_:)))
        toggle.state = isEnabled ? .on : .off

        let iconView = NSImageView()
        iconView.image = icon
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let nameField = NSTextField(labelWithString: appName)
        nameField.font = NSFont.systemFont(ofSize: 13)
        nameField.lineBreakMode = .byTruncatingTail
        nameField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        row.addArrangedSubview(toggle)
        row.addArrangedSubview(iconView)
        row.addArrangedSubview(nameField)

        if !isBasePreset {
            let deleteButton = NSButton(title: "", target: self, action: #selector(deleteClicked(_:)))
            deleteButton.bezelStyle = .inline
            deleteButton.isBordered = false
            deleteButton.image = NSImage(systemSymbolName: "xmark.circle",
                                         accessibilityDescription: "Remove")
            deleteButton.contentTintColor = .tertiaryLabelColor
            row.addArrangedSubview(deleteButton)
        }

        return row
    }

    // MARK: - Actions

    @objc private func toggleChanged(_ sender: NSButton) {
        guard let row = sender.superview as? AppRowView else { return }

        var disabled = disabledPauseApps
        if sender.state == .on {
            disabled.remove(row.bundleID)
        } else {
            disabled.insert(row.bundleID)
        }
        disabledPauseApps = disabled
    }

    @objc private func deleteClicked(_ sender: NSButton) {
        guard let row = sender.superview as? AppRowView else { return }

        var apps = Settings.pausedApps
        apps.removeAll { $0 == row.bundleID }
        Settings.pausedApps = apps

        var disabled = disabledPauseApps
        disabled.remove(row.bundleID)
        disabledPauseApps = disabled

        rebuildRows()
    }

    @objc private func addApplicationClicked(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = ["app"]
        panel.directoryURL = FileManager.default.urls(
            for: .applicationDirectory,
            in: .localDomainMask
        ).first

        guard panel.runModal() == .OK else { return }

        var apps = Settings.pausedApps
        for url in panel.urls {
            guard let bundleID = Bundle(url: url)?.bundleIdentifier else { continue }
            if !Self.basePauseBundleIDs.contains(bundleID) && !apps.contains(bundleID) {
                apps.append(bundleID)
            }
        }
        Settings.pausedApps = apps
        rebuildRows()
    }
}
