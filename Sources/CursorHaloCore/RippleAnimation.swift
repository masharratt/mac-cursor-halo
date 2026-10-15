import Foundation

public struct RippleFrame: Equatable, Sendable {
    public let radius: Double
    public let alpha: Double
    public let isFinished: Bool
}

/// Pure math for the click ripple: ring grows with ease-out and fades linearly.
public struct RippleAnimation: Equatable, Sendable {
    public let startRadius: Double
    public let endRadius: Double
    public let duration: Double

    public init(startRadius: Double, endRadius: Double, duration: Double) {
        self.startRadius = startRadius
        self.endRadius = endRadius
        self.duration = duration
    }

    /// Ripple sized relative to the halo radius, lasting 0.4 seconds.
    public static func standard(baseRadius: Double) -> RippleAnimation {
        RippleAnimation(startRadius: baseRadius * 0.3, endRadius: baseRadius * 2.0, duration: 0.4)
    }

    public func progress(at elapsed: Double) -> RippleFrame {
        let t = duration <= 0 ? 1 : min(max(elapsed / duration, 0), 1)
        let eased = 1 - (1 - t) * (1 - t)
        return RippleFrame(
            radius: startRadius + (endRadius - startRadius) * eased,
            alpha: 1 - t,
            isFinished: t >= 1
        )
    }
}
