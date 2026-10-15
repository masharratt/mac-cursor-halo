import AppKit
import CursorHaloCore

/// Renders README images offscreen with synthetic content, using the real colors, sizes and ripple math.
@MainActor
enum DemoRenderer {
    static let scale = 2

    static func run(outputDirectory dir: String) -> Bool {
        _ = NSApplication.shared
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let demo = render(width: 1200, height: 700, draw: drawScene)
        let colors = render(width: 1200, height: 260, draw: drawColors)
        return write(demo, to: "\(dir)/cursor-halo-demo.png") && write(colors, to: "\(dir)/cursor-halo-colors.png")
    }

    // MARK: Scene

    private static func drawScene(_ ctx: CGContext, _ size: CGSize) {
        drawBackdrop(ctx, size)
        drawWindow(ctx, CGRect(x: 70, y: 60, width: 1060, height: 580))
        let settings = Settings()
        let anim = RippleAnimation.standard(baseRadius: settings.size.radius)

        // Pointer with the highlight circle.
        let p1 = CGPoint(x: 330, y: 400)
        drawHalo(ctx, at: p1, color: settings.color, size: settings.size)
        drawCursor(ctx, at: p1)

        // Frozen left-click ripple (mid-animation).
        let p2 = CGPoint(x: 760, y: 440)
        drawRipple(ctx, at: p2, rgb: settings.color.leftClickRGB, anim: anim, elapsed: 0.14)
        drawCursor(ctx, at: p2)

        // Right-click ripple.
        let p3 = CGPoint(x: 800, y: 210)
        drawRipple(ctx, at: p3, rgb: settings.color.rightClickRGB, anim: anim, elapsed: 0.22)
        drawCursor(ctx, at: p3)
    }

    private static func drawColors(_ ctx: CGContext, _ size: CGSize) {
        drawBackdrop(ctx, size)
        let all = HaloColor.allCases
        let step = size.width / CGFloat(all.count)
        for (i, c) in all.enumerated() {
            let p = CGPoint(x: step * (CGFloat(i) + 0.5), y: size.height / 2 + 20)
            drawHalo(ctx, at: p, color: c, size: .medium)
            drawCursor(ctx, at: p)
            drawLabel(c.title, centerX: p.x, y: 40)
        }
    }

    // MARK: Pieces (same parameters as OverlayController)

