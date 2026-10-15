import Carbon.HIToolbox
import CursorHaloCore

/// Global hotkey via Carbon RegisterEventHotKey. Needs no Accessibility or Input Monitoring permission.
@MainActor
final class HotKeyRegistration {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: @MainActor () -> Void

    init?(_ hotKey: HotKey, action: @escaping @MainActor () -> Void) {
        self.action = action

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let reg = Unmanaged<HotKeyRegistration>.fromOpaque(userData).takeUnretainedValue()
                // Carbon delivers application-target events on the main thread.
                MainActor.assumeIsolated { reg.action() }
                return noErr
            },
            1, &spec, userData, &handlerRef
        )
        guard status == noErr else { return nil }

        let id = EventHotKeyID(signature: OSType(0x4348_414C), id: 1) // 'CHAL'
        let reg = RegisterEventHotKey(
            hotKey.keyCode, hotKey.carbonModifiers, id,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        guard reg == noErr else { return nil }
    }

    isolated deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
