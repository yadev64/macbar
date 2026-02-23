
<img width="101" height="101" alt="icon" src="https://github.com/user-attachments/assets/e4a7959d-0543-4913-a5f5-4b9e50a88704" />

# macbar

**Your Mac's notch just got superpowers.**

macbar turns that boring camera cutout into a dynamic, expandable command center — packed with live widgets, media controls, and system stats. Think Dynamic Island, but for your Mac, and *actually useful*.

> Hover over the notch → it expands → you're in control. Move away → it disappears. Magic. ✨

---

## ✨ Features

- 🎯 **Notch-native** — lives right inside your Mac's notch, blending seamlessly with the hardware
- 🧲 **Hover to expand** — smart two-phase detection means it only activates when you *mean* it
- 📊 **Stats Bar** — a compact top row showing Time, Date, CPU, RAM, Storage, Battery — each clickable to open the relevant app
- 🎵 **Media controls** — system-wide now playing + Spotify with ⏮ ⏯ ⏭ controls
- 📊 **Live system stats** — CPU, RAM, Storage, Battery at a glance
- 🌤️ **Weather** — current conditions, no API key needed
- 📅 **Calendar** — today's date + next upcoming event
- ⏱️ **Screen Time** — active display time today, tracked via power events
- 🔋 **Battery** — percentage from `pmset`
- 🎧 **AirPods** — battery level for connected Bluetooth headphones
- 📝 **Notes & Reminders** — latest note and next incomplete task
- 🌐 **Network** — current Wi-Fi network name
- 💾 **Storage** — free disk space remaining
- 🕐 **Live clock** — centered in the notch (moves to stats bar when enabled)
- ⚙️ **Sidebar settings** — macOS System Settings-style navigation with live notch preview
- 🔋 **Energy efficient** — zero background activity when collapsed; timers only run while expanded
- 🖥️ **Multi-monitor** — follows your cursor across displays
- ⚙️ **Fully customizable** — add, remove, reorder widgets from the settings panel
- 🚀 **Zero dependencies** — pure Swift + SwiftUI, no Xcode project needed

---

## 📸 What It Looks Like

When collapsed, macbar is invisible — it *is* your notch. Hover over it and it smoothly expands into a sleek bar showing your chosen widgets:

<img width="3024" height="1964" alt="ss" src="https://github.com/user-attachments/assets/039ab9c0-7961-4884-9404-5b6b1faea811" />

---

## 🚀 Getting Started

### Prerequisites

- macOS 13+ (Ventura or later)  
- A Mac with a notch (also works on non-notch Macs — the bar appears at the top center)
- Swift toolchain installed (comes with Xcode Command Line Tools)

### Build & Run

```bash
# Build the app
./build.sh

# Launch it!
open macbar.app
```

That's it. No Xcode project, no CocoaPods, no Swift Package Manager. Just `./build.sh` and go. 🏎️

### First Launch

macOS will ask for permissions the first time (Accessibility, Automation for Spotify/Notes/Calendar). Say yes — macbar needs these to talk to your apps.

---

## ⚙️ Customization

### Settings

Click the **⚙️ gear icon** in the expanded notch or use the **system tray icon** to open Settings. The settings window uses a familiar sidebar navigation:

| Tab | What you configure |
|-----|-------------------|
| **General** | Left & right module lists — add, remove, reorder widgets |
| **Appearance** | Bar height, corner radius, opacity, Stats Bar toggle |
| **Notch Behavior** | Activation width, expand/collapse delay timing |

### Stats Bar

Enable the **Stats Bar** in Appearance settings to get a compact top row inside the expanded notch:

`🕐 Time` · `📅 Date` · `🟢 CPU` · `🟣 RAM` · `⚫ Storage` · `🔋 Battery%`

Each item is **clickable** — tapping opens the relevant app (Calendar, Activity Monitor, Disk Utility, System Settings → Battery). When Stats Bar is enabled, the clock automatically moves from the main widget row to the stats bar.

### Available Widgets

| Widget | Shows | Click action |
|--------|-------|-------------|
| 🎵 **Media** | Now playing track + artist + ⏮⏯⏭ | Opens Spotify |
| 🔋 **Battery** | Battery percentage + charging icon | — |
| 📅 **Calendar** | Today's date + next event | Opens Calendar |
| 🌤️ **Weather** | Temperature + conditions | Opens Weather |
| 💻 **CPU** | Real-time CPU usage % | Opens Activity Monitor |
| 🧠 **RAM** | Physical memory used | Opens Activity Monitor |
| 📝 **Notes** | Most recently modified note | Opens Notes |
| ✅ **Reminders** | Next incomplete task | Opens Reminders |
| 🎧 **AirPods** | Bluetooth headphone battery | Opens Bluetooth settings |
| ⏱️ **Screen Time** | Active display time today | Opens Screen Time prefs |
| 💾 **Storage** | Free disk space | Opens Finder |
| 🌐 **Network** | Current Wi-Fi name | Opens Network settings |
| 📡 **AirDrop** | Quick launcher | Opens AirDrop |

### Default Layout

