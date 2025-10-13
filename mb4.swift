import Cocoa

class BoxWindow: NSWindow {
    init(title: String, x: CGFloat, y: CGFloat, boxNumber: Int) {
        let width: CGFloat = 200
        let height: CGFloat = 100
        super.init(contentRect: NSRect(x: x, y: y, width: width, height: height),
                   styleMask: [.titled, .closable],
                   backing: .buffered,
                   defer: false)
        self.title = title
        self.isReleasedWhenClosed = true

        // Add label with box text
        let label = NSTextField(labelWithString: "This is box \(boxNumber)")
        label.frame = NSRect(x: 20, y: 60, width: width - 40, height: 20)
        label.alignment = .center
        self.contentView?.addSubview(label)

        // Add OK button
        let button = NSButton(title: "OK", target: self, action: #selector(closeWindow))
        button.frame = NSRect(x: width/2 - 40, y: 10, width: 80, height: 30)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        self.contentView?.addSubview(button)
    }

    @objc func closeWindow() {
        self.close()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)

// compute center of main screen
let screenFrame = NSScreen.main!.frame
let boxWidth: CGFloat = 200
let boxHeight: CGFloat = 80
var x: CGFloat = screenFrame.midX - boxWidth / 2
var y: CGFloat = screenFrame.midY - boxHeight / 2

for i in 1...10 {
    let window = BoxWindow(title: "Box \(i)", x: x, y: y, boxNumber: i)
    window.makeKeyAndOrderFront(nil)

    x += 20
    y -= 20

    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
}

app.run()
