import AppKit

// Hidden developer flag: render the README demo images offscreen and exit.
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--render-demo") {
    let dir = i + 1 < args.count ? args[i + 1] : "docs/images"
    exit(DemoRenderer.run(outputDirectory: dir) ? 0 : 1)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
