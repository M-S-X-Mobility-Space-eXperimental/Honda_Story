//
//  TapPlayer.swift
//  Honda_story
//
//  Created by bwang on 3/26/25.
//

import SwiftUI
import Firebase
import FirebaseDatabase

class TapViewModel: ObservableObject {
    private var ref: DatabaseReference = Database.database().reference()
    private var userId: String
    @Published var tapped = false
    @Published var Geyser: Bool = false
    
    init(userId: String) {
        self.userId = userId
        ref.child("Geyser").setValue(false)
    }
    
    func tap(completion: @escaping (Bool) -> Void) {
        let timestamp = Date().timeIntervalSince1970
        tapped = true
        
        ref.child("players/\(userId)").updateChildValues([
            "tapped": true,
            "timestamp": timestamp
        ])
        
        let opponentId = userId == "0" ? "1" : "0"
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            self.ref.child("players/\(opponentId)/tapped").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self,
                      let opponentTapped = snapshot.value as? Bool else {
                    self?.resetTapAfterDelay()
                    completion(false)
                    return
                }

                if opponentTapped {
                    print("Both tapped!")
                    self.ref.child("Geyser").setValue(true)
                    completion(true)
                } else {
                    self.resetTapAfterDelay()
                    completion(false)
                }
            }
        }
    }
    
    private func resetTapAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.tapped = false
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
}
