import AppKit
import CursorHaloCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore(backing: UserDefaults.standard)
    private var settings = Settings()
    private let overlay = OverlayController()
    private var menu: MenuController?
    private var hotKey: HotKeyRegistration?
    private var monitors: [Any] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings = store.load()
        overlay.apply(settings)

        menu = MenuController(
            settings: settings,
            onChange: { [weak self] in self?.update($0) }
        )

        hotKey = HotKeyRegistration(HotKey.toggle) { [weak self] in
            guard let self else { return }
            var s = self.settings
            s.toggleMaster()
            self.update(s)
        }

        installMouseMonitors()
        overlay.moveHighlight(to: NSEvent.mouseLocation)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.overlay.rebuild() }
        }
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
