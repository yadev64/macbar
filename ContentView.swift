import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var hoverObserver: HoverObserver
    @State private var isTargeted: Bool = false
    @State private var draggedItemName: String? = nil
    
    @AppStorage("leftModulesListV2") private var leftModules: [String] = ["CPU", "RAM", "Storage"]
    @AppStorage("rightModulesListV2") private var rightModules: [String] = ["Calendar", "Media", "Weather"]
    @AppStorage("notchWidth") private var notchWidth: Double = 600.0
    @AppStorage("barHeight") private var barHeight: Double = 110
    @AppStorage("barCornerRadius") private var barCornerRadius: Double = 20
    @AppStorage("barOpacity") private var barOpacity: Double = 100
    @AppStorage("showClock") private var showClock: Bool = true
    
    // Dynamic width calculation
    private var dynamicWidth: CGFloat {
        let hStackPadding: CGFloat = 50 // .padding(.horizontal, 25)
        let timeWidth: CGFloat = 85 // generous for different time formats
        let hStackSpacing: CGFloat = 16 // Gap
        
        let allModules = leftModules + rightModules
        var totalModuleWidths: CGFloat = 0
        
        for mod in allModules {
            switch mod {
            case "Clock": totalModuleWidths += 130
            case "Media": totalModuleWidths += 172
            case "Spotify": totalModuleWidths += 172
            case "Battery": totalModuleWidths += 95
            case "AirDrop": totalModuleWidths += 110
            case "Calendar": totalModuleWidths += 152
            case "Weather": totalModuleWidths += 162
            case "CPU": totalModuleWidths += 112
            case "RAM": totalModuleWidths += 112
            case "Notes": totalModuleWidths += 152
            case "Reminders": totalModuleWidths += 152
            case "AirPods": totalModuleWidths += 132
            case "Screen Time": totalModuleWidths += 120
            case "Storage": totalModuleWidths += 152
            case "Network": totalModuleWidths += 142
            default: totalModuleWidths += 120 // Fallback
            }
        }
        
        // Gap for time is 2 gaps if time is there. Total elements = count + 1. So gaps = count.
        let calculated = hStackPadding + timeWidth + totalModuleWidths + (CGFloat(allModules.count) * hStackSpacing)
        return allModules.isEmpty ? 160 : calculated
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Content
                if hoverObserver.isHovering {
                    HStack(spacing: 16) {
                        
                        // LEFT MODULES
                        ForEach(leftModules, id: \.self) { mod in
                            buildModule(name: mod)
                                .id(mod)
                        }
                        
                        // CENTER TIME
                        if showClock {
                            Text(Date(), style: .time)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                        }
                        
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
                    
                    // TOP RIGHT SETTINGS BUTTON
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { openSettings() }) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.system(size: 12))
                                    .padding(8) // Give it a slightly larger hit area
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                            .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                    .transition(.opacity)
                } else {
                    // Emulate physical notch base width
                    Color.clear
                }
            }
            .frame(width: hoverObserver.isHovering ? dynamicWidth : 160, 
                   height: hoverObserver.isHovering ? CGFloat(barHeight) : 16)
            .background(
                RoundedRectangle(cornerRadius: CGFloat(barCornerRadius), style: .continuous)
                    .fill(Color.black.opacity(barOpacity / 100))
                    // Push the shape upwards so top corners render off-screen, giving square top corners
                    .padding(.top, -20) 
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(barCornerRadius), style: .continuous)
                    .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
                    .padding(.top, -20)
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: hoverObserver.isHovering)
            
            // Push everything to the top of the 120pt high window
            Spacer(minLength: 0)
        }
        // Frame the entire VStack (safe area + dynamic content) using a wider 2800pt canvas
        .frame(width: 2800, height: 120, alignment: .top)
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
        case "Spotify":
            SpotifyModule()
        case "AirDrop":
            AirDropModule()
        case "Calendar":
            CalendarModule()
        case "Weather":
            WeatherModule()
        case "CPU":
            CPUModule()
        case "RAM":
            RAMModule()
        case "Notes":
            NotesModule()
        case "Reminders":
            RemindersModule()
        case "AirPods":
            AirPodsModule()
        case "Screen Time":
            ScreenTimeModule()
        case "Storage":
            StorageModule()
        case "Network":
            NetworkModule()
        default:
            EmptyView()
        }
    }
    
    private func openSettings() {
        AppDelegate.shared.openSettings()
    }
}
