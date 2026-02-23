import SwiftUI
import AppKit

@main
struct macbarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We use Settings to avoid creating a default main window,
        // since we are managing our own borderless Notch window.
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    
    var windowController: NotchWindowController?
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    
    override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        windowController = NotchWindowController()
        windowController?.showWindow()
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "macbar")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit macbar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func openSettings() {
        print("AppDelegate openSettings called!")
        if settingsWindow == nil {
            print("Creating new Settings Window...")
            let hostingController = NSHostingController(rootView: SettingsView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.title = "macbar Settings"
            window.contentViewController = hostingController
            window.isReleasedWhenClosed = false
            window.level = .floating // Ensure it appears above the current workspace
            
            // Explicitly force center placement on primary screen
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let windowRect = window.frame
                let newOrigin = NSPoint(
                    x: screenRect.midX - (windowRect.width / 2),
                    y: screenRect.midY - (windowRect.height / 2)
                )
                window.setFrameOrigin(newOrigin)
            } else {
                window.center()
            }
            
            self.settingsWindow = window
        }
        
        print("Ordering Settings Window to front...")
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
