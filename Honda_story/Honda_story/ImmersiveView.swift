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

struct ImmersiveView: View {
    @State private var environmentEntity: Entity?
    @State private var timerCancellable: Cancellable?
    @State private var bisonFoodsEntity: Entity?
    
    @State private var isFollowingHand = false
    @State private var handAnchor: Entity?

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
                            environment.position += SIMD3<Float>(x: 0.002, y: 0, z: 0)
                        }
                }
                
                // Find "BisonFoods" and deactivate it initially
                if let bisonfood = immersiveContentEntity.findEntity(named: "BisonFoods"){
                    bisonFoodsEntity = bisonfood
                    bisonfood.isEnabled = false
                    
                }
                
            

            }
        }
        
        .gesture(TapGesture().targetedToAnyEntity()
             .onEnded { value in
                 
                 let tappedEntity = value.entity
                 if tappedEntity.name == "GeyserSandbox" {
                     bisonFoodsEntity?.isEnabled = true
                 }
                 _ = value.entity.applyTapForBehaviors()
         })
        .onDisappear {
                
            timerCancellable?.cancel()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
