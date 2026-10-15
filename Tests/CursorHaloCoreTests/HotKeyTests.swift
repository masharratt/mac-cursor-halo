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
