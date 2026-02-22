import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var hoverObserver: HoverObserver
    @State private var isTargeted: Bool = false
    @State private var draggedItemName: String? = nil
    
    @AppStorage("leftModule") private var leftModule: String = "Media"
    @AppStorage("rightModule") private var rightModule: String = "Clock"
    @AppStorage("notchWidth") private var notchWidth: Double = 600.0
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black)
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    
                // Content
                if hoverObserver.isHovering {
                    HStack(spacing: 20) {
                        
                        // LEFT MODULE
                        buildModule(name: leftModule)
                            .id(leftModule)
                        
                        Spacer()
                        
                        // CENTER SETTINGS BUTTON
                        Button(action: {
                            openSettings()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // RIGHT MODULE (Or Drop Shelf if dragging)
                        if isTargeted || draggedItemName != nil {
                            HStack {
                                if let iName = draggedItemName {
                                    Image(systemName: "doc.fill")
                                        .foregroundColor(.blue)
                                    Text(iName)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .frame(maxWidth: 80)
                                } else {
                                    Image(systemName: "tray.and.arrow.down")
                                        .foregroundColor(isTargeted ? .blue : .gray)
                                    Text("Drop Files Here")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        } else {
                            buildModule(name: rightModule)
                                .id(rightModule)
                        }
                    }
                    .padding(.horizontal, 25)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Emulate physical notch base width
                    Color.black
                }
            }
            .frame(width: hoverObserver.isHovering ? CGFloat(notchWidth) : 200, 
                   height: hoverObserver.isHovering ? 86 : 32)
            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: hoverObserver.isHovering)
            
            // Push everything to the top of the 120pt high window
            Spacer(minLength: 0)
        }
        // Frame the entire VStack (safe area + dynamic content)
        .frame(width: 800, height: 120, alignment: .top)
        // Ensure SwiftUI view respects safe area / borderless
        .edgesIgnoringSafeArea(.all)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            if let provider = providers.first {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                    if let data = urlData as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.draggedItemName = url.lastPathComponent
                        }
                    } else if let url = urlData as? URL {
                        DispatchQueue.main.async {
                            self.draggedItemName = url.lastPathComponent
                        }
                    }
                }
                return true
            }
            return false
        }
    }
    
    @ViewBuilder
    func buildModule(name: String) -> some View {
        switch name {
        case "Battery":
            BatteryModule()
        case "Clock":
            ClockModule()
        case "Media":
            MediaModule()
        case "WiFi":
            WifiModule()
        default:
            EmptyView()
        }
    }
    
    private func openSettings() {
        if #available(macOS 13.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
