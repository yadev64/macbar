# 🖤 macbar

**Your Mac's notch just got superpowers.**

macbar turns that boring camera cutout into a dynamic, expandable command center — packed with live widgets, media controls, and system stats. Think Dynamic Island, but for your Mac, and *actually useful*.

> Hover over the notch → it expands → you're in control. Move away → it disappears. Magic. ✨

---

## ✨ Features

- 🎯 **Notch-native** — lives right inside your Mac's notch, blending seamlessly with the hardware
- 🧲 **Hover to expand** — smart two-phase detection means it only activates when you *mean* it
- 🎵 **Spotify controls** — see what's playing, skip tracks, play/pause — all from the notch
- 📊 **Live system stats** — CPU, RAM, Storage at a glance
- 🌤️ **Weather** — current conditions, no API key needed
- 📅 **Calendar** — your next event, always visible
- 🔋 **Battery** — percentage + charging status
- 🎧 **AirPods** — battery level for connected headphones
- 📝 **Notes & Reminders** — latest note and next task
- 🖥️ **Multi-monitor** — follows your cursor across displays
- ⚙️ **Fully customizable** — drag, drop, add, remove widgets from a settings panel
- 🕐 **Live clock** — centered in the notch, always ticking
- 🚀 **Zero dependencies** — pure Swift + SwiftUI, no Xcode project needed

---

## 📸 What It Looks Like

When collapsed, macbar is invisible — it *is* your notch. Hover over it and it smoothly expands into a sleek bar showing your chosen widgets:

```
┌─────────────────────────────────────────────────────┐
│  CPU 12%  │  RAM 8.2 GB  │  128 GB  │  12:45 PM  │  📅 Next: Standup  │  🎵 Artist - Song  ⏮ ⏯ ⏭  │  🌤 22°C Clear  │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- macOS 13+ (Ventura or later)  
- A Mac with a notch (also works on non-notch Macs — the bar appears at the top center)
- Swift toolchain installed (comes with Xcode Command Line Tools)

### Build & Run

```bash
# Clone the repo
git clone https://github.com/your-username/macbar.git
cd macbar

# Build the app
./build.sh

# Launch it!
open macbar.app
```

That's it. No Xcode project, no CocoaPods, no Swift Package Manager. Just `./build.sh` and go. 🏎️

### First Launch

macOS will ask for permissions the first time (Accessibility, Automation for Spotify/Calendar). Say yes — macbar needs these to talk to your apps.

---

## ⚙️ Customization

### Choosing Your Widgets

1. **Right-click** the macbar system tray icon (or click the ⚙️ gear icon in the expanded notch)
2. The **Settings** window opens
3. You'll see two lists: **Left Modules** and **Right Modules**
4. Use the **+ Add** button to pick from available widgets
5. Use the **🗑 Remove** button to delete widgets you don't want
6. Reorder by dragging items in the list
7. Changes apply **instantly** — no restart needed!

### Available Widgets

| Widget | What it does | Click action |
|--------|-------------|-------------|
| 🎵 **Media** | Now playing track + artist + ⏮⏯⏭ controls | Opens Spotify |
| 🔋 **Battery** | Battery percentage + charging icon | — |
| 🕐 **Clock** | Current date (e.g. "Mon, Jan 15") | — |
| 📡 **AirDrop** | Quick launcher | Opens AirDrop |
| 📅 **Calendar** | Next upcoming event today | Opens Calendar (month view) |
| 🌤️ **Weather** | Temperature + conditions | Opens Weather app |
| 💻 **CPU** | Real-time CPU usage % | Opens Activity Monitor |
| 🧠 **RAM** | Physical memory used | Opens Activity Monitor |
| 📝 **Notes** | Most recently modified note | Opens Notes |
| ✅ **Reminders** | Next incomplete task | Opens Reminders |
| 🎧 **AirPods** | Connected headphone battery | Opens Bluetooth settings |
| ⏳ **Screen Time** | Quick launcher | Opens Screen Time prefs |
| 💾 **Storage** | Free disk space | Opens Finder |
| 🌐 **Network** | Current Wi-Fi network name | Opens Network settings |

### Default Layout

**Left side:** CPU → RAM → Storage  
**Right side:** Calendar → Media → Weather

The notch width **automatically adjusts** based on how many widgets you have. Add more? It grows. Remove some? It shrinks. No manual sizing needed.

---

## 🔧 Building Your Own Widget

Want to add a custom widget? It's surprisingly easy. Here's the recipe:

### Step 1: Add Your Data Source

Open `WidgetDataManager.swift` and add a new `@Published` property:

```swift
@Published var myCustomData: String = "Loading..."
```

Add a fetch method using a background shell command or API call:

```swift
private func fetchMyCustomData() {
    DispatchQueue.global(qos: .background).async {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/some-command")
        task.arguments = ["--some-flag"]
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.myCustomData = output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
}
```

Wire it up in `fetchAllData()` and `startTimers()`:

```swift
func fetchAllData() {
    // ... existing calls ...
    fetchMyCustomData()
}

private func startTimers() {
    // ... existing timers ...
    Timer.publish(every: 30, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in self?.fetchMyCustomData() }
        .store(in: &cancellables)
}
```

### Step 2: Create the SwiftUI View

Open `V5Modules.swift` and add your widget struct:

```swift
struct MyCustomModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            // What happens when the user clicks your widget
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "YourApp"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")       // Pick any SF Symbol
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("My Widget")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.myCustomData)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 130, alignment: .leading)  // Adjust width as needed
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}
```

### Step 3: Register It

Three quick additions:

**`ContentView.swift`** — add it to the module renderer and width map:

```swift
// In the switch inside the ForEach:
case "MyCustom": MyCustomModule()

