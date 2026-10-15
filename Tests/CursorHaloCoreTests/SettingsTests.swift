import Foundation
import Testing
@testable import CursorHaloCore

@Suite struct SettingsTests {
    @Test func defaultsMatchSpec() {
        let s = Settings()
        #expect(s.highlightEnabled)
        #expect(s.rippleEnabled)
        #expect(s.size == .medium)
        #expect(s.color == .yellow)
    }

    @Test func sizeRadii() {
        #expect(HaloSize.small.radius == 20)
        #expect(HaloSize.medium.radius == 32)
        #expect(HaloSize.large.radius == 48)
    }

    @Test func highlightAlphaIsAboutPointThreeFive() {
        #expect(Settings.highlightAlpha == 0.35)
    }

    @Test func everyColorHasValidComponents() {
        #expect(HaloColor.allCases.count == 5)
        for c in HaloColor.allCases {
            for v in [c.red, c.green, c.blue] { #expect((0...1).contains(v)) }
        }
    }

    @Test func rippleColorsDifferByButton() {
        for c in HaloColor.allCases {
            #expect(c.leftClickRGB != c.rightClickRGB)
        }
    }

    @Test func freshStoreReturnsDefaults() {
        let store = SettingsStore(backing: InMemoryBacking())
        #expect(store.load() == Settings())
    }

    @Test func roundTrip() {
        let backing = InMemoryBacking()
        let store = SettingsStore(backing: backing)
        var s = Settings()
        s.highlightEnabled = false
        s.size = .large
        s.color = .pink
        s.rippleEnabled = false
        store.save(s)
        #expect(SettingsStore(backing: backing).load() == s)
    }

    @Test func corruptDataFallsBackToDefaults() {
        let backing = InMemoryBacking()
        backing.set(Data("not json".utf8), forKey: SettingsStore.key)
        #expect(SettingsStore(backing: backing).load() == Settings())
    }

    @Test func wrongShapeJSONFallsBackToDefaults() {
        let backing = InMemoryBacking()
        backing.set(Data(#"{"size":"gigantic"}"#.utf8), forKey: SettingsStore.key)
        #expect(SettingsStore(backing: backing).load() == Settings())
    }

    @Test func userDefaultsBackingRoundTrips() {
        let suite = "cursorhalo.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SettingsStore(backing: defaults)
        var s = Settings()
        s.color = .blue
        store.save(s)
        #expect(store.load().color == .blue)
    }

    @Test func defaultToggleHotKeyIsControlOptionCommandH() {
        #expect(Settings().toggleHotKey == HotKey.toggle)
        #expect(Settings().toggleHotKey.displayString == "⌃⌥⌘H")
    }

    @Test func customHotKeyRoundTrips() {
        let backing = InMemoryBacking()
        let store = SettingsStore(backing: backing)
        var s = Settings()
        s.toggleHotKey = HotKey(keyCode: 105, keyLabel: "F13", modifiers: [.shift])
        store.save(s)
        #expect(SettingsStore(backing: backing).load().toggleHotKey == s.toggleHotKey)
    }

    @Test func oldSavedSettingsWithoutHotKeyDecodeToDefaultHotKey() {
        let backing = InMemoryBacking()
        backing.set(Data(#"{"size":"large"}"#.utf8), forKey: SettingsStore.key)
        let s = SettingsStore(backing: backing).load()
        #expect(s.size == .large)
        #expect(s.toggleHotKey == HotKey.toggle)
    }

    @Test func legacyMasterFlagOffIsIgnoredAndHidesNothing() {
        let backing = InMemoryBacking()
        backing.set(Data(#"{"effectsEnabled":false,"size":"large"}"#.utf8), forKey: SettingsStore.key)
        let s = SettingsStore(backing: backing).load()
        #expect(s.size == .large)
        #expect(s.renderPlan == RenderPlan(showHighlight: true, showRipple: true))
    }
}
