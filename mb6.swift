import Cocoa

class BoxWindow: NSWindow {
    init() {
        let width: CGFloat = 200
        let height: CGFloat = 120
        let screen = NSScreen.main!.frame
        let x = (screen.width - width) / 2
        let y = (screen.height - height) / 2

        super.init(contentRect: NSRect(x: x, y: y, width: width, height: height),
                   styleMask: [.titled, .closable],
                   backing: .buffered,
                   defer: false)
        self.title = "Box Demo"
        self.makeKeyAndOrderFront(nil)

        let label = NSTextField(labelWithString: "Hello Box!")
        label.alignment = .center
        label.frame = NSRect(x: 20, y: 50, width: width - 40, height: 20)
        self.contentView?.addSubview(label)
    }
}

// Required for Cmd+Q
class QuitHandler: NSObject {
    @objc func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Create a dummy window FIRST
let win = BoxWindow()
app.activate(ignoringOtherApps: true)

// Build menu AFTER window exists
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)

let appMenu = NSMenu(title: "Application")
let quitTitle = "Quit " + ProcessInfo.processInfo.processName
let quitItem = NSMenuItem(title: quitTitle,
                          action: #selector(QuitHandler.quit(_:)),
                          keyEquivalent: "q")
quitItem.target = QuitHandler()
appMenu.addItem(quitItem)
appMenuItem.submenu = appMenu

app.mainMenu = mainMenu

app.run()
