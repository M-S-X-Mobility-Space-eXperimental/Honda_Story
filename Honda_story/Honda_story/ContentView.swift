import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @State private var showTitle = true
    @State private var immersiveEntered = false

    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        ZStack {
            RealityView { content in
                if let scene = try? await Entity(named: "Scene", in: realityKitContentBundle) {
                    content.add(scene)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomOrnament) {
                    // Show immersive button only before entering
                    if !immersiveEntered {
                        ToggleImmersiveSpaceButton(
                            immersiveEntered: $immersiveEntered,
                            showTitle: $showTitle
                        )
                    }
                }
            }

            // Persistent title overlay
            if showTitle {
                Text("Honda in 2040")
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
        }
    }
}
