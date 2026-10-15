import Testing
@testable import CursorHaloCore

@Suite struct EffectsStateTests {
    @Test func defaultsRenderEverything() {
        let plan = Settings().renderPlan
        #expect(plan.showHighlight && plan.showRipple)
    }

    @Test(arguments: [(true, true), (true, false), (false, true), (false, false)])
    func perEffectFlagsDriveRenderPlan(h: Bool, r: Bool) {
        var s = Settings()
        s.highlightEnabled = h
        s.rippleEnabled = r
        #expect(s.renderPlan == RenderPlan(showHighlight: h, showRipple: r))
    }

    @Test func toggleHighlightFlipsOnlyHighlight() {
        var s = Settings()
        s.toggleHighlight()
        #expect(s.renderPlan == RenderPlan(showHighlight: false, showRipple: true))
        s.toggleHighlight()
        #expect(s.renderPlan == RenderPlan(showHighlight: true, showRipple: true))
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
