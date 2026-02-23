import SwiftUI
import AppKit

class NotchWindowController: NSObject {
    var window: NSWindow!
    var hoverObserver: HoverObserver!
    
    override init() {
        super.init()
        setupWindow()
    }
    
    func setupWindow() {
        // Calculate the position for the notch
        // Assuming primary screen
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        
        // Make the window wide enough to accommodate maximum expanded width
        let notchWidth: CGFloat = 2800 
        // Reset base panel height to support the raw view height without spacer.
        let notchHeight: CGFloat = 180 // The max expanded height we will allow
        
        // Window y position: Top of screen - notchHeight
        let rect = NSRect(
            x: screenRect.midX - (notchWidth / 2),
            y: screenRect.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
        
        window = NSWindow(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        // Floating above everything
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false // We need this to receive hover, but we might toggle it based on intersection
        let hostingView = NSHostingView<AnyView>(rootView: AnyView(EmptyView()))
        window.contentView = hostingView
        
        hoverObserver = HoverObserver(window: window, hostingView: hostingView)
        
        let contentView = ContentView()
            .environmentObject(hoverObserver)
        hostingView.rootView = AnyView(contentView)
    }
    
    func showWindow() {
        window.makeKeyAndOrderFront(nil)
    }
}
