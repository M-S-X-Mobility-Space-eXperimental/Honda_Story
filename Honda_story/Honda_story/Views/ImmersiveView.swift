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

import ARKit

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
    @State private var eatingRefEntity: Entity?

    @State private var ProgressBarEntity: Entity?
    @State private var HeatBarEntity: Entity?
    @State private var PressureBarEntity: Entity?
    @State private var EruptionEntity: Entity?
    @State private var GeyserSandboxEntity: Entity?
    @State private var GeyserSoundTLEntity: Entity?
    
    @State private var timelineGeyser:Entity?
    @State private var BisonEntity: Entity?
//    @State private var CountDownEntity: Entity?
    @State private var TestCubeEntity: Entity?
    
    @State private var HumanEntity: Entity? // For Occlusion
    
    @State private var RootEntity: Entity?
    
    @State private var GeyserErupt: Bool = false
    @State private var BisonAttracted: Bool = false
    @State private var BisonRightPlaying: Bool = false
    @State private var BisonWrongPlaying: Bool = false
    
    @State private var HeatOrPressure: String = ""
    
    
    @State private var Timeline_GeyserEntity: Entity?
    
    @State private var LeftHandAnchor: AnchorEntity?
    @State private var RightHandAnchor: AnchorEntity?
    @State private var CurrentHandAnchor: AnchorEntity?
    
    @State private var RefImageAnchor: AnchorEntity?
    @State private var refImageAnchorPosition: SIMD3<Float> = .zero
    @State private var refImageAnchorOrientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 0)

    
    @State private var lastCubePosition: SIMD3<Float>?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var subscriptions: [EventSubscription] = []

    
    @State private var currentControllingObj: String?


    
    @StateObject var dbModel = DBModel.shared

    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            
            if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                
                content.add(immersiveContentEntity)
                
                self.immersiveContentEntity = immersiveContentEntity
                self.SceneRootContent = content
                
                
                let occlusionMaterial = OcclusionMaterial()
                
                // Hand Tracking Setup
                let session = SpatialTrackingSession()
                let configuration = SpatialTrackingSession.Configuration(tracking: [.hand, .world,.image])
                
                _ = await session.run(configuration)
                self.session = session
               //Setup an anchor at the user's left palm.
                self.LeftHandAnchor = AnchorEntity(.hand(.left, location: .palm), trackingMode: .continuous)
                self.RightHandAnchor = AnchorEntity(.hand(.right, location: .palm), trackingMode: .continuous)
                
                self.RefImageAnchor = AnchorEntity(.image(group: "MSX_QR", name: "Ref"), trackingMode: .continuous)
                
                
                
//                let leftSphere = ModelEntity(
//                    mesh: .generateSphere(radius: 0.07), // 1 cm radius
//                    materials: [occlusionMaterial]
//                )
//                
//                let rightSphere = ModelEntity(
//                    mesh: .generateSphere(radius: 0.07),
//                    materials: [occlusionMaterial]
//                )
//                
//                self.LeftHandAnchor?.addChild(leftSphere)
//                self.RightHandAnchor?.addChild(rightSphere)
                
            
                
                
                content.add(LeftHandAnchor!)
                content.add(RightHandAnchor!)
                content.add(RefImageAnchor!)

                assignEntity(named: "GeyserSoundTL", to: &GeyserSoundTLEntity)
                assignEntity(named: "Environment", to: &environmentEntity)
                assignEntity(named: "BisonFoods", to: &bisonFoodsEntity, disable: true, hide: true )
//                assignEntity(named: "BisonFoods", to: &bisonFoodsEntity, disable: false, hide: false )
                assignEntity(named: "Eruption", to: &EruptionEntity, disable: true)
                assignEntity(named: "Bison", to: &BisonEntity, hide:true)
//                assignEntity(named: "Bison", to: &BisonEntity, hide:false)
                assignEntity(named: "bluegrass", to: &bluegrassEntity)
                assignEntity(named: "GeyserSandbox", to: &GeyserSandboxEntity, disable: false, hide: true)
                assignEntity(named: "BisonTransitTL", to: &bisonTransitTLEntity)
                assignEntity(named: "Bison_End", to: &bisonCorrectEntity)
                assignEntity(named: "Bison_Wrong", to: &bisonWrongEntity)
                assignEntity(named: "Eating_Reference", to: &eatingRefEntity)
                
                assignEntity(named: "UIHeat", to: &HeatBarEntity)
                assignEntity(named: "UIPressure", to: &PressureBarEntity)
                
