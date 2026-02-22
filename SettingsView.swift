import SwiftUI

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Element].self, from: data) else {
            return nil
        }
        self = decoded
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}

struct SettingsView: View {
    @AppStorage("leftModulesList") private var leftModules: [String] = ["Media"]
    @AppStorage("rightModulesList") private var rightModules: [String] = ["Clock"]
    
    let availableModules = ["Media", "Battery", "Clock", "WiFi", "None"]
    
    // Compute remaining items so users cannot add duplicates
    private var filteredAvailableModules: [String] {
        availableModules.filter { !leftModules.contains($0) && !rightModules.contains($0) }
    }
    
    var body: some View {
        VStack {
            Text("Dashboard Configuration")
                .font(.headline)
                .padding(.top, 10)
            
            HStack(spacing: 20) {
                // LEFT SIDE MODULES
                VStack {
                    Text("Left Side (Max 4)")
                        .font(.subheadline).bold()
                    List {
                        ForEach(leftModules, id: \.self) { mod in
                            HStack {
                                Text(mod)
                                Spacer()
                                Button(action: {
                                    if let index = leftModules.firstIndex(of: mod) {
                                        leftModules.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .onMove(perform: moveLeft)
                        .onDelete(perform: deleteLeft)
                    }
                    .frame(height: 180)
                    .border(Color.gray.opacity(0.3))
                    
                    Menu("Add Module") {
                        ForEach(filteredAvailableModules, id: \.self) { mod in
                            Button(mod) {
                                if leftModules.count < 4 { leftModules.append(mod) }
                            }
                        }
                    }
                    .disabled(leftModules.count >= 4 || filteredAvailableModules.isEmpty)
                }
                
                // RIGHT SIDE MODULES
                VStack {
                    Text("Right Side (Max 4)")
                        .font(.subheadline).bold()
                    List {
                        ForEach(rightModules, id: \.self) { mod in
                            HStack {
                                Text(mod)
                                Spacer()
                                Button(action: {
                                    if let index = rightModules.firstIndex(of: mod) {
                                        rightModules.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .onMove(perform: moveRight)
                        .onDelete(perform: deleteRight)
                    }
                    .frame(height: 180)
                    .border(Color.gray.opacity(0.3))
                    
                    Menu("Add Module") {
                        ForEach(filteredAvailableModules, id: \.self) { mod in
                            Button(mod) {
                                if rightModules.count < 4 { rightModules.append(mod) }
                            }
                        }
                    }
                    .disabled(rightModules.count >= 4 || filteredAvailableModules.isEmpty)
                }
            }
            .padding()
            
            Text("Tip: Drag items in the list to reorder them. Swipe/Delete to remove.")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
        }
        .frame(width: 500, height: 350)
    }
    
    func moveLeft(from source: IndexSet, to destination: Int) {
        leftModules.move(fromOffsets: source, toOffset: destination)
    }
    func deleteLeft(at offsets: IndexSet) {
        leftModules.remove(atOffsets: offsets)
    }
    func moveRight(from source: IndexSet, to destination: Int) {
        rightModules.move(fromOffsets: source, toOffset: destination)
    }
    func deleteRight(at offsets: IndexSet) {
        rightModules.remove(atOffsets: offsets)
    }
}
