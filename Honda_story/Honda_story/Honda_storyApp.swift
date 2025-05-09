//
//  Honda_storyApp.swift
//  Honda_story
//
//  Created by messitu on 2/3/25.
//

import SwiftUI
import FirebaseCore
import RealityKitContent


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}


@main
struct Honda_storyApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var appModel = AppModel()
    
    init() {
        RealityKitContent.GestureComponent.registerComponent()
    }

    var body: some Scene {
        WindowGroup (id: appModel.contentWindowID) {
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
