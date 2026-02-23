import SwiftUI

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Element].self, from: data) else {
            return nil
        }
        self = decoded
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}

// MARK: - Module info helper
struct ModuleInfo {
    let name: String
    let icon: String
    let color: Color
    let description: String
    
    static let all: [ModuleInfo] = [
        ModuleInfo(name: "Media", icon: "music.note.list", color: .purple, description: "System-wide Now Playing"),
        ModuleInfo(name: "Spotify", icon: "music.note", color: .green, description: "Spotify controls"),
        ModuleInfo(name: "Calendar", icon: "calendar", color: .red, description: "Date & upcoming events"),
        ModuleInfo(name: "Weather", icon: "cloud.sun.fill", color: .cyan, description: "Current conditions"),
        ModuleInfo(name: "CPU", icon: "cpu", color: .green, description: "CPU usage"),
        ModuleInfo(name: "RAM", icon: "memorychip", color: .purple, description: "Memory usage"),
        ModuleInfo(name: "Battery", icon: "battery.75percent", color: .green, description: "Battery level"),
        ModuleInfo(name: "Clock", icon: "clock.fill", color: .orange, description: "Current time"),
        ModuleInfo(name: "Storage", icon: "internaldrive", color: .gray, description: "Disk space"),
        ModuleInfo(name: "Network", icon: "network", color: .cyan, description: "Wi-Fi network"),
        ModuleInfo(name: "AirDrop", icon: "airdrop", color: .blue, description: "Quick AirDrop"),
        ModuleInfo(name: "Notes", icon: "note.text", color: .yellow, description: "Recent note"),
        ModuleInfo(name: "Reminders", icon: "list.bullet.circle.fill", color: .orange, description: "Next reminder"),
        ModuleInfo(name: "AirPods", icon: "airpodspro", color: .white, description: "AirPods battery"),
        ModuleInfo(name: "Screen Time", icon: "hourglass", color: .indigo, description: "Daily screen time"),
    ]
    
    static func info(for name: String) -> ModuleInfo? {
        all.first { $0.name == name }
    }
}

// MARK: - Main Settings View
struct SettingsView: View {
    @State private var selection: String? = "General"
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(selection: $selection) {
                NavigationLink(destination: GeneralTab(), tag: "General", selection: $selection) {
                    Label("General", systemImage: "gearshape")
                }
                NavigationLink(destination: WidgetsTab(), tag: "Widgets", selection: $selection) {
                    Label("Widgets", systemImage: "square.grid.2x2")
                }
                NavigationLink(destination: NotchTab(), tag: "Notch", selection: $selection) {
                    Label("Notch", systemImage: "rectangle.topthird.inset.filled")
                }
                NavigationLink(destination: AppearanceTab(), tag: "Appearance", selection: $selection) {
                    Label("Appearance", systemImage: "paintbrush")
                }
                NavigationLink(destination: AboutTab(), tag: "About", selection: $selection) {
                    Label("About", systemImage: "info.circle")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 160)
            
            // Default detail view
            GeneralTab()
        }
        .frame(width: 640, height: 480)
    }
}

// MARK: - General Tab
struct GeneralTab: View {
    @AppStorage("showClock") private var showClock = true
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Show clock in expanded bar", isOn: $showClock)
                Toggle("Launch macbar at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
            } header: {
                Label("Startup", systemImage: "power")
            }
            
            Section {
                HStack {
                    Text("Reset all settings")
                    Spacer()
                    Button("Reset") {
                        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.auto.macbar")
                    }
                    .foregroundColor(.red)
                }
            } header: {
                Label("Advanced", systemImage: "wrench.and.screwdriver")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        // Use SMLoginItemSetEnabled or launchctl for proper login item management
        let script = enabled
            ? "tell application \"System Events\" to make login item at end with properties {path:\"/Users/\\(NSUserName())/Antigravity/git/macbar/macbar.app\", hidden:false}"
            : "tell application \"System Events\" to delete login item \"macbar\""
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }
}

// MARK: - Widgets Tab
struct WidgetsTab: View {
    @AppStorage("leftModulesListV2") private var leftModules: [String] = ["CPU", "RAM", "Storage"]
    @AppStorage("rightModulesListV2") private var rightModules: [String] = ["Calendar", "Media", "Weather"]
    
    private var usedModules: Set<String> {
        Set(leftModules + rightModules)
    }
    
