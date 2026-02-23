import Foundation
import Combine
import AppKit

class WidgetDataManager: ObservableObject {
    static let shared = WidgetDataManager()
    
    @Published var calendarData: String = "Fetching..."
    @Published var weatherData: String = "Fetching..."
    @Published var cpuUsage: String = "0%"
    @Published var ramUsage: String = "0 MB"
    @Published var recentNote: String = "Loading..."
    @Published var nextReminder: String = "All clear"
    @Published var airPodsData: String = "Disconnected"
    @Published var freeStorage: String = "Calculating..."
    @Published var networkName: String = "Searching..."
    @Published var mediaTrack: String = "Not Playing"
    @Published var mediaArtist: String = ""
    @Published var isMediaPlaying: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        fetchAllData()
        startTimers()
        
        // Re-fetch everything when waking from sleep (network may take a moment)
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Delay 5s to let Wi-Fi reconnect
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self?.fetchAllData()
            }
        }
    }
    
    func fetchAllData() {
        fetchCalendar()
        fetchWeather()
        fetchCPU()
        fetchRAM()
        fetchNote()
        fetchReminder()
        fetchAirPods()
        fetchStorage()
        fetchNetwork()
        fetchMedia()
    }
    
    private func startTimers() {
        Timer.publish(every: 60, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchCalendar() }.store(in: &cancellables)
        Timer.publish(every: 1800, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchWeather() }.store(in: &cancellables)
        // If weather shows N/A, retry every 30s until it succeeds
        Timer.publish(every: 30, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            if self?.weatherData == "N/A" || self?.weatherData == "Fetching..." {
                self?.fetchWeather()
            }
        }.store(in: &cancellables)
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchCPU() }.store(in: &cancellables)
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchRAM() }.store(in: &cancellables)
        Timer.publish(every: 60, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchNote() }.store(in: &cancellables)
        Timer.publish(every: 60, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchReminder() }.store(in: &cancellables)
        Timer.publish(every: 10, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchAirPods() }.store(in: &cancellables)
        Timer.publish(every: 60, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchStorage() }.store(in: &cancellables)
        Timer.publish(every: 5, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchNetwork() }.store(in: &cancellables)
        Timer.publish(every: 3, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.fetchMedia() }.store(in: &cancellables)
    }

    private func fetchCalendar() {
        DispatchQueue.main.async {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            self.calendarData = formatter.string(from: Date())
        }
    }

    private func fetchWeather() {
        DispatchQueue.global(qos: .background).async {
            // Step 1: Get location from ipinfo.io
            let locTask = Process()
            let locPipe = Pipe()
            locTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            locTask.arguments = ["-sf", "--max-time", "8", "https://ipinfo.io/loc"]
            locTask.standardOutput = locPipe
            try? locTask.run()
            locTask.waitUntilExit()
            
            let locData = locPipe.fileHandleForReading.readDataToEndOfFile()
            guard let locStr = String(data: locData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !locStr.isEmpty else {
                // Network not ready yet — don't overwrite with N/A, just leave current value
                return
            }
            
            let coords = locStr.components(separatedBy: ",")
            guard coords.count == 2 else { return }
            let lat = coords[0]
            let lon = coords[1]
            
            // Step 2: Fetch weather from Open-Meteo (free, no API key)
            let url = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&timezone=auto"
            let wxTask = Process()
            let wxPipe = Pipe()
            wxTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            wxTask.arguments = ["-sf", "--max-time", "8", url]
            wxTask.standardOutput = wxPipe
            try? wxTask.run()
            wxTask.waitUntilExit()
            
            let wxData = wxPipe.fileHandleForReading.readDataToEndOfFile()
            guard let wxStr = String(data: wxData, encoding: .utf8),
                  !wxStr.isEmpty else { return }
            
            // Minimal JSON parsing without Foundation.JSONSerialization overhead
            if let json = try? JSONSerialization.jsonObject(with: Data(wxStr.utf8)) as? [String: Any],
               let current = json["current"] as? [String: Any],
               let temp = current["temperature_2m"] as? Double,
               let code = current["weather_code"] as? Int {
                let condition = Self.weatherDescription(for: code)
                let display = String(format: "%.0f°C %@", temp, condition)
                DispatchQueue.main.async {
                    self.weatherData = display
                }
            }
        }
    }
    
    private static func weatherDescription(for code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1: return "Mostly Clear"
        case 2: return "Partly Cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 56, 57: return "Freezing Drizzle"
        case 61, 63, 65: return "Rainy"
        case 66, 67: return "Freezing Rain"
        case 71, 73, 75: return "Snowy"
        case 77: return "Snow Grains"
        case 80, 81, 82: return "Showers"
        case 85, 86: return "Snow Showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Hail Storm"
        default: return "—"
        }
    }

    private func fetchCPU() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/top")
            task.arguments = ["-l", "1", "-n", "0"]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if let range = output.range(of: "CPU usage: ") {
                    let sub = output[range.upperBound...]
                    if let end = sub.range(of: " idle") {
                        let final = String(sub[..<end.upperBound])
                        let components = final.components(separatedBy: ", ")
                        for comp in components {
                            if comp.contains("idle") {
                                let idleStr = comp.replacingOccurrences(of: "% idle", with: "").trimmingCharacters(in: .whitespaces)
                                if let idle = Double(idleStr) {
                                    let usage = Int(100.0 - idle)
                                    DispatchQueue.main.async {
                                        self.cpuUsage = "\(usage)%" // Escaped % is not needed in swift string interp without format specifiers
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func fetchRAM() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/top")
            task.arguments = ["-l", "1", "-n", "0"]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if let range = output.range(of: "PhysMem: ") {
                    let sub = output[range.upperBound...]
                    if let end = sub.range(of: " used") {
                        let final = String(sub[..<end.lowerBound])
                        DispatchQueue.main.async {
                            self.ramUsage = final + " Used"
                        }
                    }
                }
            }
        }
    }

    private func fetchNote() {
        DispatchQueue.global(qos: .background).async {
            let script = """
            tell application "Notes"
                if (count of notes) > 0 then
                    return name of note 1
                else
                    return "No Notes"
                end if
            end tell
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if let output = result.stringValue {
                    DispatchQueue.main.async { self.recentNote = output }
                }
            }
        }
    }

    private func fetchReminder() {
        DispatchQueue.global(qos: .background).async {
            let script = """
            tell application "Reminders"
                set allReminders to reminders whose completed is false
                if (count of allReminders) > 0 then
                    return name of item 1 of allReminders
                else
                    return "All clear"
                end if
            end tell
            """
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let result = appleScript.executeAndReturnError(&error)
                if let output = result.stringValue {
                    DispatchQueue.main.async { self.nextReminder = output }
                }
            }
        }
    }

    private func fetchAirPods() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            task.arguments = ["SPBluetoothDataType"]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                var foundDevice = ""
                var foundBattery = ""
                for (index, line) in lines.enumerated() {
                    if line.contains("Battery Level: ") {
                        let batteryStr = line.replacingOccurrences(of: "Battery Level: ", with: "").trimmingCharacters(in: .whitespaces)
                        var backIndex = index - 1
                        while backIndex >= 0 {
                            if !lines[backIndex].contains(":") && !lines[backIndex].trimmingCharacters(in: .whitespaces).isEmpty {
                                foundDevice = lines[backIndex].trimmingCharacters(in: .whitespaces)
                                foundBattery = batteryStr
                                break
                            } else if lines[backIndex].contains(":") && !lines[backIndex].hasPrefix(" ") {
                                foundDevice = lines[backIndex].replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
                                foundBattery = batteryStr
                                break
                            }
                            backIndex -= 1
                        }
                        if foundDevice.contains("AirPods") {
                            break
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if !foundBattery.isEmpty {
                        self.airPodsData = foundBattery.replacingOccurrences(of: "Battery Level: ", with: "")
                    } else {
                        self.airPodsData = "Disconnected"
                    }
                }
            }
        }
    }

    private func fetchStorage() {
        DispatchQueue.global(qos: .background).async {
            if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
               let freeSize = attributes[.systemFreeSize] as? NSNumber {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useGB, .useTB]
                formatter.countStyle = .file
                let formattedString = formatter.string(fromByteCount: freeSize.int64Value)
                DispatchQueue.main.async {
                    self.freeStorage = formattedString + " Free"
                }
            }
        }
    }

    private func fetchNetwork() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
            task.arguments = ["-getairportnetwork", "en0"]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if let range = output.range(of: "Current Wi-Fi Network: ") {
                    let sub = output[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.async { self.networkName = sub }
                } else if output.contains("Wi-Fi power is turned off") {
                    DispatchQueue.main.async { self.networkName = "Wi-Fi Off" }
                } else {
                    DispatchQueue.main.async { self.networkName = "Not Connected" }
                }
            }
        }
    }
    
    private func fetchMedia() {
        DispatchQueue.global(qos: .background).async {
            let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    set trackInfo to "Not Playing|||"
                    set playState to "paused"
                    if player state is playing then
                        set playState to "playing"
                    end if
                    if player state is playing or player state is paused then
                        set trackInfo to name of current track & "|||" & artist of current track
                    end if
                    return trackInfo & "|||" & playState
                end tell
            end if
            return "Not Playing||||||paused"
            """
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let clean = output.trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = clean.components(separatedBy: "|||")
                if parts.count >= 3 {
                    DispatchQueue.main.async {
                        self.mediaTrack = parts[0]
                        self.mediaArtist = parts[1]
                        self.isMediaPlaying = parts[2] == "playing"
                    }
                }
            }
        }
    }
    
    func sendSpotifyCommand(_ command: String) {
        DispatchQueue.global(qos: .background).async {
            let script = "tell application \"Spotify\" to \(command)"
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            try? task.run()
            task.waitUntilExit()
            // Re-fetch immediately to update UI
            self.fetchMedia()
        }
    }
}
