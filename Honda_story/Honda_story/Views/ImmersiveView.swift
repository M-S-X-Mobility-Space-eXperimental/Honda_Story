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
    @State private var bisonTransitTLEntity: Entity?
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
            assignEntity(named: "BisonTransitTL", to: &bisonTransitTLEntity)
            assignEntity(named: "BisonFoods", to: &bisonFoodsEntity, disable: false)
            assignEntity(named: "Eruption", to: &EruptionEntity, disable: true)
            assignEntity(named: "Bison", to: &BisonEntity)
            assignEntity(named: "bluegrass", to: &bluegrassEntity)
            assignEntity(named: "GeyserSandbox", to: &GeyserSandboxEntity, disable: true)
                            
            }
        }
        .task{
            dbModel.observeGeyser()
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
                _ = bisonTransitTLEntity?.applyTapForBehaviors()
                
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
                    if value.entity.parent?.name == "BisonFoods"{
//                    if value.entity.name == "bluegrass" {
                        // Update position to match drag location in 3D
                        
                        if(!BisonAttracted){
                            _ = BisonEntity?.applyTapForBehaviors()
                            BisonAttracted = true
                        }
                        
                        let entityWorldPos = value.entity.convert(position: .zero, to: nil)
                        let leftHandWorldPos = self.LeftHandAnchor?.convert(position: .zero, to: nil) ?? SIMD3<Float>(10000,10000,10000)
                        let rightHandWorldPos = self.RightHandAnchor?.convert(position: .zero, to: nil) ?? SIMD3<Float>(10000,10000,10000)
                        
                        let leftDist = distance(leftHandWorldPos, entityWorldPos)
                        let rightDist = distance(rightHandWorldPos, entityWorldPos)
                        
                        print("left Dist:",leftDist)
                        print("right dist:",rightDist)
                        
                        if(leftDist < rightDist){
                            print("Assign Left")
                            CurrentHandAnchor = self.LeftHandAnchor
                            
                        }else{
                            print("Assign Right")
                            CurrentHandAnchor = self.RightHandAnchor
                        }
                        
                        value.entity.position = SIMD3<Float>(0,0,0)
                        self.CurrentHandAnchor?.addChild(value.entity)
                        SceneRootContent?.add(CurrentHandAnchor!)
                        
                    }
                }
                .onEnded { value in
                       let draggedEntity = value.entity
                       let worldPosition = draggedEntity.position(relativeTo: bisonFoodsEntity)

                       draggedEntity.removeFromParent()

                       draggedEntity.position = worldPosition

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
