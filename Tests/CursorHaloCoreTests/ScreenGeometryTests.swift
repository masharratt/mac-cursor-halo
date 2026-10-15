import CoreGraphics
import Testing
@testable import CursorHaloCore

@Suite struct ScreenGeometryTests {
    // Main at origin, second to the left (negative x), third above.
    let frames = [
        CGRect(x: 0, y: 0, width: 1440, height: 900),
        CGRect(x: -1920, y: 0, width: 1920, height: 1080),
        CGRect(x: 0, y: 900, width: 1440, height: 900),
    ]

    @Test func findsMainScreen() {
        #expect(ScreenGeometry.index(containing: CGPoint(x: 100, y: 100), in: frames) == 0)
    }

    @Test func findsNegativeOriginScreen() {
        #expect(ScreenGeometry.index(containing: CGPoint(x: -10, y: 500), in: frames) == 1)
    }

    @Test func findsScreenAbove() {
        #expect(ScreenGeometry.index(containing: CGPoint(x: 700, y: 1000), in: frames) == 2)
    }

    @Test func boundaryBelongsToExactlyOneScreen() {
        // x == 0 belongs to the main screen (min edge inclusive, max edge exclusive).
        #expect(ScreenGeometry.index(containing: CGPoint(x: 0, y: 10), in: frames) == 0)
    }

    @Test func pointOutsideAllScreensIsNil() {
        #expect(ScreenGeometry.index(containing: CGPoint(x: 5000, y: 5000), in: frames) == nil)
        #expect(ScreenGeometry.index(containing: .zero, in: []) == nil)
    }

    @Test func localPointSubtractsOrigin() {
        let p = ScreenGeometry.localPoint(CGPoint(x: -1000, y: 300), in: frames[1])
        #expect(p == CGPoint(x: 920, y: 300))
    }

    @Test func localPointOnMainIsIdentity() {
        let p = CGPoint(x: 12, y: 34)
        #expect(ScreenGeometry.localPoint(p, in: frames[0]) == p)
    }
}
