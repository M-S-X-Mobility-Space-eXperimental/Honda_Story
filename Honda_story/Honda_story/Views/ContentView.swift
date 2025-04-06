import SwiftUI
import RealityKit
import RealityKitContent



struct ContentView: View {
    
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    
    @State private var showTitle = true
    @State private var immersiveEntered = false
    @StateObject var dbModel = DBModel.shared


//    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ZStack {
            RealityView { content in
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                    content.add(scene)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomOrnament) {
                    if !immersiveEntered {
                        ToggleImmersiveSpaceButton(
                            immersiveEntered: $immersiveEntered,
                            showTitle: $showTitle
                        )
                    }
                }
            }

            if showTitle {
                Text("Welcome to YellowStone National Park")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
            
            Text("Waiting for all players to be ready")
            .font(.title3)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.6))
            )
        }
        .onChange(of: showTitle) {
            if !showTitle {
                dismissWindow(id: "ContentWindow")
            }
        }
    }
    
}
