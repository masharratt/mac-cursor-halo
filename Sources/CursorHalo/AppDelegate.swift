import AppKit
import CursorHaloCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore(backing: UserDefaults.standard)
    private var settings = Settings()
    private let overlay = OverlayController()
    private var menu: MenuController?
    private var hotKey: HotKeyRegistration?
    private var recorder: ShortcutRecorderWindow?
    private var monitors: [Any] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings = store.load()
        overlay.apply(settings)

        menu = MenuController(
            settings: settings,
            onChange: { [weak self] in self?.update($0) },
            onChangeShortcut: { [weak self] in self?.beginRecordingShortcut() },
            onResetShortcut: { [weak self] in self?.resetShortcut() }
        )

        _ = registerHotKey(settings.toggleHotKey)

        installMouseMonitors()
        overlay.moveHighlight(to: NSEvent.mouseLocation)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.overlay.rebuild() }
        }
    }

    /// Replaces the registered Carbon hotkey. Returns false if the system refused (combo owned elsewhere).
    private func registerHotKey(_ key: HotKey) -> Bool {
        hotKey = nil // unregisters the previous one first
        hotKey = HotKeyRegistration(key) { [weak self] in
            guard let self else { return }
            var s = self.settings
            s.toggleHighlight()
            self.update(s)
        }
        return hotKey != nil
    }

    private func beginRecordingShortcut() {
        guard recorder == nil else { recorder?.show(); return }
        hotKey = nil // free the current combo so it can be captured again
        let window = ShortcutRecorderWindow(
            onCandidate: { [weak self] candidate in
                guard let self else { return nil }
                guard self.registerHotKey(candidate) else {
                    return "\(candidate.displayString) is already used by another app. Try a different shortcut."
                }
                var s = self.settings
                s.toggleHotKey = candidate
                self.update(s)
                return nil
            },
            onFinish: { [weak self] in
                guard let self else { return }
                self.recorder = nil
                // Cancelled or failed: make sure the saved shortcut is live again.
                if self.hotKey == nil { _ = self.registerHotKey(self.settings.toggleHotKey) }
            }
        )
        recorder = window
        window.show()
    }

    private func resetShortcut() {
        guard registerHotKey(HotKey.toggle) else {
            _ = registerHotKey(settings.toggleHotKey)
            let alert = NSAlert()
            alert.messageText = "Could not reset the shortcut"
            alert.informativeText = "\(HotKey.toggle.displayString) is already used by another app."
            alert.runModal()
            return
        }
        var s = settings
        s.toggleHotKey = HotKey.toggle
        update(s)
    }

    private func update(_ new: Settings) {
        settings = new
        store.save(new)
        overlay.apply(new)
        menu?.refresh(new)
    }

    private func installMouseMonitors() {
        let moveMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        let clickMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown]

        // Global monitors see events sent to other apps; local ones see events sent to this app.
        if let m = NSEvent.addGlobalMonitorForEvents(matching: moveMask, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.overlay.moveHighlight(to: NSEvent.mouseLocation) }
        }) { monitors.append(m) }

        if let m = NSEvent.addGlobalMonitorForEvents(matching: clickMask, handler: { [weak self] event in
            let isRight = event.type == .rightMouseDown
            MainActor.assumeIsolated { self?.overlay.ripple(at: NSEvent.mouseLocation, rightClick: isRight) }
        }) { monitors.append(m) }

        if let m = NSEvent.addLocalMonitorForEvents(matching: moveMask, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.overlay.moveHighlight(to: NSEvent.mouseLocation) }
            return event
        }) { monitors.append(m) }

        if let m = NSEvent.addLocalMonitorForEvents(matching: clickMask, handler: { [weak self] event in
            let isRight = event.type == .rightMouseDown
            MainActor.assumeIsolated { self?.overlay.ripple(at: NSEvent.mouseLocation, rightClick: isRight) }
            return event
        }) { monitors.append(m) }
    }
}
