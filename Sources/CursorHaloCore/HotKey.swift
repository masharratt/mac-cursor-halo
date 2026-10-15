import Foundation

public struct HotKey: Equatable, Codable, Sendable {
    public struct Modifiers: OptionSet, Codable, Sendable {
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

    /// Factory default; the user can replace it via Settings.toggleHotKey.
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

public enum ShortcutValidation: Equatable, Sendable {
    case accepted
    case rejected(String)
}

extension HotKey {
    /// Virtual key codes for F1 through F20, in order.
    private static let fKeyCodes: [UInt32] = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79, 80, 90]

    private static let namedKeys: [UInt32: String] = [
        49: "Space", 36: "↩", 76: "⌅", 48: "⇥", 51: "⌫", 117: "⌦",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "Home", 119: "End", 116: "Page Up", 121: "Page Down",
    ]

    public static func fKeyName(keyCode: UInt32) -> String? {
        fKeyCodes.firstIndex(of: keyCode).map { "F\($0 + 1)" }
    }

    /// Display label for a captured key: F-key name, named key, uppercased character, or a key-code fallback.
    public static func label(keyCode: UInt32, characters: String?) -> String {
        if let f = fKeyName(keyCode: keyCode) { return f }
        if let n = namedKeys[keyCode] { return n }
        let trimmed = (characters ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.unicodeScalars.first, first.value >= 0x20, !(0xF700...0xF8FF).contains(first.value) {
            return trimmed.uppercased()
        }
        return "Key \(keyCode)"
    }

    /// Accepts combos with Command, Control or Option, or any F1-F20 key. Bare keys would hijack normal typing.
    public static func validate(keyCode: UInt32, modifiers: Modifiers) -> ShortcutValidation {
        if fKeyName(keyCode: keyCode) != nil { return .accepted }
        if !modifiers.isDisjoint(with: [.command, .control, .option]) { return .accepted }
        return .rejected("Include ⌘, ⌃ or ⌥, or use an F1 to F20 key.")
    }
}

public enum RecorderOutcome: Equatable, Sendable {
    case cancelled
    case rejected(String)
    case candidate(HotKey)
}

/// Pure interpretation of one key press while the shortcut recorder is open.
public enum ShortcutRecorder {
    public static let escapeKeyCode: UInt32 = 53

    public static func interpret(keyCode: UInt32, modifiers: HotKey.Modifiers, characters: String?) -> RecorderOutcome {
        if keyCode == escapeKeyCode { return .cancelled }
        switch HotKey.validate(keyCode: keyCode, modifiers: modifiers) {
        case .rejected(let message):
            return .rejected(message)
        case .accepted:
            let label = HotKey.label(keyCode: keyCode, characters: characters)
            return .candidate(HotKey(keyCode: keyCode, keyLabel: label, modifiers: modifiers))
        }
    }
}
