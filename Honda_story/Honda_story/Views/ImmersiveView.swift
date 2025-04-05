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

struct ImmersiveView: View {
    
    @State private var session: SpatialTrackingSession?
    
    @State private var environmentEntity: Entity?
    @State private var timerCancellable: Cancellable?
    @State private var bisonFoodsEntity: Entity?
    @State private var bluegrassEntity: Entity?
    @State private var EruptionEntity: Entity?
    @State private var BisonEntity: Entity?
    
    @State private var GeyserErupt: Bool = false
    @State private var BisonAttracted: Bool = false
    
    @State private var Timeline_GeyserEntity: Entity?
    
    
    @StateObject private var dbModel: DBModel
    
    
    init() {
          // Initialize the DBModel with playerID from AppStorage
          _dbModel = StateObject(wrappedValue: DBModel())
      }

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                
                
                content.add(immersiveContentEntity)
                
                
                let session = SpatialTrackingSession()
                let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
                _ = await session.run(configuration)
                self.session = session
               //Setup an anchor at the user's left palm.
                let handAnchor = AnchorEntity(.hand(.left, location: .palm), trackingMode: .continuous)
                
                if let sphere = immersiveContentEntity.findEntity(named: "Sphere"){
                               
                    //Child the gauntlet scene to the handAnchor.
                    handAnchor.addChild(sphere)
                    
                    // Add the handAnchor to the RealityView scene.
                    content.add(handAnchor)
                   
                }

                
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
                    EruptionEntity = eruption
                }
                
                if let bison = immersiveContentEntity.findEntity(named: "Bison") {
                    BisonEntity = bison
                    
                }
                print(BisonEntity ?? "Nobison")
                
                if let bluegrass = immersiveContentEntity.findEntity(named: "bluegrass") {
                    bluegrassEntity = bluegrass
                }

            }
        }
        .task{
            dbModel.observeGeyser()
        }
        
        .onChange(of: dbModel.Geyser) {
            if dbModel.Geyser {
                print("Enabling Eruption")
                EruptionEntity?.isEnabled = true
                bisonFoodsEntity?.isEnabled = true
                GeyserErupt = true
                
           }
        }
        
        .gesture(TapGesture().targetedToAnyEntity()
             .onEnded { value in
                 
                 let tappedEntity = value.entity
                 
                 if tappedEntity.name == "GeyserSandbox" {
                     dbModel.tapGeyser()
                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                         if GeyserErupt {
                             // apply to behavior
                             _ = tappedEntity.applyTapForBehaviors()
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
                        
                        if(!BisonAttracted){
                            _ = BisonEntity?.applyTapForBehaviors()
                            BisonAttracted = true
                        }
                        
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
