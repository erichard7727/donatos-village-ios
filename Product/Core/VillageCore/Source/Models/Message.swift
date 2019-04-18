//
//  Message.swift
//  VillageCore
//
//  Created by Allie Galuska on 4/17/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public struct Message {
    public let id: String
    public let person: Person?
    public let text: String?
    public let ownderDisplayName: String?
    public let lastUpdated: String?
    public let createdDate: String?
    //    public let attachment: MediaAttachment? TODO: Not the same as MediaAttachment, also maybe not needed...?
    public let streamId: String
    public let likesCount: Int?
    public let hasUserLikedMessage: Bool?
    public let isSystem: Bool?
}
