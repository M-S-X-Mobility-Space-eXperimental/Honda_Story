/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the welcome view.
*/

import SwiftUI

struct WelcomeView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack {
            SharePlayButton("Play Set Off Together", activity: SetOffTogetherActivity())
                .padding(.vertical, 20)
        }
        .padding(.horizontal)
    }
}

#Preview(windowStyle: .automatic) {
    WelcomeView()
        .environment(AppModel())
}