    private var availableModules: [ModuleInfo] {
        ModuleInfo.all.filter { !usedModules.contains($0.name) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Left side
                ModuleListSection(
                    title: "Left Side",
                    modules: $leftModules,
                    maxCount: 4,
                    available: availableModules
                )
                
                Divider()
                
                // Right side
                ModuleListSection(
                    title: "Right Side",
                    modules: $rightModules,
                    maxCount: 4,
                    available: availableModules
                )
            }
            .padding()
            
            Divider()
            
            // Available widgets pool
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Widgets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if availableModules.isEmpty {
                    Text("All widgets are in use")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 8)
                    ], spacing: 8) {
                        ForEach(availableModules, id: \.name) { mod in
                            WidgetPoolItem(module: mod) {
                                // Add to whichever side has fewer
                                if leftModules.count <= rightModules.count && leftModules.count < 4 {
                                    leftModules.append(mod.name)
                                } else if rightModules.count < 4 {
                                    rightModules.append(mod.name)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ModuleListSection: View {
    let title: String
    @Binding var modules: [String]
    let maxCount: Int
    let available: [ModuleInfo]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(modules.count)/\(maxCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
            
            List {
                ForEach(modules, id: \.self) { mod in
                    HStack(spacing: 8) {
                        if let info = ModuleInfo.info(for: mod) {
                            Image(systemName: info.icon)
                                .foregroundColor(info.color)
                                .frame(width: 20)
                        }
                        Text(mod)
                            .font(.system(size: 13))
                        Spacer()
                        Button(action: {
                            if let idx = modules.firstIndex(of: mod) {
                                modules.remove(at: idx)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 2)
                }
                .onMove { from, to in
                    modules.move(fromOffsets: from, toOffset: to)
                }
            }
            .listStyle(.plain)
            .frame(height: 160)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            
            if modules.count < maxCount && !available.isEmpty {
                Menu {
                    ForEach(available, id: \.name) { mod in
                        Button(action: { modules.append(mod.name) }) {
                            Label(mod.name, systemImage: mod.icon)
                        }
                    }
                } label: {
                    Label("Add Widget", systemImage: "plus.circle.fill")
                        .font(.system(size: 12))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct WidgetPoolItem: View {
    let module: ModuleInfo
    let onAdd: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 4) {
                Image(systemName: module.icon)
                    .foregroundColor(module.color)
                    .font(.system(size: 16))
                Text(module.name)
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
            )
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { h in isHovering = h }
    }
}

// MARK: - Notch Behavior Tab
struct NotchTab: View {
    @AppStorage("activationWidth") private var activationWidth: Double = 200
    @AppStorage("collapseDelay") private var collapseDelay: Double = 0.3
    @AppStorage("expandDelay") private var expandDelay: Double = 0.05
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Activation Zone Width")
                        Spacer()
                        Text("\(Int(activationWidth))pt")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $activationWidth, in: 80...500, step: 10)
                    Text("How wide the invisible hover target is when the notch is collapsed.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Expand Delay")
                        Spacer()
                        Text("\(expandDelay, specifier: "%.2f")s")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $expandDelay, in: 0.01...0.5, step: 0.01)
                    Text("How quickly the notch expands when you hover over it.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Collapse Delay")
                        Spacer()
                        Text("\(collapseDelay, specifier: "%.1f")s")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $collapseDelay, in: 0.1...2.0, step: 0.1)
                    Text("How long the notch stays open after your mouse leaves.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } header: {
                Label("Hover Behavior", systemImage: "cursorarrow.motionlines")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Tab
struct AppearanceTab: View {
    @AppStorage("barHeight") private var barHeight: Double = 85
    @AppStorage("barCornerRadius") private var barCornerRadius: Double = 20
    @AppStorage("barOpacity") private var barOpacity: Double = 95
    @AppStorage("showStatsBar") private var showStatsBar: Bool = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Show Stats Bar", isOn: $showStatsBar)
                Text("Adds a compact row of CPU, RAM, Storage, Battery, and Date above your widgets.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } header: {
                Label("Stats Bar", systemImage: "chart.bar")
            }
            
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Bar Height")
                        Spacer()
                        Text("\(Int(barHeight))pt")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $barHeight, in: 50...150, step: 5)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text("\(Int(barCornerRadius))pt")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $barCornerRadius, in: 0...40, step: 1)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Background Opacity")
                        Spacer()
                        Text("\(Int(barOpacity))%")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $barOpacity, in: 50...100, step: 5)
                }
            } header: {
                Label("Expanded Bar", systemImage: "rectangle.topthird.inset.filled")
            }
            
            Section {
                VStack(spacing: 8) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        // Background simulating macOS desktop
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.15, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.2, blue: 0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 0) {
                            // The notch preview bar
                            RoundedRectangle(cornerRadius: CGFloat(barCornerRadius))
                                .fill(Color.black.opacity(barOpacity / 100))
                                .frame(height: max(CGFloat(barHeight) * 0.5, 28))
                                .overlay(
                                    HStack(spacing: 6) {
                                        Circle().fill(.green.opacity(0.7)).frame(width: 6, height: 6)
                                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.25)).frame(width: 30, height: 5)
                                        Spacer()
                                        Text("12:45")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.5))
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 2).fill(.white.opacity(0.25)).frame(width: 30, height: 5)
                                        Circle().fill(.cyan.opacity(0.7)).frame(width: 6, height: 6)
                                    }
                                    .padding(.horizontal, 12)
                                )
                                .padding(.horizontal, 20)
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .frame(height: 80)
                    .animation(.easeInOut(duration: 0.2), value: barHeight)
                    .animation(.easeInOut(duration: 0.2), value: barCornerRadius)
                    .animation(.easeInOut(duration: 0.2), value: barOpacity)
                }
                .padding(.vertical, 4)
            } header: {
                Label("Live Preview", systemImage: "eye")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - About Tab
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "rectangle.topthird.inset.filled")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("macbar")
                .font(.system(size: 24, weight: .bold))
            
            Text("Your Mac's notch just got superpowers.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            Divider().padding(.horizontal, 40)
            
            VStack(spacing: 6) {
                Text("Built using Google Antigravity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.caption)
            }
            
            Spacer()
            
            Text("Made with ♥ and an unreasonable amount of AppleScript")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
