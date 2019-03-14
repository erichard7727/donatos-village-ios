//
//  KudosService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/14/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum KudosServiceError: Error {
    case unknown
}

struct KudosService {
    
    private init() { }
    
    static func getKudosReceived(for person: Person, page: Int = 1) -> Promise<Kudos> {
        return getKudos(.received, for: person, page: page)
    }
    
    static func getKudosGiven(for person: Person, page: Int = 1) -> Promise<Kudos> {
        return getKudos(.given, for: person, page: page)
    }
    
    static func getKudos(_ kudoType: VillageCoreAPI.KudoType, for person: Person, page: Int = 1) -> Promise<Kudos> {
        return firstly {
            let kudos = VillageCoreAPI.kudos(kudoType, personId: person.id.description, page: page)
            return VillageService.shared.request(target: kudos)
        }.then { (json: JSON) -> Kudos in
            let kudos = json["kudos"].arrayValue.compactMap({ Kudo(from: $0) })
            return kudos
        }
    }
    
}

// MARK: - SwiftyJSON Extensions

fileprivate extension Kudo {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].int,
            let achievementId = response["achievementId"].string,
            let achievementTitle = response["achievementTitle"].string,
            let comment = response["comment"].string,
            let receiver = Person(from: response["receiver"]),
            let sender = Person(from: response["sender"]),
            let date = response["dateCreated"].string
        else {
            return nil
        }
        
        self = Kudo.init(
            id: id,
            achievementId: achievementId,
            achievementTitle: achievementTitle,
            comment: comment,
            points: response["points"].int ?? 1,
            receiver: receiver,
            sender: sender,
            date: date
        )
    }
    
}
