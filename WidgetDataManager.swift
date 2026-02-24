import Foundation
import Combine
import AppKit
import EventKit

class WidgetDataManager: ObservableObject {
    static let shared = WidgetDataManager()
    
    @Published var calendarData: String = "Fetching..."
    @Published var calendarEvent: String = ""
    @Published var calendarEventTime: String = ""
    @Published var weatherData: String = "Fetching..."
    @Published var cpuUsage: String = "0%"
    @Published var ramUsage: String = "0 MB"
    @Published var recentNote: String = "Loading..."
    @Published var nextReminder: String = "All clear"
    @Published var airPodsData: String = "Disconnected"
    @Published var freeStorage: String = "Calculating..."
    @Published var networkName: String = "Searching..."
    @Published var batteryLevel: String = "–"
    @Published var screenTime: String = "–"
    @Published var mediaTrack: String = "Not Playing"
    @Published var mediaArtist: String = ""
    @Published var isMediaPlaying: Bool = false
    @Published var mediaSource: String = ""
    @Published var spotifyTrack: String = "Not Playing"
    @Published var spotifyArtist: String = ""
    @Published var isSpotifyPlaying: Bool = false
    
    // MARK: - Aesthetic Mode Data
    // Media
    @Published var mediaArtwork: NSImage? = nil
    @Published var mediaDuration: Double = 0
    @Published var mediaPosition: Double = 0
    @Published var mediaApp: String = ""
    
    // System
    @Published var networkUpSpeed: String = "0 KB/s"
    @Published var networkDownSpeed: String = "0 KB/s"
    @Published var customDiskRead: String = "0 KB/s"
    @Published var customDiskWrite: String = "0 KB/s"
    
