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
    
    static func getKudosStream(for person: Person, page: Int = 1) -> Promise<Kudos> {
        return getKudos(.all, for: person, page: page)
    }
    
    static func getKudosReceived(for person: Person, achievement: Achievement? = nil, page: Int = 1) -> Promise<Kudos> {
        return getKudos(.received, for: person, achievement: achievement, page: page)
    }
    
    static func getKudosGiven(for person: Person, achievement: Achievement? = nil, page: Int = 1) -> Promise<Kudos> {
        return getKudos(.given, for: person, achievement: achievement, page: page)
    }
    
    static func getKudos(_ kudoType: VillageCoreAPI.KudoType, for person: Person, achievement: Achievement? = nil, page: Int = 1) -> Promise<Kudos> {
        return firstly {
            let kudos = VillageCoreAPI.kudos(kudoType, personId: person.id.description, achievementId: achievement?.id, page: page)
            return VillageService.shared.request(target: kudos)
        }.then { (json: JSON) -> Kudos in
            let kudos = json["kudos"].arrayValue.compactMap({ Kudo(from: $0) })
            return kudos
        }
    }
    
    static func givableAchievements(page: Int = 1) -> Promise<Achievements> {
        return firstly {
            let achievements = VillageCoreAPI.givableAchievements(page: page)
            return VillageService.shared.request(target: achievements)
        }.then { (json: JSON) -> Achievements in
            let achievements = json["achievements"].arrayValue.compactMap({ Achievement(from: $0) })
            return achievements
        }
    }
    
    static func getAchievements(for person: Person, page: Int = 1) -> Promise<Achievements> {
        return firstly {
            let achievements = VillageCoreAPI.achievements(personId: person.id.description, page: page)
            return VillageService.shared.request(target: achievements)
        }.then { (json: JSON) -> Achievements in
            let achievements = json["achievements"].arrayValue.compactMap({ Achievement(from: $0) })
            return achievements
        }
    }
    
    static func giveKudo(to person: Person, for achievement: Achievement, points: Int = 1, comment: String) -> Promise<Void> {
        let giveKudo = VillageCoreAPI.giveKudo(
            receiverId: person.id,
            achievementId: achievement.id,
            points: points,
            comment: comment
        )
        return VillageService.shared.request(target: giveKudo).asVoid()
    }
    
    static func getLeaderboard(page: Int = 1) -> Promise<People> {
        return firstly {
            let leaderboard = VillageCoreAPI.kudosLeaderboard(page: page, days: nil)
            return VillageService.shared.request(target: leaderboard)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
        }
    }
    
    static func getWeeklyLeaderboard(page: Int = 1) -> Promise<People> {
        return firstly {
            let leaderboard = VillageCoreAPI.kudosLeaderboard(page: page, days: 7)
            return VillageService.shared.request(target: leaderboard)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
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
            let dateString = response["dateCreated"].string,
            let date = villageCoreAPIDateFormatter.date(from: dateString)
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

fileprivate extension Achievement {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].string,
            let title = response["title"].string,
            let pointsCap = response["pointsCap"].int
        else {
            return nil
        }
        
        // if securityPolicies is empty, kudos for this achievement can be given
        // by anyone. If non-empty, only users who are granted one of these policies
        // can give kudos for the achievement.
        let securityPolicies = response["securityPolicies"].arrayValue
            .compactMap({ $0["id"].string })
            .compactMap({ SecurityPolicies(securityPolicyID: $0) })
        
        self = Achievement.init(
            id: id,
            title: title,
            description: response["description"].stringValue,
            pointsCap: pointsCap,
            userPoints: response["userPoints"].int,
            enabled: response["enabled"].boolValue,
            mediaAttachments: response["mediaAttachment"].arrayValue.compactMap(MediaAttachment.init),
            securityPolicies: securityPolicies.isEmpty ? .superAdmin : SecurityPolicies.combining(securityPolicies)
        )
    }
    
}
