import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var hoverObserver: HoverObserver
    @State private var isTargeted: Bool = false
    @State private var draggedItemName: String? = nil
    
    @AppStorage("showMediaMock") private var showMediaMock = true
    @AppStorage("notchWidth") private var notchWidth: Double = 400.0
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isTargeted ? Color.blue : Color.clear, lineWidth: 2)
                )
                
            // Content
            if hoverObserver.isHovering {
                HStack(spacing: 20) {
                    if showMediaMock {
                        // Media Player Mock
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                            VStack(alignment: .leading) {
                                Text("Now Playing")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                Text("Song Title - Artist")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Shelf / Drop Mock
                    HStack {
                        if let iName = draggedItemName {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            Text(iName)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: 80)
                        } else {
                            Image(systemName: "tray.and.arrow.down")
                                .foregroundColor(isTargeted ? .blue : .gray)
                            Text("Drop Files Here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .scale))
            } else {
                // Emulate physical notch
                Color.black
            }
        }
        .frame(width: hoverObserver.isHovering ? CGFloat(notchWidth) : 200, 
               height: hoverObserver.isHovering ? 70 : 32)
        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: hoverObserver.isHovering)
        // Ensure SwiftUI view respects safe area / borderless
        .edgesIgnoringSafeArea(.all)
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
            if let provider = providers.first {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                    if let data = urlData as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.draggedItemName = url.lastPathComponent
                        }
                    } else if let url = urlData as? URL {
                        DispatchQueue.main.async {
                            self.draggedItemName = url.lastPathComponent
                        }
                    }
                }
                return true
            }
            return false
        }
    }
}