// In the dynamicWidth switch:
case "MyCustom": totalModuleWidths += 142  // match your frame width + padding
```

**`SettingsView.swift`** — add it to the available modules list:

```swift
let availableModules = ["Media", "Battery", ..., "MyCustom"]
```

### Step 4: Build & Test

```bash
./build.sh && open macbar.app
```

Your new widget will appear in the Settings panel, ready to be added to either side of the notch. 🎉

---

## 🏗️ Architecture

```
macbar/
├── macbarApp.swift              # App entry point + AppDelegate
├── ContentView.swift            # Main notch UI + dynamic layout engine
├── HoverObserver.swift          # Two-phase mouse tracking (activation + interaction)
├── NotchWindowController.swift  # NSWindow setup (borderless, always-on-top, multi-monitor)
├── Modules.swift                # Core modules (Battery, Clock)
├── V5Modules.swift              # All functional widgets (14 modules)
├── WidgetDataManager.swift      # Central data cache (background fetching via shell/AppleScript)
├── SettingsView.swift           # Drag-and-drop module configuration UI
└── build.sh                     # One-line build script — no Xcode needed
```

### How It Works

1. **`NotchWindowController`** creates an invisible, borderless `NSWindow` at the top of your screen
2. **`HoverObserver`** uses two-phase detection:
   - *Collapsed*: tiny 200×10pt activation strip right at the notch
   - *Expanded*: full window frame for widget interaction
3. **`ContentView`** dynamically renders your chosen widgets and auto-calculates the perfect width
4. **`WidgetDataManager`** runs background timers fetching live data (CPU, weather, Spotify, etc.) so widgets display instantly — no loading spinners
5. Everything animates with SwiftUI spring animations for that buttery-smooth feel

---

## 🤝 Contributing

Found a bug? Want to add a wild new widget? PRs are absolutely welcome!

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing-widget`)
3. Follow the [Building Your Own Widget](#-building-your-own-widget) guide
4. Commit your changes (`git commit -m 'Add amazing widget'`)
5. Push to the branch (`git push origin feature/amazing-widget`)
6. Open a Pull Request

---

## 📜 License

MIT License — do whatever you want with it. See [LICENSE](LICENSE) for the full text.

---

## 💜 Credits

Built with love, Swift, and an unreasonable amount of AppleScript.

If you like macbar, give it a ⭐ — it makes the notch happy.