    private static func cg(_ rgb: RGB, _ alpha: Double) -> CGColor {
        CGColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha)
    }

    private static func drawHalo(_ ctx: CGContext, at p: CGPoint, color: HaloColor, size: HaloSize) {
        let r = size.radius
        let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
        ctx.setFillColor(cg(color.rgb, Settings.highlightAlpha))
        ctx.fillEllipse(in: rect)
        ctx.setStrokeColor(cg(color.rgb, HaloStyle.highlightStrokeAlpha))
        ctx.setLineWidth(HaloStyle.highlightLineWidth)
        ctx.strokeEllipse(in: rect)
    }

    private static func drawRipple(_ ctx: CGContext, at p: CGPoint, rgb: RGB, anim: RippleAnimation, elapsed: Double) {
        let f = anim.progress(at: elapsed)
        let r = f.radius
        // The live ring is drawn at its end size and scaled, so its stroke scales too.
        ctx.setStrokeColor(cg(rgb, f.alpha))
        ctx.setLineWidth(HaloStyle.rippleLineWidth * r / anim.endRadius)
        ctx.strokeEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }

    /// Draws a standard white arrow with its tip at `p`. Drawn as a vector (not NSCursor.arrow.image)
    /// because the system image picks up the user's own pointer fill color.
    private static func drawCursor(_ ctx: CGContext, at p: CGPoint) {
        let pts: [(CGFloat, CGFloat)] = [(0, 0), (0, 17), (4.2, 13.2), (7.2, 20), (10, 18.7), (7.1, 12.2), (12.6, 12.2)]
        let path = CGMutablePath()
        for (i, q) in pts.enumerated() {
            let pt = CGPoint(x: p.x + q.0 * 1.15, y: p.y - q.1 * 1.15)
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -1.5), blur: 3, color: CGColor(gray: 0, alpha: 0.35))
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))
        ctx.setLineWidth(1.4)
        ctx.setLineJoin(.round)
        ctx.addPath(path)
        ctx.strokePath()
    }

    private static func drawLabel(_ text: String, centerX: CGFloat, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor(white: 0.3, alpha: 1),
        ]
        let s = NSAttributedString(string: text, attributes: attrs)
        s.draw(at: CGPoint(x: centerX - s.size().width / 2, y: y))
    }

    // MARK: Synthetic backdrop

    private static func drawBackdrop(_ ctx: CGContext, _ size: CGSize) {
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let g = CGGradient(colorsSpace: space, colors: [
            CGColor(srgbRed: 0.80, green: 0.85, blue: 0.96, alpha: 1),
            CGColor(srgbRed: 0.90, green: 0.84, blue: 0.95, alpha: 1),
        ] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
    }

    private static func drawWindow(_ ctx: CGContext, _ r: CGRect) {
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 30, color: CGColor(gray: 0, alpha: 0.25))
        let path = CGPath(roundedRect: r, cornerWidth: 12, cornerHeight: 12, transform: nil)
        ctx.setFillColor(CGColor(gray: 0.98, alpha: 1))
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        let bar = CGRect(x: r.minX, y: r.maxY - 44, width: r.width, height: 44)
        ctx.setFillColor(CGColor(gray: 0.91, alpha: 1))
        ctx.fill(bar)
        ctx.setFillColor(CGColor(gray: 0.82, alpha: 1))
        ctx.fill(CGRect(x: r.minX, y: bar.minY - 1, width: r.width, height: 1))
        // Sidebar
        ctx.setFillColor(CGColor(gray: 0.94, alpha: 1))
        ctx.fill(CGRect(x: r.minX, y: r.minY, width: 200, height: r.height - 44))
        ctx.restoreGState()

        for (i, c) in [(1.0, 0.37, 0.34), (1.0, 0.74, 0.18), (0.16, 0.79, 0.25)].enumerated() {
            ctx.setFillColor(CGColor(srgbRed: c.0, green: c.1, blue: c.2, alpha: 1))
            ctx.fillEllipse(in: CGRect(x: r.minX + 18 + CGFloat(i) * 22, y: bar.midY - 6, width: 12, height: 12))
        }
        // Title pill
        ctx.setFillColor(CGColor(gray: 0.80, alpha: 1))
        fillBar(ctx, CGRect(x: r.midX - 90, y: bar.midY - 5, width: 180, height: 10))

        // Sidebar items
        for i in 0..<6 {
            ctx.setFillColor(CGColor(gray: 0.82, alpha: 1))
            fillBar(ctx, CGRect(x: r.minX + 24, y: bar.minY - 40 - CGFloat(i) * 34, width: [110, 90, 130, 80, 100, 120][i], height: 10))
        }
        // Body text lines
        let widths: [CGFloat] = [620, 700, 540, 680, 0, 660, 590, 430, 0, 690, 640, 500]
        var y = bar.minY - 50
        ctx.setFillColor(CGColor(gray: 0.86, alpha: 1))
        fillBar(ctx, CGRect(x: r.minX + 240, y: y, width: 260, height: 16))
        y -= 46
        for w in widths {
            if w > 0 {
                ctx.setFillColor(CGColor(gray: 0.89, alpha: 1))
                fillBar(ctx, CGRect(x: r.minX + 240, y: y, width: w, height: 10))
            }
            y -= 28
        }
    }

    private static func fillBar(_ ctx: CGContext, _ r: CGRect) {
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: r.height / 2, cornerHeight: r.height / 2, transform: nil))
        ctx.fillPath()
    }

    // MARK: Output

    private static func render(width: Int, height: Int, draw: (CGContext, CGSize) -> Void) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width * scale, pixelsHigh: height * scale,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = NSSize(width: width, height: height)
        let gc = NSGraphicsContext(bitmapImageRep: rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = gc
        draw(gc.cgContext, CGSize(width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    private static func write(_ rep: NSBitmapImageRep, to path: String) -> Bool {
        guard let data = rep.representation(using: .png, properties: [:]) else { return false }
        do { try data.write(to: URL(fileURLWithPath: path)); return true } catch { return false }
    }
}
