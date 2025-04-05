//
//  AppModel.swift
//  Honda_story
//
//  Created by messitu on 2/3/25.
//

import SwiftUI

@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    let contentWindowID = "ContentWindow"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var isContentWindowVisible = false

    func dismissContentWindow(using dismiss: DismissWindowAction) {
        dismiss(id: contentWindowID)
        isContentWindowVisible = false
    }

    func openContentWindow(using open: OpenWindowAction) {
        open(id: contentWindowID)
        isContentWindowVisible = true
    }
}
