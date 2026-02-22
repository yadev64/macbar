import SwiftUI
import AppKit

class HoverObserver: ObservableObject {
    @Published var isHovering: Bool = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    init(window: NSWindow, hostingView: NSView) {
        // We track the mouse position. If we are within the expanded bounds of the app, we show the expanded UI.
        
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            
            // Mouse location in screen coordinates
            let mouseLoc = NSEvent.mouseLocation
            
            // Current window frame
            let windowFrame = window.frame
            
            // Define an interaction area. It should be slightly taller/wider than the notch so we catch approaching mouse.
            let hoverArea = NSRect(
                x: windowFrame.midX - 150,
                y: windowFrame.maxY - 100, // Top 100 pixels around notch
                width: 300,
                height: 100
            )
            
            if hoverArea.contains(mouseLoc) {
                if !self.isHovering {
                    DispatchQueue.main.async {
                        self.isHovering = true
                        window.ignoresMouseEvents = false
                    }
                }
            } else {
                if self.isHovering {
                    DispatchQueue.main.async {
                        self.isHovering = false
                        window.ignoresMouseEvents = true
                    }
                }
            }
        }
        
        // Initial state assuming collapsed
        window.ignoresMouseEvents = true
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved], handler: handler)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
            handler(event)
            return event
        }
    }
    
    deinit {
        if let gm = globalMonitor { NSEvent.removeMonitor(gm) }
        if let lm = localMonitor { NSEvent.removeMonitor(lm) }
    }
}
