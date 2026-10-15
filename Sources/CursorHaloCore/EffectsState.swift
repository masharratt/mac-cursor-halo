/// What the app should draw, derived from the per-effect flags.
public struct RenderPlan: Equatable, Sendable {
    public let showHighlight: Bool
    public let showRipple: Bool

    public init(showHighlight: Bool, showRipple: Bool) {
        self.showHighlight = showHighlight
        self.showRipple = showRipple
    }

    /// The highlight appears only on the screen that contains the cursor.
    public func highlightVisible(screenIndex: Int, cursorScreenIndex: Int?) -> Bool {
        showHighlight && cursorScreenIndex == screenIndex
    }
}

extension Settings {
    public var renderPlan: RenderPlan {
        RenderPlan(
            showHighlight: highlightEnabled,
            showRipple: rippleEnabled
        )
    }
}
