import AppKit

// Create an autorelease pool for Cocoa
autoreleasepool {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)

    let alert = NSAlert()
    alert.messageText = "Hello!"
    alert.informativeText = "This is a Swift message box."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")

    // Bring the alert to front
    app.activate(ignoringOtherApps: true)
    alert.runModal()
}
