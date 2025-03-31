//
//  ImmersiveView.swift
//  Honda_story
//
//  Created by messitu on 2/3/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine
import FirebaseDatabase

var ref: DatabaseReference!

struct ImmersiveView: View {
    @State private var environmentEntity: Entity?
    @State private var timerCancellable: Cancellable?
    @State private var bisonFoodsEntity: Entity?
    @State private var bluegrassEntity: Entity?
    @State private var EruptionEntity: Entity?
    
    @StateObject private var viewModel: TapViewModel
    
    init() {
          // Initialize the viewModel with playerID from AppStorage
          let playerIDFromStorage = UserDefaults.standard.integer(forKey: "playerID")
          _viewModel = StateObject(wrappedValue: TapViewModel(userId: String(playerIDFromStorage)))
      }

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                
                
                content.add(immersiveContentEntity)

              
                if let environment = immersiveContentEntity.findEntity(named: "Environment") {
                    environmentEntity = environment
                    
                    // Start a timer to move the object 1cm per second
                    timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
                        .autoconnect()
                        .sink { _ in
                            environment.position += SIMD3<Float>(x: 0.02, y: 0, z: 0)
                        }
                }
                
                // Find "BisonFoods" and deactivate it initially
                if let bisonfood = immersiveContentEntity.findEntity(named: "BisonFoods"){
                    bisonFoodsEntity = bisonfood
                    bisonfood.isEnabled = false
                    
                }
                if let eruption = immersiveContentEntity.findEntity(named: "Eruption"){
                    eruption.isEnabled = false
                }
                
                if let bluegrass = immersiveContentEntity.findEntity(named: "bluegrass") {
                    bluegrassEntity = bluegrass
                }

            }
        }
        
        .gesture(TapGesture().targetedToAnyEntity()
             .onEnded { value in
                 
                 let tappedEntity = value.entity
                 
                 if tappedEntity.name == "GeyserSandbox" {
                     viewModel.tap { bothTapped in
                         if bothTapped {
                             print("Both players tapped!")
                             EruptionEntity?.isEnabled = true
                             bisonFoodsEntity?.isEnabled = true
                             _ = value.entity.applyTapForBehaviors()
                         } else {
                             print("Waiting on opponent.")
                         }
                     }
                 }
                 
         })
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    if value.entity.name == "bluegrass" {
                        // Update position to match drag location in 3D
                        bluegrassEntity?.position = value.convert(value.location3D, from: .local, to: .scene)
                    }
                }
        )
        
        
        .onDisappear {
                
            timerCancellable?.cancel()
        }
    }
    
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
