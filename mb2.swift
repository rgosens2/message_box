import AppKit

class MessageBox: NSWindow {
    init(title: String, text: String, origin: NSPoint) {
        let size = NSSize(width: 300, height: 150)
        super.init(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        self.title = title
        self.isReleasedWhenClosed = false

        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 20, y: 70, width: 260, height: 40)
        label.alignment = .center
        self.contentView?.addSubview(label)

        let button = NSButton(title: "OK", target: self, action: #selector(closeWindow))
        button.frame = NSRect(x: 110, y: 20, width: 80, height: 30)
        self.contentView?.addSubview(button)
    }

    @objc func closeWindow() {
        self.close()
    }
}

autoreleasepool {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)

    let screen = NSScreen.main!
    let center = NSPoint(x: screen.frame.midX - 150, y: screen.frame.midY - 75)

    let win1 = MessageBox(title: "First Box",
                          text: "This is the first message box.",
                          origin: center)
    win1.makeKeyAndOrderFront(nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        var offset = center
        offset.x += 10
        offset.y -= 10
        let win2 = MessageBox(title: "Second Box",
                              text: "Appears 10 px down and right.",
                              origin: offset)
        win2.makeKeyAndOrderFront(nil)
    }

    app.run()
}
