import SwiftUI

struct SettingsView: View {
    @AppStorage("leftModule") private var leftModule: String = "Media"
    @AppStorage("rightModule") private var rightModule: String = "Clock"
    @AppStorage("notchWidth") private var notchWidth: Double = 600.0
    
    let modules = ["None", "Media", "Battery", "Clock", "WiFi"]
    
    var body: some View {
        Form {
            Section(header: Text("Dashboard Modules")) {
                Picker("Left Module", selection: $leftModule) {
                    ForEach(modules, id: \.self) { module in
                        Text(module).tag(module)
                    }
                }
                
                Picker("Right Module", selection: $rightModule) {
                    ForEach(modules, id: \.self) { module in
                        Text(module).tag(module)
                    }
                }
            }
            
            Section(header: Text("Appearance")) {
                VStack(alignment: .leading) {
                    Text("Expanded Width: \(Int(notchWidth))")
                        .font(.caption)
                    Slider(value: $notchWidth, in: 350...700, step: 10)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
