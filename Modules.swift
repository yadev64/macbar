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
