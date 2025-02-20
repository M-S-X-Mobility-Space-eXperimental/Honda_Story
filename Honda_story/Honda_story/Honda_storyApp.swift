//
//  Honda_storyApp.swift
//  Honda_story
//
//  Created by messitu on 2/3/25.
//

import SwiftUI

@main
struct Honda_storyApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .frame(minWidth: 800, minHeight: 800)
                .frame(minDepth: 800)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 2, depth: 2, in: .meters)

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
