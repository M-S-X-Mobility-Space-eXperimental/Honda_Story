import RealityKit
import SwiftUI

public final class EntityGestureState {
    
    // MARK: - Shared Instance
    
    @MainActor public static let shared = EntityGestureState()
    
    // MARK: - Drag State

    public var targetedEntity: Entity?
    public var dragStartPosition: SIMD3<Float> = .zero
    public var isDragging = false
    public var pivotEntity: Entity?
    public var initialOrientation: simd_quatf?

    // MARK: - Scale State

    public var startScale: SIMD3<Float> = .one
    public var isScaling = false

    // MARK: - Rotate State

    public var startOrientation = Rotation3D.identity
    public var isRotating = false

    private init() {}
}

// MARK: - Gesture Component

public struct GestureComponent: Component, Codable {
    
    public var canDrag: Bool = true
    public var pivotOnDrag: Bool = true
    public var preserveOrientationOnPivotDrag: Bool = true
    public var canScale: Bool = true
    public var canRotate: Bool = true
    
    public init() {}

    // MARK: - Drag Gesture Logic

    @MainActor public mutating func onChanged(value: EntityTargetValue<DragGesture.Value>) {
        guard canDrag else { return }
        let state = EntityGestureState.shared
        
        if state.targetedEntity == nil {
            state.targetedEntity = value.entity
            state.initialOrientation = value.entity.orientation(relativeTo: nil)
        }

        pivotOnDrag ? handlePivotDrag(value: value) : handleFixedDrag(value: value)
    }
    
    @MainActor private mutating func handlePivotDrag(value: EntityTargetValue<DragGesture.Value>) {
        let state = EntityGestureState.shared
        guard let entity = state.targetedEntity else {
            fatalError("Gesture contained no entity")
        }
        
        var targetPivotTransform = Transform()
        
        if let inputPose = value.inputDevicePose3D {
            targetPivotTransform.translation = value.convert(inputPose.position, from: .local, to: .scene)
            targetPivotTransform.rotation = value.convert(
                AffineTransform3D(rotation: inputPose.rotation),
                from: .local,
                to: .scene
            ).rotation
        } else {
            targetPivotTransform.translation = value.convert(value.location3D, from: .local, to: .scene)
        }

        if !state.isDragging {
            let pivotEntity = Entity()
            guard let parent = entity.parent else {
                fatalError("Non-root entity is missing a parent.")
            }

            parent.addChild(pivotEntity)
            pivotEntity.move(to: targetPivotTransform, relativeTo: nil)
            pivotEntity.addChild(entity, preservingWorldTransform: true)

            state.pivotEntity = pivotEntity
            state.isDragging = true
        } else {
            state.pivotEntity?.move(to: targetPivotTransform, relativeTo: nil, duration: 0.2)
        }

        if preserveOrientationOnPivotDrag, let initialOrientation = state.initialOrientation {
            state.targetedEntity?.setOrientation(initialOrientation, relativeTo: nil)
        }
    }

    @MainActor private mutating func handleFixedDrag(value: EntityTargetValue<DragGesture.Value>) {
        let state = EntityGestureState.shared
        guard let entity = state.targetedEntity else {
            fatalError("Gesture contained no entity")
        }

        if !state.isDragging {
            state.isDragging = true
            state.dragStartPosition = entity.scenePosition
        }

        let translation3D = value.convert(value.gestureValue.translation3D, from: .local, to: .scene)
        let offset = SIMD3<Float>(Float(translation3D.x), Float(translation3D.y), Float(translation3D.z))

        entity.scenePosition = state.dragStartPosition + offset

        if let initialOrientation = state.initialOrientation {
            state.targetedEntity?.setOrientation(initialOrientation, relativeTo: nil)
        }
    }

    @MainActor public mutating func onEnded(value: EntityTargetValue<DragGesture.Value>) {
        let state = EntityGestureState.shared
        state.isDragging = false

        if let pivotEntity = state.pivotEntity, pivotOnDrag {
            pivotEntity.parent?.addChild(state.targetedEntity!, preservingWorldTransform: true)
            pivotEntity.removeFromParent()
        }

        state.pivotEntity = nil
        state.targetedEntity = nil
    }

    // MARK: - Scale Gesture Logic

    @MainActor public mutating func onChanged(value: EntityTargetValue<MagnifyGesture.Value>) {
        let state = EntityGestureState.shared
        guard canScale, !state.isDragging else { return }

        let entity = value.entity

        if !state.isScaling {
            state.isScaling = true
            state.startScale = entity.scale
        }

        let magnification = Float(value.magnification)
        entity.scale = state.startScale * magnification
    }

    @MainActor public mutating func onEnded(value: EntityTargetValue<MagnifyGesture.Value>) {
        EntityGestureState.shared.isScaling = false
    }

    // MARK: - Rotate Gesture Logic

    @MainActor public mutating func onChanged(value: EntityTargetValue<RotateGesture3D.Value>) {
        let state = EntityGestureState.shared
        guard canRotate, !state.isDragging else { return }

        let entity = value.entity

        if !state.isRotating {
            state.isRotating = true
            state.startOrientation = Rotation3D(entity.orientation(relativeTo: nil))
        }

        let rotation = value.rotation
        let flipped = Rotation3D(angle: rotation.angle,
                                 axis: RotationAxis3D(x: -rotation.axis.x,
                                                      y: rotation.axis.y,
                                                      z: -rotation.axis.z))
        let newOrientation = state.startOrientation.rotated(by: flipped)
        entity.setOrientation(.init(newOrientation), relativeTo: nil)
    }

    @MainActor public mutating func onEnded(value: EntityTargetValue<RotateGesture3D.Value>) {
        EntityGestureState.shared.isRotating = false
    }
}
