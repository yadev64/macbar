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
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        fetchAllData()
        startTimers()
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
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            task.arguments = ["-s", "https://wttr.in/?format=\"%t+%C\""]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let cleaned = output.trimmingCharacters(in: CharacterSet(charactersIn: "\"\n\r "))
                DispatchQueue.main.async {
                    self.weatherData = cleaned
                }
            } else {
                DispatchQueue.main.async {
                    self.weatherData = "N/A"
                }
            }
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
                    if player state is playing then
                        return name of current track & "|||" & artist of current track
                    end if
                end tell
            end if
            return "Not Playing|||"
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
                if parts.count >= 2 {
                    DispatchQueue.main.async {
                        self.mediaTrack = parts[0]
                        self.mediaArtist = parts[1]
                    }
                }
            }
        }
    }
}
