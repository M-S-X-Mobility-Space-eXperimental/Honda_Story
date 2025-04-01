//
//  Player.swift
//  Honda_story
//
//  Created by bwang on 4/1/25.
//

import Foundation

struct Vector3: Codable {
    var x: Double
    var y: Double
    var z: Double
}

struct GameObj: Codable {
    var controllerId: String
    var position: Vector3
}

struct Player: Codable {
    var ready: Bool
    var tapped: Bool
    var objectList: [GameObj]
}

