import CoreGraphics

public enum ScreenGeometry {
    /// Index of the first frame containing the point. Min edges are inclusive, max edges exclusive,
    /// so a point on a shared border belongs to exactly one screen. Works with negative origins.
    public static func index(containing point: CGPoint, in frames: [CGRect]) -> Int? {
        frames.firstIndex { frame in
            point.x >= frame.minX && point.x < frame.maxX
                && point.y >= frame.minY && point.y < frame.maxY
        }
    }

    /// Converts a global AppKit point to a point local to the given screen frame.
    public static func localPoint(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(x: point.x - frame.minX, y: point.y - frame.minY)
    }
}
