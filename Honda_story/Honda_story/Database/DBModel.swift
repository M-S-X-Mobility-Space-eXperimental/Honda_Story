//
//  TapPlayer.swift
//  Honda_story
//
//  Created by bwang on 3/26/25.
//

import SwiftUI
import Firebase
import FirebaseDatabase
import RealityFoundation

class DBModel: ObservableObject {
    static let shared = DBModel()
    
    private var ref: DatabaseReference = Database.database().reference()
    private var userId: String

    // Game State Variables
    @Published var Geyser: Bool = false // for eruption
    @Published var startGeyserExp = false
    private var geyserStarted = false // <-- Add this to prevent multiple triggers
    
    // Player State Variables
    @Published var AllReady: Bool = false
    @Published var AllTapped: Bool = false
    @Published var FinishBisonFoodInit: Bool = false
    
    // DB Handle
    private var allTappedHandle: DatabaseHandle?

    private init() { // Make the initializer private to enforce singleton
        self.userId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        print(self.userId)
        
        initializeCurrentPlayer()
        
        // This is for game state changes
        ref.child("Geyser").setValue(false)
    }
    
    func getUserID() -> String{
        return self.userId
    }
    
    func tapGeyser() {
        ref.child("players/\(userId)").updateChildValues([
            "tapped": true,
        ])
        
        self.ObserveAllTapped()
        self.resetTapAfterDelay()
    }

    
    private func resetTapAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.ref.child("players/\(self.userId)/tapped").setValue(false)
        }
    }
    
    func observeGeyser() {
        ref.child("Geyser").observe(.value, with: { [weak self] snapshot in
            guard let self = self else { return }
            
            if let geyserValue = snapshot.value as? Bool {
                DispatchQueue.main.async {
                    self.Geyser = geyserValue
                    print("Geyser value changed to: \(geyserValue)")
                }
            } else {
                print("Failed to read Geyser value")
            }
        })
    }
    
    
    func ObserveAllTapped(){
        allTappedHandle = ref.child("players").observe(.value, with: { [weak self] snapshot in
            guard let self = self else { return }

            let players = self.parsePlayers(snapshot: snapshot)
            let allTapped = self.allPlayersTapped(players: players)

            DispatchQueue.main.async {
                self.AllTapped = allTapped
                if(!self.Geyser){
                    if(self.AllTapped){
                        self.Geyser = true
                        self.ref.child("Geyser").setValue(true)
                        
                        if let handle = self.allTappedHandle {
                            self.ref.child("players").removeObserver(withHandle: handle)
                            self.allTappedHandle = nil // clean up
                        }
                    }
                }
                print("All players tapped: \(allTapped)")
            }
        })
    }
    
    
    func observeAllRealdy() {
        ref.child("players").observe(.value, with: { [weak self] snapshot in
            guard let self = self else { return }

            let players = self.parsePlayers(snapshot: snapshot)
            let allReady = self.allPlayersReady(players: players)

            DispatchQueue.main.async {
                self.AllReady = allReady
                print("All players ready: \(allReady)")
                if allReady && !self.geyserStarted {
                    self.geyserStarted = true // prevent re-trigger
                    self.ref.child("ReadyTime").observeSingleEvent(of: .value) { snapshot in
                        guard let readyTimestamp = snapshot.value as? TimeInterval else {
                            print("Failed to get ReadyTime from database")
                            return
                        }

                        let currentTime = Date().timeIntervalSince1970
                        let timeElapsed = currentTime - readyTimestamp
                        let delay = max(0, 37 - timeElapsed)

                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.startGeyserExp = true
                            print("Geyser experiment started after delay of \(delay) seconds")
                        }
                    }
                }
            }
        })
    }
    
    func playerResetReady(){
        //reset the ready variable for next round
        self.ref.child("players/\(self.userId)").updateChildValues([
            "ready": false,
        ])
    }

    
    func allPlayersReady(players: [String: Player]) -> Bool {
        return players.values.allSatisfy { $0.ready }
    }
    
    func allPlayersTapped(players: [String: Player]) -> Bool {
        return players.values.allSatisfy { $0.tapped }
    }
    
    func initalizeDB_BisonFoods(_ objectDict: [String: Any]) {
        ref.child("/BisonFoods").setValue(objectDict) { error, _ in
            if let error = error {
                print("🔥 Upload failed: \(error.localizedDescription)")
            } else {
                print("✅ Upload succeeded.")
                self.FinishBisonFoodInit = true
            }
        }
    }


    
    func initializeCurrentPlayer(objectCount: Int = 2) {
//        let objectList = createDefaultObjectList(count: objectCount)

        let initialData: [String: Any] = [
            "ready": false,
            "tapped": false,
//            "objectList": objectList
        ]

        ref.child("players/\(self.userId)").setValue(initialData) { error, _ in
            if let error = error {
                print("Failed to initialize player: \(error)")
            } else {
                print("Player \(self.userId) initialized with \(objectCount) objects.")
            }
        }
    }
    
    func setPlayerReady(){
        ref.child("players/\(userId)").updateChildValues([
            "ready": true,
        ])
        
        let timestamp = Int(Date().timeIntervalSince1970)
        
        ref.updateChildValues([
            "ReadyTime": timestamp
        ])
    }
    
    func parsePlayers(snapshot: DataSnapshot) -> [String: Player] {
        var players = [String: Player]()

        for child in snapshot.children {
            if let childSnapshot = child as? DataSnapshot,
               let value = childSnapshot.value as? [String: Any] {
                do {
                    let data = try JSONSerialization.data(withJSONObject: value)
                    let player = try JSONDecoder().decode(Player.self, from: data)
                    players[childSnapshot.key] = player
                } catch {
                    print("Error decoding player \(childSnapshot.key): \(error)")
                }
            }
        }

        return players
    }
    
    func updateBisonFoodProperty(forName name: String, withTransform transform: Transform) {
        let userId = self.getUserID()

        let gameObj: [String: Any] = [
            "controllerId": userId,
            "position": [
                "x": transform.translation.x,
                "y": transform.translation.y,
                "z": transform.translation.z
            ],
            "rotation": [
                "x": transform.rotation.vector.x,
                "y": transform.rotation.vector.y,
                "z": transform.rotation.vector.z,
                "w": transform.rotation.vector.w
            ],
            "scale": [
                "x": transform.scale.x,
                "y": transform.scale.y,
                "z": transform.scale.z
            ]
        ]

        ref.child("BisonFoods/\(name)").setValue(gameObj) { error, _ in
            if let error = error {
                print("🔥 Failed to update BisonFood '\(name)': \(error.localizedDescription)")
            }
        }
    }
    
    func releaseBisonFoodControl(forName name: String) {
        let releaseData: [String: Any] = [
            "controllerId": "N/A"
        ]

        ref.child("BisonFoods/\(name)").updateChildValues(releaseData) { error, _ in
            if let error = error {
                print("❌ Failed to release control of '\(name)': \(error.localizedDescription)")
            }
        }
    }
    
    func observeBisonFoodChildUpdates(onUpdate: @escaping (_ name: String, _ transform: Transform) -> Void) {
        let userId = self.getUserID()

        ref.child("BisonFoods").observe(.childChanged) { snapshot in
            let name = snapshot.key

            guard let data = snapshot.value as? [String: Any],
                  let controllerId = data["controllerId"] as? String,
                  controllerId != userId else {
                return
            }

            guard let pos = data["position"] as? [String: Any],
                  let rot = data["rotation"] as? [String: Any],
                  let scale = data["scale"] as? [String: Any],
                  let px = (pos["x"] as? NSNumber)?.floatValue,
                  let py = (pos["y"] as? NSNumber)?.floatValue,
                  let pz = (pos["z"] as? NSNumber)?.floatValue,
                  let rx = (rot["x"] as? NSNumber)?.floatValue,
                  let ry = (rot["y"] as? NSNumber)?.floatValue,
                  let rz = (rot["z"] as? NSNumber)?.floatValue,
                  let rw = (rot["w"] as? NSNumber)?.floatValue,
                  let sx = (scale["x"] as? NSNumber)?.floatValue,
                  let sy = (scale["y"] as? NSNumber)?.floatValue,
                  let sz = (scale["z"] as? NSNumber)?.floatValue
            else {
                print("⚠️ Incomplete transform data for \(name)")
                return
            }

            let transform = Transform(
                scale: SIMD3<Float>(sx, sy, sz),
                rotation: simd_quatf(ix: rx, iy: ry, iz: rz, r: rw),
                translation: SIMD3<Float>(px, py, pz)
            )

            onUpdate(name, transform)
        }
    }


}