    // Calendar
    struct CalendarEventInfo: Identifiable {
        let id = UUID()
        let title: String
        let startDate: Date
        let endDate: Date
        let color: NSColor
        let isAllDay: Bool
        let url: URL?
        let notes: String?
    }
    @Published var todayEvents: [CalendarEventInfo] = []
    @Published var selectedCalendarDate: Date = Date() {
        didSet {
            fetchAestheticCalendar()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let eventStore = EKEventStore()
    
    private init() {
        fetchAllData()
        
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
        fetchSpotify()
        fetchNowPlaying()
        fetchBattery()
        fetchScreenTime()
    }
    
    // MARK: - Energy optimization: only fetch when notch is visible
    var isVisible: Bool = false {
        didSet {
            if isVisible && !oldValue {
                // Just became visible — do an immediate refresh and start timers
                fetchAllData()
                startVisibleTimers()
            } else if !isVisible && oldValue {
                // Just collapsed — stop everything
                stopVisibleTimers()
            }
        }
    }
    
    private var visibleCancellables = Set<AnyCancellable>()
    
    private func startVisibleTimers() {
        stopVisibleTimers()
        // Fast-updating data (only while expanded)
        Timer.publish(every: 10, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchCPU()
            self?.fetchRAM()
        }.store(in: &visibleCancellables)
        
        // Very fast updates for network/disk speeds (live feeling)
        Timer.publish(every: 2, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchSystemSpeeds()
        }.store(in: &visibleCancellables)
        
        Timer.publish(every: 5, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchSpotify()
            self?.fetchNowPlaying()
        }.store(in: &visibleCancellables)
        Timer.publish(every: 15, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchNetwork()
        }.store(in: &visibleCancellables)
        // Slower data (still only while expanded)
        Timer.publish(every: 30, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchCalendar()
        }.store(in: &visibleCancellables)
        Timer.publish(every: 60, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard self?.isVisible == true else { return }
            self?.fetchAirPods()
            self?.fetchBattery()
            self?.fetchStorage()
            self?.fetchNote()
            self?.fetchReminder()
        }.store(in: &visibleCancellables)
    }
    
    private func stopVisibleTimers() {
        visibleCancellables.forEach { $0.cancel() }
        visibleCancellables.removeAll()
    }

    private func fetchCalendar() {
        DispatchQueue.main.async {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            self.calendarData = formatter.string(from: Date())
        }
        
        // Fetch upcoming event via EventKit
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized || status == .fullAccess {
            self.fetchNextEvent()
            self.fetchAestheticCalendar()
        } else {
            eventStore.requestFullAccessToEvents { granted, _ in
                if granted {
                    self.fetchNextEvent()
                    self.fetchAestheticCalendar()
                } else {
                    DispatchQueue.main.async {
                        self.calendarEvent = ""
                        self.calendarEventTime = ""
                        self.todayEvents = []
                    }
                }
            }
        }
    }
    
    private func fetchAestheticCalendar() {
        DispatchQueue.global(qos: .background).async {
            let targetDate = self.selectedCalendarDate
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let calendars = self.eventStore.calendars(for: .event)
            let predicate = self.eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: calendars)
            let events = self.eventStore.events(matching: predicate)
                .sorted { $0.startDate < $1.startDate }
            
            let eventInfos = events.map { event in
                CalendarEventInfo(
                    title: event.title ?? "New Event",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    color: NSColor(cgColor: event.calendar.cgColor) ?? .systemBlue,
                    isAllDay: event.isAllDay,
                    url: event.url,
                    notes: event.notes
                )
            }
            
            DispatchQueue.main.async {
                self.todayEvents = eventInfos
            }
        }
    }
    
    private func fetchNextEvent() {
        DispatchQueue.global(qos: .background).async {
            let now = Date()
            // Look back 2 hours (for in-progress events) and forward 24 hours
            let startDate = now.addingTimeInterval(-2 * 3600)
            let endDate = now.addingTimeInterval(24 * 3600)
            
            let calendars = self.eventStore.calendars(for: .event)
            let predicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
            let events = self.eventStore.events(matching: predicate)
                .filter { !$0.isAllDay } // Skip all-day events
                .sorted { $0.startDate < $1.startDate }
            
            // Find the most relevant event:
            // 1. Currently in-progress event
            // 2. Next upcoming event
            var bestEvent: EKEvent? = nil
            
            for event in events {
                if event.startDate <= now && event.endDate > now {
                    // Currently in progress — this takes priority
                    bestEvent = event
                    break
                }
                if event.startDate > now {
                    // Next upcoming
                    bestEvent = event
                    break
                }
            }
            
            DispatchQueue.main.async {
                if let event = bestEvent {
                    self.calendarEvent = event.title ?? "Event"
                    self.calendarEventTime = self.relativeTime(for: event, now: now)
                } else {
                    self.calendarEvent = ""
                    self.calendarEventTime = ""
                }
            }
        }
    }
    
    private func relativeTime(for event: EKEvent, now: Date) -> String {
        let start = event.startDate!
        let end = event.endDate!
        
        if start <= now && end > now {
            // Event is in progress
            let elapsed = Int(now.timeIntervalSince(start) / 60)
            let remaining = Int(end.timeIntervalSince(now) / 60)
            if elapsed < 1 { return "Starting now" }
            if remaining < 1 { return "Ending now" }
            if remaining <= 60 { return "\(remaining) min left" }
            return "\(remaining / 60)h \(remaining % 60)m left"
        } else {
            // Event is upcoming
            let minutesUntil = Int(start.timeIntervalSince(now) / 60)
            if minutesUntil < 1 { return "Now" }
            if minutesUntil < 60 { return "In \(minutesUntil) min" }
            let hours = minutesUntil / 60
            let mins = minutesUntil % 60
            if mins == 0 { return "In \(hours)h" }
            return "In \(hours)h \(mins)m"
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
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            task.standardOutput = pipe
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                DispatchQueue.main.async { self.recentNote = output }
            } else {
                DispatchQueue.main.async { self.recentNote = "No Notes" }
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
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            task.standardOutput = pipe
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                DispatchQueue.main.async { self.nextReminder = output }
            } else {
                DispatchQueue.main.async { self.nextReminder = "All clear" }
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
    
    private func fetchSpotify() {
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
                        self.spotifyTrack = parts[0]
                        self.spotifyArtist = parts[1]
                        self.isSpotifyPlaying = parts[2] == "playing"
                    }
                }
            }
        }
    }
    
    private func fetchNowPlaying() {
        DispatchQueue.global(qos: .background).async {
            // Use the helper script via `swift` interpreter — it uses the private MediaRemote
            // framework which requires the ObjC/XPC runtime that only the interpreter provides
            let helperPath = Bundle.main.path(forResource: "nowplaying_helper", ofType: "swift")
                ?? (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/nowplaying_helper.swift"
            
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
            task.arguments = [helperPath]
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice
            
            guard (try? task.run()) != nil else { return }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            guard let output = String(data: data, encoding: .utf8) else { return }
            let clean = output.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = clean.components(separatedBy: "|||")
            
            if parts.count >= 7 {
                DispatchQueue.main.async {
                    let title = parts[0]
                    let artist = parts[1]
                    let source = parts[2]
                    let isPlaying = parts[3] == "true"
                    let duration = Double(parts[4]) ?? 0
                    let elapsed = Double(parts[5]) ?? 0
                    let artworkBase64 = parts[6]
                    
                    if !title.isEmpty && title != "Not Playing" {
                        self.mediaTrack = title
                        self.mediaArtist = artist
                        self.mediaApp = source
                        self.isMediaPlaying = isPlaying
                        self.mediaDuration = duration
                        self.mediaPosition = elapsed
                        
                        if !artworkBase64.isEmpty, let pData = Data(base64Encoded: artworkBase64, options: .ignoreUnknownCharacters), let img = NSImage(data: pData) {
                            self.mediaArtwork = img
                        } else {
                            self.mediaArtwork = nil
                        }
                        
                    } else {
                        self.isMediaPlaying = false
                        self.mediaArtwork = nil
                        self.mediaDuration = 0
                        self.mediaPosition = 0
                    }
                }
            }
        }
    }
    
    private var lastNetBytesOut: UInt64 = 0
    private var lastNetBytesIn: UInt64 = 0
    
    func fetchSystemSpeeds() {
        DispatchQueue.global(qos: .background).async {
            // 1. Network Speeds via netstat
            let netTask = Process()
            let netPipe = Pipe()
            netTask.executableURL = URL(fileURLWithPath: "/usr/bin/netstat")
            netTask.arguments = ["-ib"]
            netTask.standardOutput = netPipe
            try? netTask.run()
            let netData = netPipe.fileHandleForReading.readDataToEndOfFile()
            netTask.waitUntilExit()
            if let output = String(data: netData, encoding: .utf8) {
                var currentBytesIn: UInt64 = 0
                var currentBytesOut: UInt64 = 0
                
                let lines = output.components(separatedBy: .newlines)
                for line in lines.dropFirst() {
                    let cols = line.split(separator: " ", omittingEmptySubsequences: true)
                    // netstat -ib format varies slightly, but roughly: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll
                    // Usually Ibytes is col 6, Obytes is col 9.
                    if cols.count >= 10, let ibytes = UInt64(cols[6]), let obytes = UInt64(cols[9]) {
                        currentBytesIn += ibytes
                        currentBytesOut += obytes
                    } else if cols.count == 11, let ibytes = UInt64(cols[7]), let obytes = UInt64(cols[10]) {
                        // Alternate format with Name Mtu Network Address Ipkts Ierrs Drop Ibytes Opkts Oerrs Obytes Coll
                        currentBytesIn += ibytes
                        currentBytesOut += obytes
                    }
                }
                
                if self.lastNetBytesIn > 0 && self.lastNetBytesOut > 0 {
                    let diffIn = currentBytesIn > self.lastNetBytesIn ? currentBytesIn - self.lastNetBytesIn : 0
                    let diffOut = currentBytesOut > self.lastNetBytesOut ? currentBytesOut - self.lastNetBytesOut : 0
                    
                    let rxSpeed = self.formatBytesPerSecond(diffIn)
                    let txSpeed = self.formatBytesPerSecond(diffOut)
                    
                    DispatchQueue.main.async {
                        self.networkDownSpeed = rxSpeed
                        self.networkUpSpeed = txSpeed
                    }
                }
                
                self.lastNetBytesIn = currentBytesIn
                self.lastNetBytesOut = currentBytesOut
            }
            
            // 2. Disk Speeds via iostat (sample over 1 second)
            let diskTask = Process()
            let diskPipe = Pipe()
            diskTask.executableURL = URL(fileURLWithPath: "/usr/sbin/iostat")
            diskTask.arguments = ["-d", "-K", "-w", "1", "-c", "2"] // 2 samples, 1 sec delay
            diskTask.standardOutput = diskPipe
            try? diskTask.run()
            let diskData = diskPipe.fileHandleForReading.readDataToEndOfFile()
            diskTask.waitUntilExit()
            if let output = String(data: diskData, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
                // Look at the very last line (second sample)
                if let lastLine = lines.last {
                    let cols = lastLine.split(separator: " ", omittingEmptySubsequences: true)
                    // iostat format: KB/t xfrs/s MB/s (for each disk). We just sum up the MB/s column (index 2, 5, 8...)
                    // Actually, total sum is easier: sum all KB/t * xfrs/s... wait, standard iostat format has disk0 disk1
                    // Let's just grab the first disk's speed for now (usually the main SSD)
                    if cols.count >= 3, let mbps = Double(cols[2]) {
                        // iostat doesn't easily split read/write without complex parsing.
                        // Let's use a simplified representation or just show total I/O
                        let speedStr = String(format: "%.1f MB/s", mbps)
                        DispatchQueue.main.async {
                            // Assign total speed to both for now, or just one
                            self.customDiskRead = speedStr
                            self.customDiskWrite = "—"
                        }
                    }
                }
            }
        }
    }
    
    private func formatBytesPerSecond(_ bytes: UInt64) -> String {
        if bytes < 1024 { return "\(bytes) B/s" }
        let kb = Double(bytes) / 1024.0
        if kb < 1024 { return String(format: "%.0f KB/s", kb) }
        let mb = kb / 1024.0
        return String(format: "%.1f MB/s", mb)
    }
    
    func sendSpotifyCommand(_ command: String) {
        DispatchQueue.global(qos: .background).async {
            let script = "tell application \"Spotify\" to \(command)"
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", script]
            try? task.run()
            task.waitUntilExit()
            self.fetchSpotify()
        }
    }
    
    // Send system-wide media commands via MediaRemote framework
    // Commands: 0=Play, 1=Pause, 2=TogglePlayPause, 4=NextTrack, 5=PreviousTrack
    func sendMediaCommand(_ command: UInt32) {
        DispatchQueue.global(qos: .background).async {
            let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
            guard let handle = dlopen(path, RTLD_NOW),
                  let sym = dlsym(handle, "MRMediaRemoteSendCommand") else { return }
            
            typealias SendCmdFn = @convention(c) (UInt32, AnyObject?) -> Bool
            let sendCmd = unsafeBitCast(sym, to: SendCmdFn.self)
            _ = sendCmd(command, nil)
            
            // Re-fetch after a short delay to update UI
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
                self.fetchNowPlaying()
            }
        }
    }
    
    private func fetchBattery() {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            task.arguments = ["-g", "batt"]
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Parse "XX%" from pmset output
                if let range = output.range(of: #"\d+%"#, options: .regularExpression) {
                    let pct = String(output[range])
                    DispatchQueue.main.async {
                        self.batteryLevel = pct
                    }
                }
            }
        }
    }
    
    private func fetchScreenTime() {
        DispatchQueue.global(qos: .background).async {
            // Use shell pipeline to get display on/off events
            let task = Process()
            let pipe = Pipe()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", "pmset -g log | grep 'Display is turned'"]
            task.standardOutput = pipe
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let now = Date()
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: now)
            
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            df.locale = Locale(identifier: "en_US_POSIX")
            
            struct DisplayEvent {
                let date: Date
                let isOn: Bool
            }
            
            // Parse ALL events (including yesterday's last event for carry-over)
            var allEvents: [DisplayEvent] = []
            for line in output.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.count >= 25 else { continue }
                let timestampStr = String(trimmed.prefix(25))
                guard let date = df.date(from: timestampStr) else { continue }
                let isOn = line.contains("turned on")
                allEvents.append(DisplayEvent(date: date, isOn: isOn))
            }
            allEvents.sort { $0.date < $1.date }
            
            // Find the last event before today to determine initial state
            var displayWasOn = false
            for event in allEvents {
                if event.date >= startOfToday { break }
                displayWasOn = event.isOn
            }
            
            // Filter to today's events only
            let todayEvents = allEvents.filter { $0.date >= startOfToday }
            
            // Sum display-on time
            var totalOnSeconds: TimeInterval = 0
            var lastOnTime: Date? = displayWasOn ? startOfToday : nil
            
            for event in todayEvents {
                if event.isOn {
                    lastOnTime = event.date
                } else if let onTime = lastOnTime {
                    totalOnSeconds += event.date.timeIntervalSince(onTime)
                    lastOnTime = nil
                }
            }
            
            // If display is currently on, count up to now
            if let onTime = lastOnTime {
                totalOnSeconds += now.timeIntervalSince(onTime)
            }
            
            let formatted = self.formatDuration(totalOnSeconds)
            DispatchQueue.main.async {
                self.screenTime = formatted
            }
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

