import SwiftUI

struct AirDropModule: View {
    @State private var isHovering = false
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["/System/Library/CoreServices/Finder.app/Contents/Applications/AirDrop.app"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "airdrop")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("AirDrop")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Launcher")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct CalendarModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Calendar"]
            try? process.run()
            
            let script = """
            tell application "Calendar"
                activate
                switch view to month view
            end tell
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Calendar")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.calendarData)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct WeatherModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Weather"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Weather")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.weatherData)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 150, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct CPUModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Activity Monitor"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("CPU")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.cpuUsage)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 100, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct RAMModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Activity Monitor"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "memorychip")
                    .foregroundColor(.purple)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("RAM")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.ramUsage)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 100, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct NotesModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Notes"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Recent Note")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.recentNote)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct RemindersModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Reminders"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.circle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Reminders")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.nextReminder)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct AirPodsModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["x-apple.systempreferences:com.apple.preference.bluetooth"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "airpodspro")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("AirPods")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.airPodsData)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .frame(width: 120, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct ScreenTimeModule: View {
    @State private var isHovering = false
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["x-apple.systempreferences:com.apple.preference.screentime"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "hourglass")
                    .foregroundColor(.indigo)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Screen Time")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Launcher")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct StorageModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["/System/Volumes/Data"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "internaldrive")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Macintosh HD")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.freeStorage)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(6)
            .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in isHovering = hovering }
    }
}

struct NetworkModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        Button(action: {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["x-apple.systempreferences:com.apple.preference.network"]
            try? process.run()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .foregroundColor(.cyan)
                    .font(.system(size: 20))
                VStack(alignment: .leading) {
                    Text("Wi-Fi")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(data.networkName)
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

struct MediaModule: View {
    @State private var isHovering = false
    @ObservedObject var data = WidgetDataManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            // Track info row — tap to open Spotify
            Button(action: {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-a", "Spotify"]
                try? process.run()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(data.mediaArtist.isEmpty ? "Media" : data.mediaArtist)
                            .font(.system(size: 9))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Text(data.mediaTrack)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Playback controls row
            HStack(spacing: 12) {
                Button(action: { data.sendSpotifyCommand("previous track") }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { data.sendSpotifyCommand("playpause") }) {
                    Image(systemName: data.isMediaPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { data.sendSpotifyCommand("next track") }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(width: 152)
        .padding(6)
        .background(isHovering ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in isHovering = hovering }
    }
}
