//
//  Player.swift
//  Honda_story
//
//  Created by bwang on 4/1/25.
//

import Foundation

struct Vector3: Codable {
    var x: Float
    var y: Float
    var z: Float
}

struct Vector4: Codable {
    var x: Float
    var y: Float
    var z: Float
    var w: Float
}

struct GameObj: Codable {
    var controllerId: String
    var position: Vector3
    var rotation: Vector4
    var scale: Vector3
}

struct Player: Codable {
    var ready: Bool
    var tapped: Bool
//    var objectList: [GameObj]
}

