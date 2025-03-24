//
//  Honda_storyApp.swift
//  Honda_story
//
//  Created by messitu on 2/3/25.
//

import SwiftUI
import RealityKitContent

@main
struct Honda_storyApp: App {
    
    init() {
        RealityKitContent.GestureComponent.registerComponent()
    }

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.volumetric)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
