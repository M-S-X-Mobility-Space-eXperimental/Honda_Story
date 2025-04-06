//
//  TapPlayer.swift
//  Honda_story
//
//  Created by bwang on 3/26/25.
//

import SwiftUI
import Firebase
import FirebaseDatabase

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
    
    // DB Handle
    private var allTappedHandle: DatabaseHandle?

    private init() { // Make the initializer private to enforce singleton
        self.userId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        print(self.userId)
        
        initializeCurrentPlayer()
        
        // This is for game state changes
        ref.child("Geyser").setValue(false)
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 40) {
                        self.startGeyserExp = true
                        
                        print("35 seconds passed for all palyer ready. Geyser exp started.")
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
    
    func createDefaultObjectList(count: Int) -> [[String: Any]] {
        return (0..<count).map { _ in
            return [
                "controllerId": userId,
                "position": [
                    "x": 0.0,
                    "y": 0.0,
                    "z": 0.0
                ]
            ]
        }
    }
    
    func initializeCurrentPlayer(objectCount: Int = 2) {
        let objectList = createDefaultObjectList(count: objectCount)

        let initialData: [String: Any] = [
            "ready": false,
            "tapped": false,
            "objectList": objectList
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
}
