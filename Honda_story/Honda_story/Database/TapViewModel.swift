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
    
    init(userId: String) {
        self.userId = userId
    }
    
    func tap(completion: @escaping (Bool) -> Void) {
        let timestamp = Date().timeIntervalSince1970
        tapped = true
        
        ref.child("players/\(userId)").updateChildValues([
            "tapped": true,
            "timestamp": timestamp
        ])
        
        let opponentId = userId == "0" ? "1" : "0"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.ref.child("players").observeSingleEvent(of: .value) { [weak self] snapshot in
                guard let self = self,
                      let data = snapshot.value as? [String: Any],
                      let userData = data[self.userId] as? [String: Any],
                      let opponentData = data[opponentId] as? [String: Any],
                      let userTapped = userData["tapped"] as? Bool,
                      let opponentTapped = opponentData["tapped"] as? Bool else{
                    self?.resetTapAfterDelay()
                    completion(false)
                    return
                }
                
                
                if userTapped && opponentTapped {
                    print("Both tapped!")
                    completion(true)
                } else {
                    self.resetTapAfterDelay()
                    completion(false)
                }
            }
        }
    }
    
    private func resetTapAfterDelay() {	
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.tapped = false
            self.ref.child("players/\(self.userId)/tapped").setValue(false)
        }
    }
}
