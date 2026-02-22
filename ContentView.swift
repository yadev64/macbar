import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var hoverObserver: HoverObserver
    @State private var isTargeted: Bool = false
    @State private var draggedItemName: String? = nil
    
    @AppStorage("leftModulesList") private var leftModules: [String] = ["Media"]
    @AppStorage("rightModulesList") private var rightModules: [String] = ["Clock"]
    @AppStorage("notchWidth") private var notchWidth: Double = 600.0
    
    // Dynamic width calculation
    private var dynamicWidth: CGFloat {
        let baseSpacing: CGFloat = 80 // Base margins + Settings Cog space
        let moduleWidth: CGFloat = 160 // Estimate for average module width
        let totalModules = CGFloat(leftModules.count + rightModules.count)
        return totalModules > 0 ? baseSpacing + (totalModules * moduleWidth) : 200
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Content
                if hoverObserver.isHovering {
                    HStack(spacing: 20) {
                        
                        // LEFT MODULES
                        ForEach(leftModules, id: \.self) { mod in
                            buildModule(name: mod)
                                .id(mod)
                        }
                        
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
                        
                        // RIGHT MODULES (Or Drop Shelf if dragging)
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
                            ForEach(rightModules.reversed(), id: \.self) { mod in
                                buildModule(name: mod)
                                    .id(mod)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Emulate physical notch base width
                    Color.clear
                }
            }
            .frame(width: hoverObserver.isHovering ? dynamicWidth : 200, 
                   height: hoverObserver.isHovering ? 86 : 32)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black)
                    // Push the shape upwards so top corners render off-screen, giving square top corners
                    .padding(.top, -20) 
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
                    .padding(.top, -20)
            )
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
        AppDelegate.shared.openSettings()
    }
}
