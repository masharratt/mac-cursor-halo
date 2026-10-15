import Testing
@testable import CursorHaloCore

@Suite struct RippleAnimationTests {
    let anim = RippleAnimation(startRadius: 10, endRadius: 50, duration: 0.4)

    @Test func startFrame() {
        let f = anim.progress(at: 0)
        #expect(f.radius == 10)
        #expect(f.alpha == 1)
        #expect(!f.isFinished)
    }

    @Test func endFrame() {
        let f = anim.progress(at: 0.4)
        #expect(f.radius == 50)
        #expect(f.alpha == 0)
        #expect(f.isFinished)
    }

    @Test func midFrameIsBetween() {
        let f = anim.progress(at: 0.2)
        #expect(f.radius > 10 && f.radius < 50)
        #expect(f.alpha > 0 && f.alpha < 1)
        #expect(!f.isFinished)
    }

    @Test func clampsOutOfRange() {
        #expect(anim.progress(at: -1).radius == 10)
        #expect(anim.progress(at: 99).isFinished)
        #expect(anim.progress(at: 99).radius == 50)
    }

    @Test func radiusIsMonotonicAndAlphaNonIncreasing() {
        var lastR = -1.0, lastA = 2.0
        for i in 0...40 {
            let f = anim.progress(at: Double(i) * 0.01)
            #expect(f.radius >= lastR)
            #expect(f.alpha <= lastA)
            lastR = f.radius; lastA = f.alpha
        }
    }

    @Test func zeroDurationFinishesImmediately() {
        let a = RippleAnimation(startRadius: 1, endRadius: 2, duration: 0)
        #expect(a.progress(at: 0).isFinished)
    }

    @Test func standardDurationIsPointFourSeconds() {
        #expect(RippleAnimation.standard(baseRadius: 32).duration == 0.4)
    }
}
