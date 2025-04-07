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
    
    @State private var immersiveContentEntity:Entity?
    @State private var SceneRootContent: RealityViewContent?
    
    @State private var environmentEntity: Entity?
    @State private var timerCancellable: Cancellable?
    @State private var bisonFoodsEntity: Entity?
    @State private var bluegrassEntity: Entity?
   
    @State private var EruptionEntity: Entity?
    @State private var GeyserSandboxEntity: Entity?
    @State private var GeyserSoundTLEntity: Entity?
    
    @State private var timelineGeyser:Entity?
    @State private var BisonEntity: Entity?
    @State private var CountDownEntity: Entity?
    @State private var TestCubeEntity: Entity?
    
//    @State private var RootEntity: Entity?
    
    @State private var GeyserErupt: Bool = false
    @State private var BisonAttracted: Bool = false
    
    @State private var Timeline_GeyserEntity: Entity?
    
    @State private var LeftHandAnchor: AnchorEntity?
    @State private var RightHandAnchor: AnchorEntity?
    @State private var CurrentHandAnchor: AnchorEntity?
    @State private var SphereEntity: Entity?
    
    @State private var lastCubePosition: SIMD3<Float>?
    @State private var cancellables = Set<AnyCancellable>()
    
    @State private var deferredEntities: [String: Entity] = [:]


    
    @StateObject var dbModel = DBModel.shared

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                
                
                content.add(immersiveContentEntity)
                
                self.immersiveContentEntity = immersiveContentEntity
                self.SceneRootContent = content
                
                
                // Hand Tracking Setup
                let session = SpatialTrackingSession()
                let configuration = SpatialTrackingSession.Configuration(tracking: [.hand, .world])
                _ = await session.run(configuration)
                self.session = session
               //Setup an anchor at the user's left palm.
                self.LeftHandAnchor = AnchorEntity(.hand(.left, location: .indexFingerTip), trackingMode: .continuous)
                self.RightHandAnchor = AnchorEntity(.hand(.right, location: .indexFingerTip), trackingMode: .continuous)


                assignEntity(named: "GeyserSoundTL", to: &GeyserSoundTLEntity)
                assignEntity(named: "Environment", to: &environmentEntity)
                assignEntity(named: "BisonFoods", to: &bisonFoodsEntity, disable: false)
                assignEntity(named: "Eruption", to: &EruptionEntity, disable: true)
                assignEntity(named: "Bison", to: &BisonEntity)
                assignEntity(named: "bluegrass", to: &bluegrassEntity)
                assignEntity(named: "GeyserSandbox", to: &GeyserSandboxEntity, disable: true)
                
//                assignEntity(named: "Sphere", to: &SphereEntity)
//                
//                LeftHandAnchor?.addChild(SphereEntity!)
//                content.add(LeftHandAnchor!)
                
                
                

            }
        }
        .task{
//            dbModel.observeGeyser()
            
            // First stage observe all ready
            dbModel.observeAllRealdy()
        }
        .onChange(of: dbModel.startGeyserExp) {
            if dbModel.startGeyserExp{
                GeyserSandboxEntity?.isEnabled = true
                print(GeyserSoundTLEntity ?? "GeyserSoundTLEntity is nil")
                
                _ = GeyserSoundTLEntity?.applyTapForBehaviors()
                
                startMoving()
           }
            
            //reset ready for next round
            dbModel.playerResetReady()
        }
        
        .onChange(of: dbModel.Geyser) {
            if dbModel.Geyser {
                print("Enabling Eruption")
                EruptionEntity?.isEnabled = true
                bisonFoodsEntity?.isEnabled = true
                GeyserErupt = true
                
                CountDownEntity?.isEnabled = false
                
                _ = GeyserSandboxEntity?.applyTapForBehaviors()
                _ = bisonFoodsEntity?.applyTapForBehaviors()
                
           }
        }
        
        .simultaneousGesture(TapGesture().targetedToAnyEntity()
             .onEnded { value in
                 
                 let tappedEntity = value.entity
                 
                 if tappedEntity.name == "GeyserSandbox" {
                     dbModel.tapGeyser()
                 }
                 
         })
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    // Only interact with children of BisonFoods
                    guard value.entity.parent?.name == "BisonFoods" else { return }
                    
                    // check if the object have collision component
                    
                    guard value.entity.components[CollisionComponent.self] != nil else { return }
                    
                    guard value.entity.name != "_bison_basket" else { return }
                    
                    // Trigger Bison behavior once
                    if !BisonAttracted {
                        _ = BisonEntity?.applyTapForBehaviors()
                        BisonAttracted = true
                    }
                    
                    // Convert entity and hand positions to world space
                    let entityWorldPos = value.entity.convert(position: .zero, to: nil)
                    let leftHandPos = LeftHandAnchor?.convert(position: .zero, to: nil) ?? SIMD3<Float>(repeating: .greatestFiniteMagnitude)
                    let rightHandPos = RightHandAnchor?.convert(position: .zero, to: nil) ?? SIMD3<Float>(repeating: .greatestFiniteMagnitude)
                    
                    // Compare distances to decide which hand to attach to
                    let leftDist = distance(leftHandPos, entityWorldPos)
                    let rightDist = distance(rightHandPos, entityWorldPos)
                    
                    CurrentHandAnchor = leftDist < rightDist ? LeftHandAnchor : RightHandAnchor
                    print("Assign \(leftDist < rightDist ? "Left" : "Right") Hand")
                    
                    let worldScale = value.entity.scale(relativeTo: nil)

                    // Attach entity to the chosen hand anchor
                    value.entity.removeFromParent()
                    value.entity.position = .zero
                    value.entity.setScale(worldScale, relativeTo: nil)
                    CurrentHandAnchor?.addChild(value.entity)

                    // Ensure anchor is added to the scene
                    if let anchor = CurrentHandAnchor {
                        SceneRootContent?.add(anchor)
                    }
                }
                .onEnded { value in
                    // Detach entity from hand and return it to BisonFoods in its original relative position
                    let draggedEntity = value.entity
                    let localPosition = draggedEntity.position(relativeTo: bisonFoodsEntity)

                    draggedEntity.removeFromParent()
                    draggedEntity.position = localPosition
                    bisonFoodsEntity?.addChild(draggedEntity)
                }
        )
        .onDisappear {
                
            timerCancellable?.cancel()
        }
    }
    
    func startMoving(){
        // Start a timer to move the object 1cm per second
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.environmentEntity?.position += SIMD3<Float>(x: 0, y: 0, z: 0.01)
            }
    }
    
    func assignEntity(named name: String, to binding: inout Entity?, disable: Bool = false) {
        if let entity = self.immersiveContentEntity?.findEntity(named: name) {
            binding = entity
            if disable {
                entity.isEnabled = false
            }
        }
    }

    
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