**Left side:** Screen Time → Media → Notes  
**Right side:** Weather → Calendar

The notch width **automatically adjusts** based on how many widgets you have — no manual sizing needed.

---

## 🔋 Energy Efficiency

macbar uses a **visibility-aware timer system** to minimize energy impact:

- **Collapsed (99% of the time):** Zero timers, zero process spawning, near-zero CPU usage
- **Expanded (on hover):** Instant full data refresh + live update timers start
- **On collapse:** All timers immediately cancelled

This means macbar idles at essentially **0% CPU** when you're not using it, and only wakes up the moment you hover over the notch.

| Data | Update interval (while expanded) |
|------|--------------------------------|
| CPU, RAM | Every 10 seconds |
| Spotify, Now Playing | Every 5 seconds |
| Network | Every 15 seconds |
| Calendar | Every 30 seconds |
| AirPods, Battery, Storage, Notes, Reminders | Every 60 seconds |

---

## 🔧 Building Your Own Widget

Want to add a custom widget? Here's the recipe:

### Step 1: Add Your Data Source

Open `WidgetDataManager.swift` and add a new `@Published` property:

```swift
@Published var myCustomData: String = "Loading..."
```

Add a fetch method using a background shell command:

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

Wire it up in `fetchAllData()` and `startVisibleTimers()`:

```swift
func fetchAllData() {
    // ... existing calls ...
    fetchMyCustomData()
}

private func startVisibleTimers() {
    // ... existing timers ...
    Timer.publish(every: 30, on: .main, in: .common)
        .autoconnect()
        .sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchMyCustomData()
        }
        .store(in: &visibleCancellables)
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
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "YourApp"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
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
            .frame(width: 130, alignment: .leading)
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

**`ContentView.swift`** — add to the module renderer and width map:

```swift
case "MyCustom": MyCustomModule()         // in the ForEach switch
case "MyCustom": totalModuleWidths += 142 // in dynamicWidth
```

**`SettingsView.swift`** — add to the available modules list:

```swift
let availableModules = ["Media", "Battery", ..., "MyCustom"]
```

### Step 4: Build & Test

```bash
./build.sh && open macbar.app
```

---

## 🏗️ Architecture

```
macbar/
├── macbarApp.swift              # App entry + AppDelegate + status bar menu
├── ContentView.swift            # Main notch UI + dynamic layout engine
├── HoverObserver.swift          # Two-phase mouse tracking (activation + interaction)
├── NotchWindowController.swift  # NSWindow setup (borderless, always-on-top, multi-monitor)
├── Modules.swift                # Core modules (Battery, Clock)
├── V5Modules.swift              # All functional widgets (14 modules) + Stats Bar
├── WidgetDataManager.swift      # Visibility-aware data cache (background fetching)
├── SettingsView.swift           # Sidebar settings UI with live preview
└── build.sh                     # One-line build script — no Xcode needed
```

### How It Works

1. **`NotchWindowController`** creates an invisible, borderless `NSWindow` at the top of your screen
2. **`HoverObserver`** uses two-phase detection:
   - *Collapsed*: tiny activation strip right at the notch
   - *Expanded*: full window frame for widget interaction
3. **`ContentView`** dynamically renders your chosen widgets, Stats Bar, and auto-calculates the perfect width
4. **`WidgetDataManager`** uses visibility-aware timers — zero work when collapsed, instant data on expand
5. Everything animates with SwiftUI spring animations for that buttery-smooth feel

---

## 📋 Version History

### v2.0 — The Stats Bar Update (Feb 2026)

**New Features**
- ✨ **Stats Bar** — compact top row showing Time, Date, CPU, RAM, Storage, Battery at a glance
- ✨ **Clickable stats** — each stats bar item opens its relevant app on click with hover highlight
- ✨ **Screen Time widget** — now shows actual active display time today (parsed from power events)
- ✨ **Battery in data manager** — real battery percentage via `pmset -g batt`
- ✨ **Sidebar settings** — replaced tab navigation with macOS System Settings-style sidebar

**Performance**
- ⚡ **99% energy reduction** — zero background timers when collapsed; all fetching only happens on expand
- ⚡ **Visibility-aware timers** — fast timers start on expand, instantly killed on collapse
- ⚡ **Reduced timer frequencies** — CPU/RAM every 10s (was 3s), Network every 15s (was 5s)

**Fixes**
- 🐛 Fixed Notes widget stuck on "Loading..." (switched from NSAppleScript to osascript Process)
- 🐛 Fixed Reminders widget same issue
- 🐛 Fixed notch clipping when Stats Bar is enabled (increased window height to 180pt)
- 🐛 Fixed live preview in Appearance settings (dark background, proper animation)
- 🐛 Fixed bar opacity default mismatch between settings and content view

### v1.0 — Initial Release

- 14 customizable widgets
- Hover-to-expand notch UI
- Drag-and-drop widget configuration
- System-wide media controls
- Multi-monitor support
- Zero-dependency build system

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

## ♥️ Credits

Built using [Google Antigravity](https://antigravity.google/).

If you like macbar, give it a ⭐ — it makes the notch happy.
