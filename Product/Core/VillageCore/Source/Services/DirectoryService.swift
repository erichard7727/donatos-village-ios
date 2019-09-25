//
//  DirectoryService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 3/13/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import Promises
import SwiftyJSON

enum DirectoryServiceError: Error {
    case unknown
}

struct DirectoryService {
    
    private init() { }
    
    static func getDirectory(page: Int = 1) -> Promise<People> {
        return firstly {
            let directory = VillageCoreAPI.directory(page: page)
            return VillageService.shared.request(target: directory)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
        }
    }
    
    static func search(for term: String, page: Int = 1) -> Promise<People> {
        return firstly {
            let search = VillageCoreAPI.searchDirectory(term: term, page: page)
            return VillageService.shared.request(target: search)
        }.then { (json: JSON) -> People in
            let people = json["people"].arrayValue.compactMap({ Person(from: $0) })
            return people
        }
    }
    
    static func getDetails(for person: Person) -> Promise<Person> {
        return firstly {
            let personDetails = VillageCoreAPI.getPersonDetails(personId: person.id.description)
            return VillageService.shared.request(target: personDetails)
        }.then { (json: JSON) -> Person in
            guard let person = Person(from: json) else {
                throw DirectoryServiceError.unknown
            }
            return person
        }
    }
    
    static func getDetails(for user: User) -> Promise<Person> {
        return firstly {
            let personDetails = VillageCoreAPI.getPersonDetails(personId: user.personId.description)
            return VillageService.shared.request(target: personDetails)
        }.then { (json: JSON) -> Person in
            guard let person = Person(from: json) else {
                throw DirectoryServiceError.unknown
            }
            return person
        }
    }
    
    static func updateDetails(for person: Person, avatarData: Data?) -> Promise<Person> {
        return firstly {
            let updatePerson = VillageCoreAPI.updatePerson(
                id: person.id.description,
                firstName: person.firstName,
                lastName: person.lastName,
                jobTitle: person.jobTitle,
                email: person.emailAddress,
                phone: person.phone,
                twitter: person.twitter,
                directories: person.directories,
                avatarData: avatarData
            )
            return VillageService.shared.request(target: updatePerson)
        }.then { (json: JSON) -> Person in
            guard let person = Person(from: json) else {
                throw DirectoryServiceError.unknown
            }
            return person
        }
    }

}

// MARK: - SwiftyJSON Extensions

internal extension Person {
    
    init?(from response: JSON) {
        guard
            let id = response["id"].int,
            let emailAddress = response["emailAddress"].string
        else {
            return nil
        }
    
        self = Person.init(
            id: id,
            emailAddress: emailAddress,
            displayName: response["displayName"].string,
            avatarURL: response["avatar"]["url"].url,
            firstName: response["firstName"].string,
            lastName: response["lastName"].string,
            department: response["department"].string,
            jobTitle: response["jobTitle"].string,
            phone: response["phone"].string,
            twitter: response["twitter"].string,
            deactivated: response["deactivated"].boolValue,
            kudos: (count: response["kudos"]["totalKudos"].intValue, points: response["kudos"]["totalPoints"].intValue),
            directories: response["directories"].arrayValue.compactMap({ $0.int }),
            acknowledgeDate: villageCoreAPIDateFormatter.date(from: response["acknowledgeDate"].stringValue)
        )
    }
    
}
