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

    // Typing animation state
    @State private var fullDescription = """
    Yellowstone National Park — a mesmerizing expanse of wilderness and geological wonders, a testament to nature's majestic force and ageless beauty. Here, sprawling forests, powerful rivers, and dramatic mountain ranges converge across nearly 3,500 square miles of captivating landscape, creating a sanctuary of unparalleled biodiversity and geological marvels that continue to awe and inspire visitors from around the world.
    """
    @State private var displayedDescription = ""

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
                Text("Welcome to the YellowStone National Park")
                    .font(.system(size: 70, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                    )
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            } else {
                VStack(spacing: 2) {
                    Text("Waiting for all players to be ready")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.6))
                        )

                    Text(displayedDescription)
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 60)
            }
        }
        .onChange(of: showTitle) {
            if !showTitle {
                startTypingDescription()
                dbModel.setPlayerReady()
            }
        }
        .onChange(of: dbModel.startGeyserExp) {
            dismissWindow(id:"ContentWindow")
        }
    }

    func startTypingDescription() {
        // Prevent restarting if it's already in progress
        if !displayedDescription.isEmpty { return }
        
        displayedDescription = ""
        var delay = 0.0
        for letter in fullDescription {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                displayedDescription.append(letter)
            }
            delay += 0.015
        
        }
    }
}
