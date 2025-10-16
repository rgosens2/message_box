// Build: swiftc -framework Cocoa mb5.swift -o mb5.app/Contents/MacOS/mb5
// Debug add: -g -Onone
// Run: open mb5.app
// NOTE: With the gameloop and sound in place we can now create snake, tetris, breakout, etc.
// Or do a re-implementation in Swift of our sorting algos.
// Eventually we will have to switch to Metal for graphics.
// And start a career as a game developer.
// NOTE: When uploading to GitHub, if you get a HTTP 400 error, try this:
// git config --global http.postBuffer 157286400
// See: https://stackoverflow.com/questions/77856025/git-error-rpc-failed-http-400-curl-22-the-requested-url-returned-error-400-se
import Cocoa
import AVFoundation
import Foundation


// ----------------------- Tone engine -----------------------
// NOTE: Even with separate AVAudioPlayerNode instances, running under the debugger
// triggers -10878 exceptions for very short scheduled buffers. This is actually 
// normal behavior in Xcode/LLDB on macOS. The audio engine is designed to throw 
// this exception internally if the buffer scheduling is very rapid or the node hasn’t
// fully initialized, and the debugger breaks on all thrown exceptions by default.
// FIX: VS Code -> Breakpoints -> C++: on throw -> uncheck
let engine = AVAudioEngine()
let player = AVAudioPlayerNode()
engine.attach(player)

// Match the player to the current output device format
let output = engine.outputNode
let hwFormat = output.outputFormat(forBus: 0)

// Connect player → output node
engine.connect(player, to: output, format: hwFormat)

do {
    try engine.start()
    print("Engine started successfully")
} catch {
    print("Error starting engine:", error)
}

func playTone(frequency: Double, duration: Double) {
    let sampleRate = hwFormat.sampleRate
    let frameCount = AVAudioFrameCount(duration * sampleRate)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: hwFormat, frameCapacity: frameCount) else { return }
    buffer.frameLength = frameCount

    let theta = 2.0 * Double.pi * frequency / sampleRate
    let channelData = buffer.floatChannelData![0]

    for i in 0..<Int(frameCount) {
        channelData[i] = Float(sin(theta * Double(i))) * 0.1  // * 0.1 reduce volume to avoid clipping
    }

    // Schedule buffer on main thread to avoid debugger issues
    DispatchQueue.main.async {
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying {
            player.volume = 0.3  // 30% volume
            player.play()
        }
    }
}


func getDockHeight() -> CGFloat {
    guard let screen = NSScreen.main else { return 0 }

    let fullFrame = screen.frame
    let visibleFrame = screen.visibleFrame

    // Calculate difference on each side
    //let diffTop = fullFrame.maxY - visibleFrame.maxY     // menu bar
    let diffBottom = visibleFrame.minY - fullFrame.minY  // dock (bottom)
    let diffLeft = visibleFrame.minX - fullFrame.minX    // dock (left)
    let diffRight = fullFrame.maxX - visibleFrame.maxX   // dock (right)

    // Detect which side the Dock is on and return its size
    if diffBottom > 0 {
        return diffBottom        // bottom dock
    } else if diffLeft > 0 {
        return diffLeft          // left dock
    } else if diffRight > 0 {
        return diffRight         // right dock
    } else {
        return 0                 // hidden dock
    }
}



// ----------------------- FPS counter -----------------------
private var _fpsLastTime = CFAbsoluteTimeGetCurrent()
private var _fpsFrameCount = 0

func getFPS(autoPrint: Bool = true) -> Double {
    _fpsFrameCount += 1
    let currentTime = CFAbsoluteTimeGetCurrent()
    let delta = currentTime - _fpsLastTime

    var fps: Double = 0
    if delta >= 1.0 {
        fps = Double(_fpsFrameCount) / delta
        _fpsFrameCount = 0
        _fpsLastTime = currentTime

        if autoPrint {
            print(String(format: "FPS: %.1f", fps))
        }
    }

    return fps
}


// Pause to allow debugger attach
// NOTE: not necessary: we forgot to build with -g -Onone
//print("Waiting for debugger attach...")
//sleep(10)


class BoxWindow: NSWindow {

    static var shared: BoxWindow?   // global reference

    init(title: String, x: CGFloat, y: CGFloat, boxNumber: Int) {
        let width: CGFloat = boxWidth
        let height: CGFloat = boxHeight
        super.init(contentRect: NSRect(x: x, y: y, width: width, height: height),
                   styleMask: [.titled, .closable],
                   backing: .buffered,
                   defer: false)
        self.title = title
        self.isReleasedWhenClosed = false  // important: don't release app reference, only close box

        // Add label with box text
        let label = NSTextField(labelWithString: "This is box \(boxNumber)")
        label.frame = NSRect(x: 20, y: 60, width: width - 40, height: 20)
        label.alignment = .center
        self.contentView?.addSubview(label)

        // Add OK button
        let button = NSButton(title: "OK", target: self, action: #selector(closeWindow))
        button.frame = NSRect(x: width/2 - 40, y: 10, width: 80, height: 30)
        self.contentView?.addSubview(button)        
    }

    @objc func closeWindow() {
        self.close()
    }

    func move(to x: CGFloat, y: CGFloat, animated: Bool = false) {
        DispatchQueue.main.async {
            let newOrigin = NSPoint(x: x, y: y)
            if animated {
                self.animator().setFrameOrigin(newOrigin)
            } else {
                self.setFrameOrigin(newOrigin)
            }
        }
    }
}


class AboutWindow: NSWindow {
    init() {
        let width: CGFloat = 300
        let height: CGFloat = 180
        super.init(contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                   styleMask: [.titled, .closable],
                   backing: .buffered,
                   defer: false)
        self.title = "About MyBoxes"
        self.isReleasedWhenClosed = false

        // Load the app icon from bundle
        let icon: NSImage
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns") {
            icon = NSImage(contentsOfFile: iconPath) ?? NSImage(size: NSSize(width: 64, height: 64))
        } else {
            icon = NSImage(size: NSSize(width: 64, height: 64))
        }

