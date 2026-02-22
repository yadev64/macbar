import SwiftUI
import AppKit

class HoverObserver: ObservableObject {
    @Published var isHovering: Bool = false
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var hoverTask: DispatchWorkItem?
    
    // Configurable top safe area to clear physical notch
    let topSafeArea: CGFloat = 36.0
    
    init(window: NSWindow, hostingView: NSView) {
        
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            
            // Mouse location in absolute screen coordinates (bottom-left origin)
            let mouseLoc = NSEvent.mouseLocation
            
            // Get screen bounds for the screen the mouse is currently on
            guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main else { return }
            let screenRect = screen.frame
            
            // Instantly snap the window to the current screen if it isn't there
            let targetOrigin = NSPoint(x: screenRect.midX - (window.frame.width / 2), y: screenRect.maxY - window.frame.height)
            if window.frame.origin != targetOrigin {
                window.setFrameOrigin(targetOrigin)
            }
            
            // Narrow focus area: only trigger when cursor is near the notch (≈200pt wide, 30pt tall)
            // This ensures expansion starts only when the mouse is close to the notch region.
            let notchWidth: CGFloat = 200 // approximate width of the notch area
            let hoverArea = NSRect(
                x: screenRect.midX - notchWidth / 2,
                y: screenRect.maxY - 30, // just below the top edge
                width: notchWidth,
                height: 30
            )
            
            let isInside = hoverArea.contains(mouseLoc)
            
            // If the state needs to change, debounce it
            if isInside != self.isHovering {
                self.hoverTask?.cancel()
                
                let workItem = DispatchWorkItem {
                    self.isHovering = isInside
                    window.ignoresMouseEvents = !isInside
                }
                
                // Add a small delay for collapsing to avoid flickering if mouse slips out
                // Fast open, slow close.
                let delay = isInside ? 0.05 : 0.3
                self.hoverTask = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
            } else {
                // If it evaluates to the same state we are ALREADY in, 
                // we cancel any pending attempts to change it.
                // (e.g. mouse slipped out for 0.1s but came right back in)
                self.hoverTask?.cancel()
            }
        }
        
        // Initial state
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
        hoverTask?.cancel()
    }
}
