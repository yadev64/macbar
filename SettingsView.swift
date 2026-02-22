import SwiftUI

struct SettingsView: View {
    @AppStorage("showMediaMock") private var showMediaMock = true
    @AppStorage("notchWidth") private var notchWidth: Double = 400.0
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Show Media Player Mock", isOn: $showMediaMock)
                
                VStack(alignment: .leading) {
                    Text("Expanded Width: \(Int(notchWidth))")
                        .font(.caption)
                    Slider(value: $notchWidth, in: 250...600, step: 10)
                }
            }
            .padding()
        }
        .frame(width: 400, height: 200)
        .padding()
    }
}
