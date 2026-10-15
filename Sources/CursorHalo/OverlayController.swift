import AppKit
import CursorHaloCore
import QuartzCore

/// One transparent, click-through window per screen, with a highlight layer and ripple rings.
@MainActor
final class ScreenOverlay {
    let window: NSWindow
    let frame: CGRect
    let highlight = CAShapeLayer()

    init(screen: NSScreen) {
        frame = screen.frame
        window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let view = NSView(frame: CGRect(origin: .zero, size: frame.size))
        view.wantsLayer = true
        window.contentView = view
        view.layer?.addSublayer(highlight)
        highlight.isHidden = true
        window.setFrame(frame, display: false)
        window.orderFrontRegardless()
    }

    var rootLayer: CALayer { window.contentView!.layer! }

    func close() {
        window.orderOut(nil)
        window.close()
    }
}

@MainActor
final class OverlayController {
    private var overlays: [ScreenOverlay] = []
    private var settings = Settings()
    private var lastCursor = NSEvent.mouseLocation

    init() {
        rebuild()
    }

    func rebuild() {
        overlays.forEach { $0.close() }
        overlays = NSScreen.screens.map { ScreenOverlay(screen: $0) }
        applyStyle()
        moveHighlight(to: NSEvent.mouseLocation)
    }

    func apply(_ new: Settings) {
        settings = new
        applyStyle()
        moveHighlight(to: lastCursor)
    }

    private func nsColor(_ rgb: RGB, alpha: Double) -> CGColor {
        CGColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: alpha)
    }

    private func applyStyle() {
        let r = settings.size.radius
        let rect = CGRect(x: -r, y: -r, width: r * 2, height: r * 2)
        let path = CGPath(ellipseIn: rect, transform: nil)
        let rgb = settings.color.rgb
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for o in overlays {
            o.highlight.path = path
            o.highlight.fillColor = nsColor(rgb, alpha: Settings.highlightAlpha)
            o.highlight.strokeColor = nsColor(rgb, alpha: 0.8)
            o.highlight.lineWidth = 2
        }
        CATransaction.commit()
    }

    func moveHighlight(to point: CGPoint) {
        lastCursor = point
        let plan = settings.renderPlan
        let cursorScreen = ScreenGeometry.index(containing: point, in: overlays.map(\.frame))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (i, o) in overlays.enumerated() {
            let visible = plan.highlightVisible(screenIndex: i, cursorScreenIndex: cursorScreen)
            o.highlight.isHidden = !visible
            if visible {
                o.highlight.position = ScreenGeometry.localPoint(point, in: o.frame)
            }
        }
        CATransaction.commit()
    }

    func ripple(at point: CGPoint, rightClick: Bool) {
        guard settings.renderPlan.showRipple,
              let index = ScreenGeometry.index(containing: point, in: overlays.map(\.frame))
        else { return }
        let overlay = overlays[index]
        let anim = RippleAnimation.standard(baseRadius: settings.size.radius)
        let rgb = rightClick ? settings.color.rightClickRGB : settings.color.leftClickRGB

        // Draw the ring at its final size and scale it from the start radius.
        let ring = CAShapeLayer()
        let r = anim.endRadius
        ring.path = CGPath(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2), transform: nil)
        ring.fillColor = nil
        ring.strokeColor = nsColor(rgb, alpha: 1)
        ring.lineWidth = 3
        ring.position = ScreenGeometry.localPoint(point, in: overlay.frame)
        ring.opacity = 0

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = anim.startRadius / anim.endRadius
        scale.toValue = 1.0
        scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1.0
        fade.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = anim.duration
        group.isRemovedOnCompletion = true

        let root = overlay.rootLayer
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak ring] in
            MainActor.assumeIsolated { ring?.removeFromSuperlayer() }
        }
        root.addSublayer(ring)
        ring.add(group, forKey: "ripple")
        CATransaction.commit()
    }
}
