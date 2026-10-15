public struct HotKey: Equatable, Sendable {
    public struct Modifiers: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let control = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let shift = Modifiers(rawValue: 1 << 2)
        public static let command = Modifiers(rawValue: 1 << 3)
    }

    public let keyCode: UInt32
    public let keyLabel: String
    public let modifiers: Modifiers

    public init(keyCode: UInt32, keyLabel: String, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.keyLabel = keyLabel
        self.modifiers = modifiers
    }

    // cfn: fixed hotkey, make configurable if users ask
    public static let toggle = HotKey(keyCode: 4, keyLabel: "H", modifiers: [.control, .option, .command])

    /// Carbon modifier mask (cmdKey 256, shiftKey 512, optionKey 2048, controlKey 4096).
    public var carbonModifiers: UInt32 {
        var mask: UInt32 = 0
        if modifiers.contains(.command) { mask |= 256 }
        if modifiers.contains(.shift) { mask |= 512 }
        if modifiers.contains(.option) { mask |= 2048 }
        if modifiers.contains(.control) { mask |= 4096 }
        return mask
    }

    /// Mac-style glyph string, e.g. "⌃⌥⌘H".
    public var displayString: String {
        var s = ""
        if modifiers.contains(.control) { s += "⌃" }
        if modifiers.contains(.option) { s += "⌥" }
        if modifiers.contains(.shift) { s += "⇧" }
        if modifiers.contains(.command) { s += "⌘" }
        return s + keyLabel
    }
}
