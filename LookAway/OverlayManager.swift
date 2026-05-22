import Cocoa

protocol OverlayManagerDelegate: AnyObject {
    func onSkipRequested()
}

final class OverlayManager {
    weak var delegate: OverlayManagerDelegate?
    private var overlayWindows: [NSWindow] = []
    private var windowScreenFrames: [NSWindow: NSRect] = [:]
    private var lastScreenChangeTime: Date = .distantPast
    private var screenChangeWorkItem: DispatchWorkItem?

    func showOverlay() {
        closeOverlay()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = NSColor.black.withAlphaComponent(0.9)
            window.ignoresMouseEvents = false
            window.hidesOnDeactivate = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let containerView = OverlayView(frame: screen.frame)
            containerView.skipTarget = self
            containerView.skipAction = #selector(handleSkip)
            window.contentView = containerView

            overlayWindows.append(window)
            windowScreenFrames[window] = screen.frame
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        NSApp.presentationOptions.insert(.autoHideDock)
        NSApp.presentationOptions.insert(.autoHideMenuBar)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func closeOverlay() {
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
        windowScreenFrames.removeAll()
        screenChangeWorkItem?.cancel()
        screenChangeWorkItem = nil

        NSApp.presentationOptions.remove(.autoHideDock)
        NSApp.presentationOptions.remove(.autoHideMenuBar)

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleSkip() {
        delegate?.onSkipRequested()
    }

    // MARK: - Screen Change Handling

    @objc private func screensChanged() {
        guard !overlayWindows.isEmpty else { return }

        let now = Date()
        let throttleInterval: TimeInterval = 0.5
        guard now.timeIntervalSince(lastScreenChangeTime) > throttleInterval else {
            screenChangeWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.applyScreenChanges()
            }
            screenChangeWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + throttleInterval, execute: item)
            return
        }

        lastScreenChangeTime = now
        applyScreenChanges()
    }

    private func applyScreenChanges() {
        guard !overlayWindows.isEmpty else { return }

        let currentScreenFrames = Set(NSScreen.screens.map { $0.frame })

        let goneWindows = overlayWindows.filter { window in
            guard let frame = windowScreenFrames[window] else { return true }
            return !currentScreenFrames.contains(frame)
        }
        for window in goneWindows {
            window.close()
            overlayWindows.removeAll { $0 === window }
            windowScreenFrames.removeValue(forKey: window)
        }

        let coveredFrames = Set(windowScreenFrames.values)
        for screen in NSScreen.screens where !coveredFrames.contains(screen.frame) {
            addWindowForScreen(screen)
        }

        if !overlayWindows.isEmpty {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func addWindowForScreen(_ screen: NSScreen) {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.9)
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let containerView = OverlayView(frame: screen.frame)
        containerView.skipTarget = self
        containerView.skipAction = #selector(handleSkip)
        window.contentView = containerView

        overlayWindows.append(window)
        windowScreenFrames[window] = screen.frame
        window.makeKeyAndOrderFront(nil)
    }
}

private class OverlayView: NSView {
    var skipTarget: AnyObject? {
        didSet { skipButton?.target = skipTarget }
    }
    var skipAction: Selector? {
        didSet { skipButton?.action = skipAction }
    }

    private var titleLabel: NSTextField!
    private var skipButton: NSButton!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    private func setupSubviews() {
        titleLabel = NSTextField(labelWithString: "Look Away")
        titleLabel.font = NSFont.systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.sizeToFit()
        addSubview(titleLabel)

        skipButton = NSButton(frame: .zero)
        skipButton.title = "Skip"
        skipButton.bezelStyle = .rounded
        skipButton.target = skipTarget
        skipButton.action = skipAction
        skipButton.sizeToFit()
        addSubview(skipButton)
    }

    override func layout() {
        super.layout()
        let centerX = bounds.midX
        let centerY = bounds.midY

        titleLabel.frame = NSRect(
            x: centerX - titleLabel.frame.width / 2,
            y: centerY + 40,
            width: titleLabel.frame.width,
            height: titleLabel.frame.height
        )
        skipButton.frame = NSRect(
            x: centerX - skipButton.frame.width / 2,
            y: centerY - 20,
            width: skipButton.frame.width,
            height: skipButton.frame.height
        )
    }
}