//                assignEntity(named: "Human0", to: &HumanEntity)
                
                assignEntity(named: "AudioEmitter", to: &AudioEmitterEntity)
                assignEntity(named: "Root", to: &RootEntity)
                
                
                
                if(!dbModel.facing_forward){
                    RootEntity?.position = SIMD3<Float>(0.2, 0, -1.5)
                    RootEntity?.transform.rotation = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 1, 0))
                    
                    
                    // controlling different part of
                    assignEntity(named: "UIHeat", to: &ProgressBarEntity)
                    HeatOrPressure = "Heat"
                    
                    
                    
                    assignEntity(named: "B_Human", to: &HumanEntity)
                    dbModel.observePressure()
                        
                }else{
                    assignEntity(named: "UIPressure", to: &ProgressBarEntity)
                    HeatOrPressure = "Pressure"
                    
                    assignEntity(named: "F_Human", to: &HumanEntity)
                    dbModel.observeHeat()
                    
                }


                // Create the capsule ModelEntity
                let capsuleEntity = ModelEntity(
                    mesh: .generateCylinder(height: 0.7, radius: 0.25),
                    materials: [occlusionMaterial]
                )
                
                // Match the transform of the target entity
                capsuleEntity.position = HumanEntity!.position(relativeTo: nil)
                content.add(capsuleEntity)
                
                
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
            trackClappingHands()
            
//            trackWorldReferenceImage()
        }
