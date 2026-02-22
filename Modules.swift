import SwiftUI
import IOKit.ps

struct BatteryModule: View {
    @State private var batteryLevel: Int = 100
    @State private var isCharging: Bool = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Image(systemName: isCharging ? "battery.100.bolt" : getBatteryIcon(level: batteryLevel))
                .foregroundColor(isCharging ? .green : .white)
                .font(.system(size: 20))
            VStack(alignment: .leading) {
                Text("Battery")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("\(batteryLevel)%")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .onAppear(perform: updateBatteryInfo)
        .onReceive(timer) { _ in updateBatteryInfo() }
    }
    
    private func getBatteryIcon(level: Int) -> String {
        switch level {
        case 0...20: return "battery.25"
        case 21...50: return "battery.50"
        case 51...80: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private func updateBatteryInfo() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for ps in sources {
            let info = IOPSGetPowerSourceDescription(snapshot, ps).takeUnretainedValue() as! [String: Any]
            
            if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                batteryLevel = capacity
            }
            if let state = info[kIOPSPowerSourceStateKey] as? String {
                isCharging = (state == kIOPSACPowerValue)
            }
        }
    }
}

struct ClockModule: View {
    @State private var currentDate = Date()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: -2) {
                Text(currentDate, style: .time)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(currentDate, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onReceive(timer) { input in
            currentDate = input
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }
}

struct MediaModule: View {
    @State private var trackName: String = "Not Playing"
    @State private var artistName: String = ""
    @State private var isHovering = false
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Button(action: {
            // Optional: action for clicking media (e.g. open Spotify)
            let script = "tell application \"Spotify\" to activate"
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(.purple)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text(artistName.isEmpty ? "Media" : artistName)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    Text(trackName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 160, alignment: .leading) // Constrain width so it doesn't break formatting on long song titles
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear(perform: updateMediaInfo)
        .onReceive(timer) { _ in updateMediaInfo() }
    }
    
    private func updateMediaInfo() {
        // Basic AppleScript query for Spotify
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    return name of current track & "|||" & artist of current track
                end if
            end tell
        end if
        return "Not Playing|||"
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let result = appleScript.executeAndReturnError(&error)
            if let output = result.stringValue {
                let parts = output.components(separatedBy: "|||")
                if parts.count >= 2 {
                    self.trackName = parts[0]
                    self.artistName = parts[1]
                }
            }
        }
    }
}
