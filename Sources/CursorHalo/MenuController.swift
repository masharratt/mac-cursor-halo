import AppKit
import CursorHaloCore
import ServiceManagement

@MainActor
final class MenuController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var settings: Settings
    private let onChange: (Settings) -> Void
    private let onChangeShortcut: () -> Void
    private let onResetShortcut: () -> Void

    private let highlightItem = NSMenuItem()
    private let rippleItem = NSMenuItem()
    private var sizeItems: [NSMenuItem] = []
    private var colorItems: [NSMenuItem] = []
    private let loginItem = NSMenuItem()
    private let changeShortcutItem = NSMenuItem()
    private let resetShortcutItem = NSMenuItem()

    private static var isBundled: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    init(
        settings: Settings,
        onChange: @escaping (Settings) -> Void,
        onChangeShortcut: @escaping () -> Void,
        onResetShortcut: @escaping () -> Void
    ) {
        self.settings = settings
        self.onChange = onChange
        self.onChangeShortcut = onChangeShortcut
        self.onResetShortcut = onResetShortcut
        super.init()
        build()
        refresh(settings)
    }

    private func build() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Cursor Halo")
        }

        highlightItem.target = self
        highlightItem.action = #selector(toggleHighlight)
        menu.addItem(highlightItem)

        rippleItem.title = "Click Ripple"
        rippleItem.target = self
        rippleItem.action = #selector(toggleRipple)
        menu.addItem(rippleItem)
        menu.addItem(.separator())

        let sizeMenu = NSMenu()
        for size in HaloSize.allCases {
            let item = NSMenuItem(title: "\(size.title) (\(Int(size.radius)))", action: #selector(pickSize(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = size.rawValue
            sizeMenu.addItem(item)
            sizeItems.append(item)
        }
        let sizeParent = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        sizeParent.submenu = sizeMenu
        menu.addItem(sizeParent)

        let colorMenu = NSMenu()
        for color in HaloColor.allCases {
            let item = NSMenuItem(title: color.title, action: #selector(pickColor(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color.rawValue
            colorMenu.addItem(item)
            colorItems.append(item)
        }
        let colorParent = NSMenuItem(title: "Color", action: nil, keyEquivalent: "")
        colorParent.submenu = colorMenu
        menu.addItem(colorParent)
        menu.addItem(.separator())

        changeShortcutItem.title = "Change Shortcut…"
        changeShortcutItem.target = self
        changeShortcutItem.action = #selector(changeShortcut)
        menu.addItem(changeShortcutItem)

        resetShortcutItem.target = self
        resetShortcutItem.action = #selector(resetShortcut)
        menu.addItem(resetShortcutItem)
        menu.addItem(.separator())

        loginItem.title = "Launch at Login"
        loginItem.target = self
        loginItem.action = #selector(toggleLogin)
        if !Self.isBundled {
            loginItem.isEnabled = false
            loginItem.toolTip = "Only available when running from the bundled CursorHalo.app"
        }
        menu.addItem(loginItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Cursor Halo", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    func refresh(_ new: Settings) {
        settings = new
        highlightItem.title = "Highlight Circle (\(new.toggleHotKey.displayString))"
        resetShortcutItem.title = "Reset Shortcut to \(HotKey.toggle.displayString)"
        resetShortcutItem.isEnabled = new.toggleHotKey != HotKey.toggle
        highlightItem.state = new.highlightEnabled ? .on : .off
        rippleItem.state = new.rippleEnabled ? .on : .off
        for item in sizeItems { item.state = (item.representedObject as? String) == new.size.rawValue ? .on : .off }
        for item in colorItems { item.state = (item.representedObject as? String) == new.color.rawValue ? .on : .off }
        loginItem.state = Self.isBundled && SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func change(_ edit: (inout Settings) -> Void) {
        var s = settings
        edit(&s)
        onChange(s)
    }

    @objc private func toggleHighlight() { change { $0.toggleHighlight() } }
    @objc private func toggleRipple() { change { $0.rippleEnabled.toggle() } }

    @objc private func pickSize(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let size = HaloSize(rawValue: raw) else { return }
        change { $0.size = size }
    }

    @objc private func pickColor(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let color = HaloColor(rawValue: raw) else { return }
        change { $0.color = color }
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        refresh(settings)
    }

    @objc private func changeShortcut() { onChangeShortcut() }
    @objc private func resetShortcut() { onResetShortcut() }

    @objc private func quit() { NSApp.terminate(nil) }
}