//        .onChange(of: refImageAnchorPosition){
//            
//            print(refImageAnchorPosition)
//            
//            let offset_fromRef = SIMD3<Float>(-2, -1, 1)
//            
//            let offset_fromRef_Ori = simd_mul(simd_quatf(angle: .pi/2, axis: SIMD3<Float>(1, 0, 0)), simd_quatf(angle: .pi/2, axis: SIMD3<Float>(0, 1, 0)))
//            
//            
//            if length_squared(refImageAnchorPosition) > 0 {
//                
//                print("Updating Root position")
//                RootEntity?.position = refImageAnchorPosition + offset_fromRef
//                RootEntity?.transform.rotation = simd_mul( refImageAnchorOrientation, offset_fromRef_Ori)
//            }
//            
//        }
        .onChange(of: dbModel.FinishBisonFoodInit){
            dbModel.observeBisonFoodChildUpdates { name, transform in
                
                // Add this condition to prevent hearing bison in the beginning
                if dbModel.Geyser{
                    if let entity = self.immersiveContentEntity?.findEntity(named: name) {
                        entity.transform = transform
                        print("🟡 Synced remote update to \(name)")
                        bisonFeedBackSequence(name: name, entity: entity)
                        
                    }
                }
            }
            
        }
        .onChange(of: dbModel.startGeyserExp) {
            if dbModel.startGeyserExp{
                GeyserSandboxEntity?.isEnabled = true
                print(GeyserSoundTLEntity ?? "GeyserSoundTLEntity is nil")
                
                _ = GeyserSoundTLEntity?.applyTapForBehaviors()
                
                startMoving()
                
                dbModel.ObserveAllTapped()
           }
            
            //reset ready for next round
            dbModel.playerResetReady()
        }
        
        .onChange(of: dbModel.Heat) {
            HeatBarEntity?.transform.scale = SIMD3<Float>(x: Float(dbModel.Heat), y: 1, z: 1)
        }
        .onChange(of: dbModel.Pressure) {
            PressureBarEntity?.transform.scale = SIMD3<Float>(x: Float(dbModel.Pressure), y: 1, z: 1)
        }
        
        .onChange(of: dbModel.Geyser) {
            if dbModel.Geyser {
                print("Enabling Eruption")
                EruptionEntity?.isEnabled = true
                bisonFoodsEntity?.isEnabled = true
                GeyserErupt = true
                
//                CountDownEntity?.isEnabled = false
                
                _ = GeyserSandboxEntity?.applyTapForBehaviors()
                _ = bisonTransitTLEntity?.applyTapForBehaviors()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 49) {
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
                self.environmentEntity?.position += SIMD3<Float>(x: 0, y: 0, z: 0.05)
//                print(self.environmentEntity?.position.z ?? "0")
                if((self.environmentEntity?.position.z)! > 160){
                    self.environmentEntity?.position.z = 0
                }
            }
    }
    
    func stopMoving() {
        MovingCancellable?.cancel()
        MovingCancellable = nil
    }
    
    func assignEntity(named name: String, to binding: inout Entity?, disable: Bool = false, hide: Bool = false) {
        if let entity = self.immersiveContentEntity?.findEntity(named: name) {
            binding = entity
            if disable {
                entity.isEnabled = false
            }
            
            if hide{
                entity.components[OpacityComponent.self]?.opacity = 0
            }
        }
    }
    
    func fadeOutOpacity(for entity: Entity, duration: TimeInterval = 3.0, step: TimeInterval = 0.05) {
        guard let opacityComponent = entity.components[OpacityComponent.self] else {
            print("Entity has no OpacityComponent")
            return
        }
        
        
        var currentOpacity = opacityComponent.opacity
        let steps = Int(duration / step)
        let decrement = currentOpacity / Float(steps)
        
        let startPos = entity.position(relativeTo: nil)
        let endPos = (eatingRefEntity?.position(relativeTo: nil))!
        let deltaPos = (endPos - startPos) / Float(steps)

        Timer.scheduledTimer(withTimeInterval: step, repeats: true) { timer in
            currentOpacity -= decrement
            currentOpacity = max(0, currentOpacity)

            entity.components.set(OpacityComponent(opacity: currentOpacity))
            
            let newPos = entity.position(relativeTo: nil) + deltaPos
            entity.setPosition(newPos, relativeTo: nil)

            if distance(newPos, endPos) <= 0.1 {
                entity.isEnabled = false
                timer.invalidate()
            }
        }
    }
    
    func trackClappingHands() {
        let clapThreshold: Float = 0.05 // 3 cm
        var hasClapped = false

        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard let leftHand = self.LeftHandAnchor,
                  let rightHand = self.RightHandAnchor else {
                return
            }

            let leftPos = leftHand.position(relativeTo: nil)
            let rightPos = rightHand.position(relativeTo: nil)

            let distance = simd_distance(leftPos, rightPos)

            if distance < clapThreshold {
                if !hasClapped {
                    hasClapped = true
                    print("👏 Clap detected!")
                    
                    if((ProgressBarEntity?.transform.scale.x)! >= 0.95){
                        
                        dbModel.tapGeyser()
                        return
                    }
                    
                    ProgressBarEntity?.transform.scale.x += 0.1
                    
                    if((ProgressBarEntity?.transform.scale.x)! >= 1){
                        ProgressBarEntity?.transform.scale.x = 1
                    }
                    
                    
                    dbModel.setHeatPressure(name: HeatOrPressure, value: Float((ProgressBarEntity?.transform.scale.x)!))
                    
                    
                }
            } else {
                hasClapped = false
                
                if ((ProgressBarEntity?.transform.scale.x)! > 0){
                    ProgressBarEntity?.transform.scale.x -= 0.005
                    
                    dbModel.setHeatPressure(name: HeatOrPressure, value: Float((ProgressBarEntity?.transform.scale.x)!))
                }
            }
        }
    }


    
    
    
    func trackGestureStates() {
        Timer.publish(every: 0.05, on: .main, in: .common)
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
                if entity.parent?.name != "BisonFoods" {return}
                
                
                
               
                bisonFeedBackSequence(name: name, entity:entity)

                
                // enable gravity after moving
//                entity.components[PhysicsBodyComponent.self]?.mode = .dynamic
                
                
                
                currentControllingObj = name

                let transform = entity.transform
                DBModel.shared.updateBisonFoodProperty(forName: name, withTransform: transform)
            }
            .store(in: &cancellables)
    }
    
    
    func bisonFeedBackSequence(name: String, entity: Entity?){
        
        
        let distance_To_bison = distance(entity?.position(relativeTo: nil) ?? SIMD3<Float>.zero, (eatingRefEntity?.position(relativeTo: nil))! )
        
        if distance_To_bison > 2 {
            // Not trigger effects
            return
        }
        
        fadeOutOpacity(for: entity!)
        
        let correct: Bool
        if(name == "bluegrass"){
            correct = true
            immersiveContentEntity?.stopAllAudio()
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
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
    
    func trackWorldReferenceImage(){
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let anchor = RefImageAnchor {
                let newPosition = anchor.position(relativeTo: nil)
                let newRotation = anchor.orientation(relativeTo: nil)
                if distance(newPosition, refImageAnchorPosition) > 0.01 {
                    refImageAnchorPosition = newPosition
                    refImageAnchorOrientation = newRotation
                    print(refImageAnchorOrientation)
                }
                
                
                
                let deltaQuat  = simd_normalize(simd_mul(simd_inverse(newRotation), refImageAnchorOrientation))
                
                let angleDifference = abs(deltaQuat.angle)
                
                if angleDifference > 0.01 {
                    refImageAnchorOrientation = newRotation
                }
            }
        }
    }

    
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
