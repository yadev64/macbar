import SwiftUI
import AppKit

extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}

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
            
            // Read configurable values from settings
            let activationWidth = CGFloat(UserDefaults.standard.double(forKey: "activationWidth").nonZero ?? 200)
            let collapseDelaySetting = UserDefaults.standard.double(forKey: "collapseDelay").nonZero ?? 0.3
            let expandDelaySetting = UserDefaults.standard.double(forKey: "expandDelay").nonZero ?? 0.05
            
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
            
            // TWO-PHASE hover detection:
            // Phase 1 (collapsed): tiny activation zone right at the physical notch
            // Phase 2 (expanded): wider area covering the full notch content so user can interact
            let isInside: Bool
            if self.isHovering {
                // Already expanded — use the full window frame + 50pt buffer above screen edge
                let expandedArea = NSRect(
                    x: window.frame.origin.x,
                    y: window.frame.origin.y,
                    width: window.frame.width,
                    height: window.frame.height + 50 // extend above maxY for bezel-pinned cursor
                )
                isInside = expandedArea.contains(mouseLoc)
            } else {
                // Collapsed — tiny activation strip centered on the notch
                let activationHeight: CGFloat = 10
                let activationArea = NSRect(
                    x: screenRect.midX - activationWidth / 2,
                    y: screenRect.maxY - activationHeight,
                    width: activationWidth,
                    height: activationHeight + 50 // extend above screen top for bezel
                )
                isInside = activationArea.contains(mouseLoc)
            }
            
            // If the state needs to change, debounce it
            if isInside != self.isHovering {
                self.hoverTask?.cancel()
                
                let workItem = DispatchWorkItem {
                    self.isHovering = isInside
                    window.ignoresMouseEvents = !isInside
                }
                
                // Fast open, slow close.
                let delay = isInside ? expandDelaySetting : collapseDelaySetting
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
