import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var windowController: MyWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cascading Boxes Example"
        window.center()

        // Create window controller
        windowController = MyWindowController(window: window)
        windowController?.showWindow(nil)
    }
}

class MyWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let contentView = window?.contentView else { return }

        let boxSize: CGFloat = 50
        let offset: CGFloat = 20

        // Create 10 cascading boxes
        for i in 0..<10 {
            let box = NSBox(frame: NSRect(
                x: 20 + CGFloat(i) * offset,
                y: 300 - CGFloat(i) * offset,
                width: boxSize,
                height: boxSize
            ))
            box.boxType = .custom
            box.borderWidth = 2
            box.fillColor = NSColor(
                red: CGFloat(i)/10.0,
                green: 0.5,
                blue: 1.0 - CGFloat(i)/10.0,
                alpha: 1.0
            )
            contentView.addSubview(box)
        }

        // Add Close button
        let button = NSButton(frame: NSRect(x: 200, y: 20, width: 100, height: 40))
        button.title = "Close"
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(closeWindow(_:))
        contentView.addSubview(button)
    }

    @objc func closeWindow(_ sender: NSButton) {
        self.window?.close()
    }
}
