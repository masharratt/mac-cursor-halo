import AppKit
import CursorHaloCore

/// Small centered window that captures the next key press as the new toggle shortcut.
/// Uses a local key monitor, so it needs no permission.
@MainActor
final class ShortcutRecorderWindow: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let messageLabel = NSTextField(labelWithString: "")
    private var monitor: Any?
    private var finished = false

    /// Returns nil when the shortcut was saved, or an error message to show while recording continues.
    private let onCandidate: (HotKey) -> String?
    private let onFinish: () -> Void

    init(onCandidate: @escaping (HotKey) -> String?, onFinish: @escaping () -> Void) {
        self.onCandidate = onCandidate
        self.onFinish = onFinish
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 120),
            styleMask: [.titled, .closable], backing: .buffered, defer: false
        )
        super.init()

        window.title = "Change Shortcut"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self

        let prompt = NSTextField(wrappingLabelWithString: "Press the new shortcut, or your mouse button. Esc cancels.")
        prompt.alignment = .center
        messageLabel.textColor = .systemRed
        messageLabel.alignment = .center
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.maximumNumberOfLines = 2
        messageLabel.preferredMaxLayoutWidth = 300

        let stack = NSStackView(views: [prompt, messageLabel])
        stack.orientation = .vertical
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        window.contentView = stack
        window.setContentSize(NSSize(width: 340, height: 120))
    }

    func show() {
        window.center()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated { self?.handle(event) ?? false }
            return handled ? nil : event
        }
    }

    private func handle(_ event: NSEvent) -> Bool {
        guard window.isKeyWindow else { return false }
        if event.isARepeat { return true }
        let outcome = ShortcutRecorder.interpret(
            keyCode: UInt32(event.keyCode),
            modifiers: Self.modifiers(from: event.modifierFlags),
            characters: event.charactersIgnoringModifiers
        )
        switch outcome {
        case .cancelled:
            finish()
        case .rejected(let message):
            messageLabel.stringValue = message
        case .candidate(let hotKey):
            if let error = onCandidate(hotKey) {
                messageLabel.stringValue = error
            } else {
                finish()
            }
        }
        return true
    }

    private static func modifiers(from flags: NSEvent.ModifierFlags) -> HotKey.Modifiers {
        var m: HotKey.Modifiers = []
        if flags.contains(.control) { m.insert(.control) }
        if flags.contains(.option) { m.insert(.option) }
        if flags.contains(.shift) { m.insert(.shift) }
        if flags.contains(.command) { m.insert(.command) }
        return m
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        window.delegate = nil
        window.close()
        onFinish()
    }

    // Closing with the red button counts as cancel.
    func windowWillClose(_ notification: Notification) {
        finish()
    }
}
