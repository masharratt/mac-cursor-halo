import Testing
@testable import CursorHaloCore

@Suite struct EffectsStateTests {
    @Test func defaultsRenderEverything() {
        let plan = Settings().renderPlan
        #expect(plan.showHighlight && plan.showRipple)
    }

    @Test func masterOffRendersNothing() {
        var s = Settings()
        s.effectsEnabled = false
        #expect(s.renderPlan == RenderPlan(showHighlight: false, showRipple: false))
    }

    @Test(arguments: [(true, true), (true, false), (false, true), (false, false)])
    func perEffectFlagsApplyWhenMasterOn(h: Bool, r: Bool) {
        var s = Settings()
        s.highlightEnabled = h
        s.rippleEnabled = r
        #expect(s.renderPlan == RenderPlan(showHighlight: h, showRipple: r))
    }

    @Test func masterOffPreservesPerEffectFlags() {
        var s = Settings()
        s.rippleEnabled = false
        s.effectsEnabled = false
        s.effectsEnabled = true
        #expect(s.renderPlan == RenderPlan(showHighlight: true, showRipple: false))
    }

    @Test func toggleMasterFlips() {
        var s = Settings()
        s.toggleMaster()
        #expect(!s.effectsEnabled)
        s.toggleMaster()
        #expect(s.effectsEnabled)
    }

    @Test func highlightVisibleOnlyOnCursorScreen() {
        let plan = RenderPlan(showHighlight: true, showRipple: true)
        #expect(plan.highlightVisible(screenIndex: 1, cursorScreenIndex: 1))
        #expect(!plan.highlightVisible(screenIndex: 0, cursorScreenIndex: 1))
        #expect(!plan.highlightVisible(screenIndex: 0, cursorScreenIndex: nil))
        let off = RenderPlan(showHighlight: false, showRipple: true)
        #expect(!off.highlightVisible(screenIndex: 1, cursorScreenIndex: 1))
    }
}
