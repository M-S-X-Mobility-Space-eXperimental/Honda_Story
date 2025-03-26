import SwiftUI

struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @Binding var immersiveEntered: Bool
    @Binding var showTitle: Bool

    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                case .closed:
                    appModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                    case .opened:
                        immersiveEntered = true
                        withAnimation {
                            showTitle = false
                        }
                    case .userCancelled, .error:
                        fallthrough
                    @unknown default:
                        appModel.immersiveSpaceState = .closed
                    }

                case .open:
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()

                case .inTransition:
                    break
                }
            }
        } label: {
            Text("Enter Immersive Experience")
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
