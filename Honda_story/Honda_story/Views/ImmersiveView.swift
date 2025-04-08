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
    
    @State private var AudioEmitterEntity: Entity?
    
    @State private var environmentEntity: Entity?
    @State private var MovingCancellable: Cancellable?
    @State private var bisonFoodsEntity: Entity?
    @State private var bisonTransitTLEntity: Entity?
    @State private var bluegrassEntity: Entity?
    
    @State private var bisonWrongEntity: Entity?
    @State private var bisonCorrectEntity: Entity?

   
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
    @State private var BisonRightPlaying: Bool = false
    @State private var BisonWrongPlaying: Bool = false
    
    
    @State private var Timeline_GeyserEntity: Entity?
    
    @State private var LeftHandAnchor: AnchorEntity?
    @State private var RightHandAnchor: AnchorEntity?
    @State private var CurrentHandAnchor: AnchorEntity?
    
    @State private var lastCubePosition: SIMD3<Float>?
    @State private var cancellables = Set<AnyCancellable>()
    
    @State private var currentControllingObj: String?


    
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
                assignEntity(named: "BisonFoods", to: &bisonFoodsEntity, disable: true)
                assignEntity(named: "Eruption", to: &EruptionEntity, disable: true)
                assignEntity(named: "Bison", to: &BisonEntity)
                assignEntity(named: "bluegrass", to: &bluegrassEntity)
                assignEntity(named: "GeyserSandbox", to: &GeyserSandboxEntity, disable: true)
                assignEntity(named: "BisonTransitTL", to: &bisonTransitTLEntity)
                assignEntity(named: "Bison_End", to: &bisonCorrectEntity)
                assignEntity(named: "Bison_Wrong", to: &bisonWrongEntity)
                
                assignEntity(named: "AudioEmitter", to: &AudioEmitterEntity)
                
                
//                let hoverComponent = HoverEffectComponent()
//                GeyserSandboxEntity?.components.set(hoverComponent)
                
                initBisonFoodObjectList()
            }
        }
        .installGestures()
        .task{
            // First stage observe all ready
            dbModel.observeAllRealdy()
            trackGestureStates()
        }
        .onChange(of: dbModel.FinishBisonFoodInit){
            dbModel.observeBisonFoodChildUpdates { name, transform in
                if let entity = self.immersiveContentEntity?.findEntity(named: name) {
                    entity.transform = transform
                    print("🟡 Synced remote update to \(name)")
                    bisonFeedBackSequence(name: name)
                    
                }
            }
            
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 55) {
                    stopMoving()
                    print("🛑 Stopped movement for BisonExp.")
                }
                
           }
        }

        
        .simultaneousGesture(TapGesture().targetedToAnyEntity()
             .onEnded { value in
                 
                 let tappedEntity = value.entity
                 
                 if tappedEntity.name == "GeyserSandbox" {
                     dbModel.tapGeyser()
                 }
                 
         })
        .onDisappear {
                
            MovingCancellable?.cancel()
        }
    }
    
    func startMoving(){
        // Start a timer to move the object 1cm per second
        MovingCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.environmentEntity?.position += SIMD3<Float>(x: 0, y: 0, z: 0.01)
            }
    }
    
    func stopMoving() {
        MovingCancellable?.cancel()
        MovingCancellable = nil
    }
    
    func assignEntity(named name: String, to binding: inout Entity?, disable: Bool = false) {
        if let entity = self.immersiveContentEntity?.findEntity(named: name) {
            binding = entity
            if disable {
                entity.isEnabled = false
            }
        }
    }
    
    func trackGestureStates() {
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let state = EntityGestureState.shared

                guard state.isDragging || state.isScaling || state.isRotating,
                      let entity = state.targetedEntity else {
                    
                    if (currentControllingObj != nil){
                        dbModel.releaseBisonFoodControl(forName: currentControllingObj!)
                    }
                    
                    return
                }

                let name = entity.name
                guard !name.isEmpty else { return }
                
                bisonFeedBackSequence(name: name)
                
                currentControllingObj = name

                let transform = entity.transform
                DBModel.shared.updateBisonFoodProperty(forName: name, withTransform: transform)
            }
            .store(in: &cancellables)
    }
    
    func bisonFeedBackSequence(name: String){
        let correct: Bool
        if(name == "bluegrass"){
            correct = true
        }else{
            correct = false
        }
        
        if(correct){
            if(!BisonRightPlaying){
                BisonRightPlaying = true
                _ = BisonEntity?.applyTapForBehaviors()
                _ = bisonCorrectEntity?.applyTapForBehaviors()
            }
        }else{
            if(!BisonWrongPlaying){
                BisonWrongPlaying = true
                _ = bisonWrongEntity?.applyTapForBehaviors()
                
                // reset BisonWrong playing
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    BisonWrongPlaying = false
                }
            }
        }
    }
    
    func initBisonFoodObjectList() {
        guard let bisonFoods = bisonFoodsEntity else {
            print("bisonFoodsEntity not initialized.")
            return
        }

        var objectDict: [String: Any] = [:]

        for child in bisonFoods.children {
            let name = child.name
            guard !name.isEmpty else {
                print("⚠️ Skipping unnamed entity.")
                continue
            }

            let pos = child.position(relativeTo: nil)
            let rotQuat = child.orientation(relativeTo: nil).vector
            let scale = child.scale(relativeTo: nil)

            let gameObj = GameObj(
                controllerId: "N/A",
                position: Vector3(x: pos.x, y: pos.y, z: pos.z),
                rotation: Vector4(x: rotQuat.x, y: rotQuat.y, z: rotQuat.z, w: rotQuat.w),
                scale: Vector3(x: scale.x, y: scale.y, z: scale.z)
            )

            // Store as dictionary for Firebase
            if let encoded = try? JSONEncoder().encode(gameObj),
               let jsonObj = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
                objectDict[name] = jsonObj
            }
        }
        
        dbModel.initalizeDB_BisonFoods(objectDict)
    }


    
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
