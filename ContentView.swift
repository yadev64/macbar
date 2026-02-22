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
        let baseSpacing: CGFloat = 50 // Base margins + center time space
        
        let allModules = leftModules + rightModules
        var totalModuleWidths: CGFloat = 0
        
        for mod in allModules {
            switch mod {
            case "Clock": totalModuleWidths += 160
            case "Media": totalModuleWidths += 240
            case "Battery": totalModuleWidths += 130
            case "AirDrop": totalModuleWidths += 150
            case "Calendar": totalModuleWidths += 180
            case "Weather": totalModuleWidths += 190
            case "CPU": totalModuleWidths += 140
            case "RAM": totalModuleWidths += 150
            case "Notes": totalModuleWidths += 150
            case "Reminders": totalModuleWidths += 160
            case "AirPods": totalModuleWidths += 160
            case "Screen Time": totalModuleWidths += 160
            case "Storage": totalModuleWidths += 160
            case "Network": totalModuleWidths += 210
            default: totalModuleWidths += 120 // Fallback
            }
        }
        
        // Add 14pt for spacing gaps, accounting for the center time as an extra node
        let calculated = baseSpacing + totalModuleWidths + CGFloat(allModules.count * 14) 
        return allModules.isEmpty ? 200 : calculated
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Content
                if hoverObserver.isHovering {
                    HStack(spacing: 14) {
                        
                        // LEFT MODULES
                        ForEach(leftModules, id: \.self) { mod in
                            buildModule(name: mod)
                                .id(mod)
                        }
                        
                        // CENTER TIME
                        Text(Date(), style: .time)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                        
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
                   height: hoverObserver.isHovering ? 86 : 16)
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