        let iconView = NSImageView(image: icon)
        iconView.frame = NSRect(x: width/2 - 32, y: height - 90, width: 64, height: 64)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        self.contentView?.addSubview(iconView)

        // Add label below icon
        let text = """
        MyBoxes 1.0
        © 2025 RG
        A Swift/Cocoa demo app.
        """

        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 20, y: 20, width: width - 40, height: 60)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 14)
        label.isSelectable = false
        //label.wantsLayer = true
        //label.layer?.borderWidth = 1
        //label.layer?.borderColor = NSColor.white.cgColor
        self.contentView?.addSubview(label)
    }
}


// NOTE: we were not getting a menu bar because we set LSUIElement to true in Info.plist
// We need a proper menu bar to get Cmd+Q working
// So we set LSUIElement to false and build a minimal menu bar programmatically
let app = NSApplication.shared

// Activate as a regular app first — required for menu bar visibility
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)

// Keep handlers alive globally
var aboutHandler: AboutInterceptor!
var quitHandler: QuitInterceptor!

// About handler class must exist before binding
class AboutInterceptor: NSObject {
    @objc func showAbout(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        let about = AboutWindow()
        about.center()
        about.makeKeyAndOrderFront(nil)
    }
}

aboutHandler = AboutInterceptor()


// Quit handler class must exist before binding
class QuitInterceptor: NSObject {
    @objc func quit(_ sender: Any?) {
        shouldQuit = true
        app.terminate(nil)
    }
}

quitHandler = QuitInterceptor()



// Build the proper Cocoa menu hierarchy
let mainMenu = NSMenu()
let appMenuItem = NSMenuItem()
mainMenu.addItem(appMenuItem)

let appMenu = NSMenu(title: "Application")

let aboutTitle = "About " + ProcessInfo.processInfo.processName
let aboutItem = NSMenuItem(title: aboutTitle,
                          action: #selector(AboutInterceptor.showAbout(_:)),
                          keyEquivalent: "")
aboutItem.target = aboutHandler
appMenu.addItem(aboutItem)

appMenu.addItem(NSMenuItem.separator())

let quitTitle = "Quit " + ProcessInfo.processInfo.processName
let quitItem = NSMenuItem(title: quitTitle,
                          action: #selector(QuitInterceptor.quit(_:)),
                          keyEquivalent: "q")
quitItem.target = quitHandler
appMenu.addItem(quitItem)

appMenuItem.submenu = appMenu
app.mainMenu = mainMenu



// Quit flag
var shouldQuit = false
NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: nil) { _ in
    shouldQuit = true
}

// Screen info
let screenFrame = NSScreen.main!.frame
let boxWidth: CGFloat = 200
let boxHeight: CGFloat = 100
var x: CGFloat = screenFrame.midX - boxWidth / 2
var y: CGFloat = screenFrame.midY - boxHeight / 2

// Box creation state
var boxCount = 0
let totalBoxes = 333

func createNextBox() {
    // Force the debugger to stop here
    // NOTE: not necessary: we forgot to build with -g -Onone
    //print("DEBUG: reached createNextBox") 
    //raise(SIGTRAP)  // triggers debugger breakpoint

    //if shouldQuit || boxCount >= totalBoxes { return }
    if shouldQuit { return }

    if (boxCount == 0) {
        // Create and show the next box
        BoxWindow.shared = BoxWindow(title: "Box \(boxCount + 1)", x: x, y: y, boxNumber: boxCount + 1)
        BoxWindow.shared?.makeKeyAndOrderFront(nil)
        BoxWindow.shared?.level = .normal  // ensure it's at normal level
        BoxWindow.shared?.orderFrontRegardless()  // force front
    }

    // Play a short tone (non-blocking)
    //let freq = 440.0 + Double(boxCount % 10) * 110.0
    let freq = 1.2*(x + y)
    DispatchQueue.main.async {
        playTone(frequency: freq, duration: 0.2)
    }

    // Move position
    //x += 15
    // Wrap around if needed
    if (x > screenFrame.width) {
        x = 0
        y += boxHeight
        if (y + boxHeight > screenFrame.height) {
            y = getDockHeight()
        }
    } else {
        x += 5
    }

    // Move the message box
    BoxWindow.shared?.move(to: x, y: y, animated: true)

    // Randomize next position
    //x = CGFloat.random(in: 0...(screenFrame.width - boxWidth))
    //y = CGFloat.random(in: 0...(screenFrame.height - boxHeight))
    //x += 1

    boxCount += 1
    //print("Created box \(boxCount)")
    //NSLog("Created box \(boxCount)")

    //let fps = getFPS()
    //print(String(format: "FPS: %.1f", fps))
    _ = getFPS()


    // Schedule next box asynchronously
    // DispatchQueue.main.async {
    //     createNextBox()
    // }

    // Schedule next box with a slight delay (0.02 s = 20 ms)
    // DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
    //     createNextBox()
    // }

    // Yield to main run loop for ~20ms to handle Cmd+Q and events
    CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.00, true)

    // Schedule next box asynchronously so the run loop fully resumes first
    // DispatchQueue.main.async {
    //     createNextBox()
    // }

    // Schedule next box with a slight delay (0.02 s = 20 ms)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.00) {
        createNextBox()
    }
}

// Start creating boxes after run loop starts
DispatchQueue.main.async {
    createNextBox()
}

app.run()
