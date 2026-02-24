import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var hoverObserver: HoverObserver
    @State private var isTargeted: Bool = false
    @State private var draggedItemName: String? = nil
    
    @AppStorage("leftModulesListV2") private var leftModules: [String] = ["Screen Time", "Media", "Notes"]
    @AppStorage("rightModulesListV2") private var rightModules: [String] = ["Weather", "Calendar"]
    @AppStorage("aestheticWidgets") private var aestheticWidgets: [String] = ["Media", "Calendar", "System"]
    @AppStorage("aestheticMode") private var aestheticMode: Bool = false
    @AppStorage("notchWidth") private var notchWidth: Double = 600.0
    @AppStorage("barHeight") private var barHeight: Double = 120
    @AppStorage("barCornerRadius") private var barCornerRadius: Double = 20
    @AppStorage("barOpacity") private var barOpacity: Double = 100
    @AppStorage("showClock") private var showClock: Bool = true
    @AppStorage("showStatsBar") private var showStatsBar: Bool = true
    
    // Dynamic width calculation
    private var dynamicWidth: CGFloat {
        let hStackPadding: CGFloat = 50 // .padding(.horizontal, 25)
        let timeWidth: CGFloat = showClock ? 85 : 0
        let hStackSpacing: CGFloat = 16 // Gap
        let minStatsWidth: CGFloat = (showStatsBar && !aestheticMode) ? 500 : 160
        
        if aestheticMode {
            // Aesthetic mode width: sum of chosen aesthetic widgets with new spacious ratios
            var totalAestheticWidth: CGFloat = 0
            for widget in aestheticWidgets {
                switch widget {
                case "Media": totalAestheticWidth += max(CGFloat(barHeight * 2.8), 300)
                case "Calendar": totalAestheticWidth += max(CGFloat(barHeight * 4.0), 380)
                case "System": totalAestheticWidth += max(CGFloat(barHeight * 1.6), 160)
                default: break
                }
            }
            
            // Add padding (sides + icon toggle) and spacing
            let padding: CGFloat = 16 // 8 on each side
            let spacing = CGFloat(max(0, aestheticWidgets.count - 1)) * 16
            let calculated = totalAestheticWidth + padding + spacing
            
            return aestheticWidgets.isEmpty ? minStatsWidth : max(calculated, minStatsWidth)
            
        } else {
            // Utility mode width (legacy)
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
            return allModules.isEmpty ? minStatsWidth : max(calculated, minStatsWidth)
        }
    }
    
    private var expandedHeight: CGFloat {
        if aestheticMode {
            return CGFloat(barHeight) + 42 // 28pt control bar + 6pt top padding + 8pt widget vertical padding
        } else {
            return showStatsBar ? CGFloat(barHeight) + 22 : CGFloat(barHeight)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Content
                if hoverObserver.isHovering {
                    VStack(spacing: 0) {
                        // TOP ROW (Controls or Stats)
                        if aestheticMode {
                            // Dedicated Top Control Bar for Aesthetic Mode
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        aestheticMode.toggle()
                                        if aestheticMode {
                                            barHeight = 130
                                        }
                                    }
                                }) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(Color.accentColor) // Highlighted state
                                        .font(.system(size: 14))
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.leading, 16)
                                
                                Spacer()
                                
                                Button(action: { openSettings() }) {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundColor(.gray.opacity(0.8))
                                        .font(.system(size: 13))
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.trailing, 16)
                            }
                            .frame(height: 28) // Same height logic as StatsBar
                            .padding(.top, 6)
                            
                        } else if showStatsBar {
                            StatsBarView()
                                .padding(.top, 6)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 3)
                        }
                        
                        // MAIN WIDGET ROW
                        if aestheticMode {
                            // AESTHETIC LAYOUT
                            HStack(spacing: 16) {
                                ForEach(aestheticWidgets, id: \.self) { mod in
                                    buildAestheticModule(name: mod)
                                }
                            }
                            .padding(.horizontal, 8) // Snug to edges
                            .padding(.vertical, 4) // 4px padding around widgets
                        } else {
                            // UTILITY LAYOUT
                            HStack(spacing: 16) {
                                // LEFT MODULES
                                ForEach(leftModules, id: \.self) { mod in
                                    buildModule(name: mod)
                                        .id(mod)
                                }
                                
                                // CENTER TIME (only if stats bar is off — otherwise time is in the stats bar)
                                if showClock && !showStatsBar {
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
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                    
                    // TOP LEFT AND RIGHT BUTTONS (Utility Mode Overlays)
                    if !aestheticMode {
                        // TOP LEFT TAB TOGGLE BUTTON
                        VStack {
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        aestheticMode.toggle()
                                        if aestheticMode {
                                            barHeight = 130
                                        }
                                    }
                                }) {
                                    Image(systemName: "rectangle.grid.3x2.fill")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .font(.system(size: 14))
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 4)
                                .padding(.leading, 12)
                                Spacer()
                            }
                            Spacer()
                        }
                        .transition(.opacity)
                        
                        // TOP RIGHT SETTINGS BUTTON
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { openSettings() }) {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .font(.system(size: 12))
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 4)
                                .padding(.trailing, 8)
                            }
                            Spacer()
                        }
                        .transition(.opacity)
                    }
                } else {
                    // Emulate physical notch base width
                    Color.clear
                }
            }
            .frame(width: hoverObserver.isHovering ? dynamicWidth : 160, 
                   height: hoverObserver.isHovering ? expandedHeight : 16)
            .background(
                RoundedRectangle(cornerRadius: CGFloat(barCornerRadius), style: .continuous)
                    .fill(Color.black.opacity(barOpacity / 100))
                    .padding(.top, -40) 
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(barCornerRadius), style: .continuous)
                    .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
                    .padding(.top, -40)
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: hoverObserver.isHovering)
            
            // Push everything to the top of the 120pt high window
            Spacer(minLength: 0)
        }
        // Frame the entire VStack (safe area + dynamic content) using a wider 2800pt canvas
        .frame(width: 2800, height: 180, alignment: .top)
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
    
    @ViewBuilder
    func buildAestheticModule(name: String) -> some View {
        switch name {
        case "Media":
            AestheticMediaWidget()
        case "Calendar":
            AestheticCalendarWidget()
        case "System":
            AestheticSystemWidget()
        default:
            EmptyView()
        }
    }
    
    private func openSettings() {
        AppDelegate.shared.openSettings()
    }
}
