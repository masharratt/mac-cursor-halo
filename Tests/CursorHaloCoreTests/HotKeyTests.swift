import Testing
@testable import CursorHaloCore

@Suite struct HotKeyTests {
    @Test func toggleKeyCodeIsH() {
        #expect(HotKey.toggle.keyCode == 4)
    }

    @Test func carbonModifiersAreControlOptionCommand() {
        // cmdKey 256 | optionKey 2048 | controlKey 4096
        #expect(HotKey.toggle.carbonModifiers == 256 | 2048 | 4096)
    }

    @Test func descriptionUsesMacGlyphsInCanonicalOrder() {
        #expect(HotKey.toggle.displayString == "⌃⌥⌘H")
    }

    @Test func descriptionForOtherModifiers() {
        let k = HotKey(keyCode: 0, keyLabel: "A", modifiers: [.shift, .command])
        #expect(k.displayString == "⇧⌘A")
        #expect(k.carbonModifiers == 512 | 256)
    }
}

@Suite struct HotKeyValidationTests {
    @Test func acceptsCommandControlOrOptionCombos() {
        for m: HotKey.Modifiers in [.command, .control, .option, [.shift, .command]] {
            #expect(HotKey.validate(keyCode: 0, modifiers: m) == .accepted)
        }
    }

    @Test func rejectsBareAndShiftOnlyKeys() {
        for m: HotKey.Modifiers in [[], .shift] {
            guard case .rejected(let msg) = HotKey.validate(keyCode: 0, modifiers: m) else {
                Issue.record("expected rejection for \(m)")
                continue
            }
            #expect(!msg.isEmpty)
        }
    }

    @Test func acceptsFunctionKeysF1ToF20WithoutModifiers() {
        let codes: [UInt32] = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79, 80, 90]
        #expect(codes.count == 20)
        for c in codes { #expect(HotKey.validate(keyCode: c, modifiers: []) == .accepted) }
    }

    @Test func fKeyNamesFollowKeyCodeTable() {
        #expect(HotKey.fKeyName(keyCode: 122) == "F1")
        #expect(HotKey.fKeyName(keyCode: 111) == "F12")
        #expect(HotKey.fKeyName(keyCode: 90) == "F20")
        #expect(HotKey.fKeyName(keyCode: 0) == nil)
    }
}

@Suite struct HotKeyLabelTests {
    @Test func letterLabelIsUppercasedCharacters() {
        #expect(HotKey.label(keyCode: 0, characters: "a") == "A")
    }

    @Test func fKeyLabelIgnoresCharacters() {
        #expect(HotKey.label(keyCode: 105, characters: "\u{F708}") == "F13")
    }

    @Test func namedKeysGetReadableLabels() {
        #expect(HotKey.label(keyCode: 49, characters: " ") == "Space")
    }

    @Test func unknownNonPrintableFallsBackToKeyCode() {
        #expect(HotKey.label(keyCode: 200, characters: "") == "Key 200")
    }

    @Test func fKeyWithModifiersDisplays() {
        let k = HotKey(keyCode: 122, keyLabel: "F1", modifiers: [.control])
        #expect(k.displayString == "⌃F1")
    }
}

@Suite struct ShortcutRecorderTests {
    @Test func escapeCancels() {
        #expect(ShortcutRecorder.interpret(keyCode: 53, modifiers: [], characters: "\u{1B}") == .cancelled)
    }

    @Test func validComboBecomesCandidate() {
        let out = ShortcutRecorder.interpret(keyCode: 38, modifiers: [.control, .option], characters: "j")
        #expect(out == .candidate(HotKey(keyCode: 38, keyLabel: "J", modifiers: [.control, .option])))
    }

    @Test func bareLetterIsRejectedWithMessage() {
        guard case .rejected(let msg) = ShortcutRecorder.interpret(keyCode: 0, modifiers: [], characters: "a") else {
            Issue.record("expected rejection")
            return
        }
        #expect(!msg.isEmpty)
    }
}
