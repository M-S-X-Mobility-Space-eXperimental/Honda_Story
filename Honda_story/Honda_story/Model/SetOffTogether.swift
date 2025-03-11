//
//  File.swift
//  Honda_story
//
//  Created by messitu on 3/11/25.
//

import Foundation
import GroupActivities
import CoreTransferable

struct SetOffTogetherActivity: GroupActivity, Transferable, Sendable {
    var metadata: GroupActivityMetadata = {
        var metadata = GroupActivityMetadata()
        metadata.title = "Set Off Together"
        metadata.type = .generic
        return metadata
    }()
}
