import SwiftUI
import AppKit

// MARK: - Aesthetic Media Widget
struct AestheticMediaWidget: View {
    @ObservedObject var data = WidgetDataManager.shared
    @State private var hoverState = false
    
    @AppStorage("barHeight") private var barHeight: Double = 120
    @AppStorage("aestheticTheme") private var aestheticTheme: String = "Black"
    
    var body: some View {
        let width = max(CGFloat(barHeight * 2.8), 300)
        let height = CGFloat(barHeight)
        
        ZStack {
            // Background Layer
            if let artwork = data.mediaArtwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .blur(radius: 40)
                    .overlay(Color.black.opacity(0.4)) // Darken overlay slightly for readability
            } else {
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.4), Color.indigo.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            
            HStack(spacing: 24) {
                // Album Art (Strictly Square)
                if let artwork = data.mediaArtwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: height - 32, height: height - 32)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: height - 32, height: height - 32)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                // Track Info & Controls
                VStack(alignment: .leading, spacing: 0) {
                    // Title and Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.mediaTrack)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Text(data.mediaArtist.isEmpty ? data.mediaApp : data.mediaArtist)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 8)
                    
                    // Progress Bar
                    if data.mediaDuration > 0 {
                        VStack(spacing: 4) {
                            GeometryReader { geo in
                                let progress = CGFloat(max(0, min(1, data.mediaPosition / data.mediaDuration)))
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: max(0, geo.size.width * progress), height: 4)
                                }
                            }
                            .frame(height: 4)
                            
                            HStack {
                                Text(formatTime(data.mediaPosition))
                                Spacer()
                                Text(formatTime(data.mediaDuration))
                            }
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Controls Row
                    HStack(spacing: 24) {
                        controlButton(icon: "backward.fill", size: 14) { data.sendMediaCommand(5) }
                        controlButton(icon: data.isMediaPlaying ? "pause.fill" : "play.fill", size: 20) { data.sendMediaCommand(2) }
                        controlButton(icon: "forward.fill", size: 14) { data.sendMediaCommand(4) }
                        Spacer()
                    }
                    .padding(.bottom, 4)
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .shadow(color: aestheticTheme == "Liquid Glass" ? Color.black.opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
    }
    
    private func controlButton(icon: String, size: CGFloat = 18, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Aesthetic Calendar Widget
struct AestheticCalendarWidget: View {
    @ObservedObject var data = WidgetDataManager.shared
    @AppStorage("barHeight") private var barHeight: Double = 120
    @AppStorage("aestheticTheme") private var aestheticTheme: String = "Black"
    
    var body: some View {
        let width = max(CGFloat(barHeight * 4.0), 380)
        let height = CGFloat(barHeight)
        let leftWidth = max(width * 0.35, 200)
        
        HStack(spacing: 0) {
            // Left Side: Scrollable Date Strip
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(data.selectedCalendarDate, formatter: monthFormatter)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: { shiftDate(by: -7) }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { shiftDate(by: 7) }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { proxy in
                        HStack(spacing: 8) {
                            let days = getSurroundingDays()
                            ForEach(days, id: \.self) { date in
                                dateCell(for: date)
                            }
                        }
                        .padding(.horizontal, 16)
                        .onAppear {
                            // Delay slightly to ensure layout is complete before scrolling
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let target = getSurroundingDays().first(where: { Calendar.current.isDate($0, inSameDayAs: data.selectedCalendarDate) }) {
                                    withAnimation {
                                        proxy.scrollTo(target, anchor: .center)
                                    }
                                }
                            }
                        }
                        .onChange(of: data.selectedCalendarDate) { newDate in
                            if let target = getSurroundingDays().first(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
                                withAnimation {
                                    proxy.scrollTo(target, anchor: .center)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .frame(width: leftWidth)
            .background(Color.white.opacity(0.04))
            
            // Right Side: Today's Events
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    if data.todayEvents.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.minus")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.3))
                            Text("No events today")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(height: height)
                    } else {
                        ForEach(data.todayEvents) { event in
                            EventCard(event: event)
                        }
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(width: width, height: height)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .shadow(color: aestheticTheme == "Liquid Glass" ? Color.black.opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
    }
    
    @ViewBuilder
    private func dateCell(for date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: data.selectedCalendarDate)
        let isToday = Calendar.current.isDateInToday(date)
        
        Button(action: {
            data.selectedCalendarDate = Calendar.current.startOfDay(for: date)
        }) {
            VStack(spacing: 6) {
                Text(date, formatter: dayOfWeekFormatter)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : (isToday ? Color.accentColor : .white.opacity(0.4)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(date, formatter: dayOfMonthFormatter)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : (isToday ? Color.accentColor : .white.opacity(0.8)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.accentColor : Color.clear)
                    .clipShape(Circle())
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
        .buttonStyle(PlainButtonStyle())
        .id(date)
    }
    
    private func getSurroundingDays() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-30...30).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }
    
    private func shiftDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: data.selectedCalendarDate) {
            data.selectedCalendarDate = newDate
        }
    }
    
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()
    private let dayOfWeekFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "E"; return f
    }()
    private let dayOfMonthFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
}

struct EventCard: View {
    let event: WidgetDataManager.CalendarEventInfo
    @State private var hover = false
    
    var body: some View {
        Button(action: {
            if let url = event.url {
                NSWorkspace.shared.open(url)
            } else if let notes = event.notes, let extracted = extractURL(from: notes) {
                NSWorkspace.shared.open(extracted)
            } else {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-a", "Calendar"]
                try? process.run()
            }
        }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(nsColor: event.color))
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        if event.isAllDay {
                            Text("All Day")
                        } else {
                            Text("\(timeStr(event.startDate)) - \(timeStr(event.endDate))")
                        }
                        
                        Spacer()
                        
                        let status = getStatus()
                        if !status.isEmpty {
                            Text(status)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(event.startDate <= Date() && event.endDate > Date() ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                                .foregroundColor(event.startDate <= Date() && event.endDate > Date() ? .green : .white.opacity(0.8))
                                .cornerRadius(6)
                        }
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(hover ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { h in hover = h }
    }
    
    private func timeStr(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
    
    private func getStatus() -> String {
        let now = Date()
        if event.isAllDay { return "" }
        if now > event.endDate { return "Done" }
        if now >= event.startDate && now < event.endDate { return "Now" }
        
        let diff = Int(event.startDate.timeIntervalSince(now) / 60)
        if diff < 120 && diff > 0 { return "In \(diff)m" }
        return ""
    }
    
    private func extractURL(from text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url
    }
}

// MARK: - Aesthetic System Widget
struct AestheticSystemWidget: View {
    @ObservedObject var data = WidgetDataManager.shared
    @AppStorage("barHeight") private var barHeight: Double = 120
    @AppStorage("aestheticTheme") private var aestheticTheme: String = "Black"
    
    var body: some View {
        let width = max(CGFloat(barHeight * 1.6), 160)
        let height = CGFloat(barHeight)
        
        VStack(spacing: 1) { // 1pt hairline dividers
            HStack(spacing: 1) {
                SystemQuadCell(icon: "cpu", color: .blue, title: "CPU", value: data.cpuUsage)
                SystemQuadCell(icon: "memorychip", color: .purple, title: "RAM", value: data.ramUsage.replacingOccurrences(of: " MB", with: ""))
            }
            HStack(spacing: 1) {
                SystemQuadCell(icon: "internaldrive", color: .orange, title: "I/O", value: data.customDiskRead)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill").foregroundColor(.green)
                        Text(data.networkDownSpeed).lineLimit(1).minimumScaleFactor(0.5)
                    }
                    HStack {
                        Image(systemName: "arrow.up.circle.fill").foregroundColor(.blue)
                        Text(data.networkUpSpeed).lineLimit(1).minimumScaleFactor(0.5)
                    }
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
            }
        }
        .frame(width: width, height: height)
        .background(Color.white.opacity(0.1)) // Acts as the 1pt divider color
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        .shadow(color: aestheticTheme == "Liquid Glass" ? Color.black.opacity(0.25) : .clear, radius: 12, x: 0, y: 6)
    }
}

struct SystemQuadCell: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.04))
    }
}
