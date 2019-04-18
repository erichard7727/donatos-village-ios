//
//  VillageCoreAPI.swift
//  VillageCore
//
//  Created by Rob Feldmann on 02/07/19.
//  Copyright © 2019 Dynamirt. All rights reserved.
//

import Moya

/// Creates an NSDateFormatter specifically for usage with this API.
///
/// Settings:
///   - POSIX Locale, for ensuring the date is formatted according to the Gregorian calendar
///   - ISO8601 date format
///   - UTC converisions
public var villageCoreAPIDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter
}()

fileprivate let defaultPageSize = 50

/// Describes all of the Village Core API Endpoints
///
/// - foundationSettings: Gets basic configuration data. To be called
///     immediately upon application initialization.
public enum VillageCoreAPI {
    
    public enum DomainInitiationMode: String {
        case invitation = "invite"
        case confirmation = "confirm"
    }
    
    public enum NoticeType {
        case all
        case notice
        case news
        
        fileprivate var apiValue: String {
            switch self {
            case .notice:
                return "notice"
                
            case .news:
                return "news"
                
            case .all:
                assertionFailure()
                return ""
            }
        }
    }
    
    public enum KudoType: String {
        case all = ""
        case received
        case given
    }
    
    // Foundation Settings
    case foundationSettings(licenseKey: String)
    
    // Authorization
    case validateIdentity(identity: String)
    case initiateDomain(_ mode: DomainInitiationMode, emailAddress: String)
    case login(identity: String, password: String, prefetch: String?, pushType: String, pushToken: String?, appPlatform: String, appVersion: String)
    case initiateResetPassword(emailAddress: String)
    case logout
    case inviteUser(email: String)
    
    // People
    case me
    case securityPolicies(userId: String)
    case updatePerson(id: String, firstName: String?, lastName: String?, jobTitle: String?, email: String?, phone: String?, twitter: String?, directories: [Int]?, avatarData: Data?)
    
    // Directory
    case directory(page: Int)
    case searchDirectory(term: String, page: Int)
    case getPersonDetails(personId: String)
    
    // Notices
    case notices(_ noticeType: NoticeType, page: Int)
    case noticeDetail(noticeId: String)
    case noticeAcknowledgedList(noticeId: String, page: Int)
    case acknowledgeNotice(noticeId: String)
    
    // Content Library
    case contentLibraryRoot(page: Int)
    case contentLibraryDirectory(contentId: String)
    
    // Kudos
    case kudos(_ kudoType: KudoType, personId: String, achievementId: String?, page: Int)
    case achievements(personId: String, page: Int)
    case givableAchievements(page: Int)
    case giveKudo(receiverId: Int, achievementId: String, points: Int, comment: String)
    case kudosLeaderboard(page: Int, days: Int?)
    
    // Streams
    case streamsHistory
//    case homeStream
//    case inviteToStream
    case streamsMembers(streamId: String)
    case likeMessage(streamId: String, messageId: String)
    case dislikeMessage(streamId: String, messageId: String)
    case otherStreams(page: Int)
    case subscriptions
    case subscribeToStream(streamId: String)
    case streamDetails(streamId: String)
    case sendMessage(message: Message)
//    case getMessagesWithHistory
//    case getMessagesNoHistory
//    case createStream
}

// MARK: - TargetType

extension VillageCoreAPI: TargetType {
    
    public var baseURL: URL {
        return URL(string: ClientConfiguration.current.appBaseURL)!
    }

    public var path: String {
        switch self {
        case let .foundationSettings(licenseKey):
            return "foundation/1.0/foundation_settings/\(licenseKey)"
            
        case .validateIdentity:
            return "auth/1.0/auth_validate_identity"
            
        case .initiateDomain:
            return "auth/1.0/auth_initiate_domain_confirmation"
            
        case .login:
            return "accounts/1.0/login"
            
        case .initiateResetPassword:
            return "auth/1.0/auth_initiate_reset_password"
            
        case .logout:
            return "accounts/1.0/logout"
            
        case .inviteUser:
            return "auth/1.0/invitation"
            
        case .me:
            return "people/1.0/me"
            
        case let .securityPolicies(userId):
            return "people/1.0/\(userId)/policy"
            
        case let .updatePerson(id, _, _, _, _, _, _, _, _):
            return "people/1.0/person/\(id)"
            
        case let .directory(page):
            return "people/1.0/people/\(page)-\(defaultPageSize)"
            
        case let .searchDirectory(term, _):
            let query = term.trimmingCharacters(in: CharacterSet.urlPathAllowed.inverted)
            return "people/1.0/search/\(query)"
            
        case let .getPersonDetails(personId):
            return "people/1.0/person/\(personId)"
            
        case .notices:
            return "notice/1.0"
            
        case let .noticeDetail(noticeId):
            return "notice/1.0/\(noticeId)"
            
        case let .noticeAcknowledgedList(noticeId, _),
             let .acknowledgeNotice(noticeId):
            return "notice/1.0/\(noticeId)/acknowledge"
            
        case .contentLibraryRoot:
            return "content/1.0"
            
        case let .contentLibraryDirectory(contentId):
            return "content/1.0/@\(contentId)"
            
        case .kudos, .giveKudo:
            return "kudos/1.0/kudos"

        case .achievements, .givableAchievements:
            return "kudos/1.0/achievements/"
            
        case .kudosLeaderboard:
            return "kudos/1.0/leaders"
            
        case .streamsHistory:
            return "streams/1.0/history"
        
        case let .streamsMembers(streamId):
            return "streams/1.0/members/\(streamId)"
        
        case let .likeMessage(streamId, messageId):
            return "streams/1.0/messages/\(streamId)/\(messageId)/like"
            
        case let .dislikeMessage(streamId, messageId):
            return "streams/1.0/messages/\(streamId)/\(messageId)/dislike"
            
        case .otherStreams(_):
            return "streams/1.0/streams/"
            
        case .subscriptions:
            return "streams/1.0/subscriptions/"
            
        case .subscribeToStream(_):
            return "stream/1.0/subscriptions/"
            
        case let .streamDetails(streamId):
            return "streams/1.0/stream/\(streamId)"
            
        case let .sendMessage(message):
            return "streams/1.0/messages/\(message.streamId)/\(message.id)"


        }
    }

    public var headers: [String : String]? {
        return [
            "Accept": "application/json",
            "Accept-Language": "en",
        ]
    }

    public var method: Moya.Method {
        switch self {
        case .foundationSettings,
             .me,
             .securityPolicies,
             .directory,
             .getPersonDetails,
             .notices,
             .noticeDetail,
             .noticeAcknowledgedList,
             .contentLibraryRoot,
             .contentLibraryDirectory,
             .kudos,
             .achievements,
             .streamsHistory,
             .givableAchievements,
             .kudosLeaderboard,
             .searchDirectory,
             .streamsMembers,
             .otherStreams,
             .subscriptions,
             .streamDetails:
            return .get
            
        case .validateIdentity,
             .initiateDomain,
             .login,
             .initiateResetPassword,
             .logout,
             .inviteUser,
             .acknowledgeNotice,
             .giveKudo:
            return .post
            
        case .updatePerson,
             .likeMessage(_),
             .dislikeMessage(_),
             .subscribeToStream(_),
             .sendMessage(_):
            return .put
        }
    }

    public var sampleData: Data {
        switch self {
        case .foundationSettings,
             .validateIdentity,
             .initiateDomain,
             .login,
             .initiateResetPassword,
             .logout,
             .inviteUser,
             .me,
             .securityPolicies,
             .updatePerson,
             .directory,
             .getPersonDetails,
             .notices,
             .noticeDetail,
             .noticeAcknowledgedList,
             .acknowledgeNotice,
             .contentLibraryRoot,
             .contentLibraryDirectory,
             .kudos,
             .giveKudo,
             .achievements,
             .givableAchievements,
             .kudosLeaderboard,
             .searchDirectory,
             .streamsHistory,
             .streamsMembers,
             .likeMessage(_),
             .dislikeMessage(_),
             .otherStreams(_),
             .subscriptions,
             .subscribeToStream(_),
             .streamDetails(_),
             .sendMessage(_):
            return Data()
        }
    }

    public var task: Task {
        switch self {
        case .foundationSettings,
             .logout,
             .me,
             .securityPolicies,
             .getPersonDetails,
             .noticeDetail,
             .acknowledgeNotice,
             .contentLibraryDirectory,
             .streamsHistory,
             .streamsMembers(_),
             .likeMessage(_),
             .dislikeMessage(_),
             .subscriptions,
             .streamDetails(_):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId
                ],
                encoding: URLEncoding.default
            )
            
        case let .validateIdentity(identity):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "licenseKey": ClientConfiguration.current.licenseKey,
                    "identity": identity,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .initiateDomain(mode, emailAddress):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "licenseKey": ClientConfiguration.current.licenseKey,
                    "inviteToken": mode.rawValue,
                    "emailAddress": emailAddress,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .initiateResetPassword(emailAddress):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "licenseKey": ClientConfiguration.current.licenseKey,
                    "emailAddress": emailAddress,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .login(identity, password, prefetch, pushType, pushToken, appPlatform, appVersion):
            return Task.requestCompositeParameters(
                bodyParameters: {
                    var params: [String: Any] = [
                        "licenseKey": ClientConfiguration.current.licenseKey,
                        "identity": identity,
                        "password": password,
                        "pushType": pushType,
                        "appPlatform": appPlatform,
                        "appVersion": appVersion
                    ]
                    if let prefetch = prefetch {
                        params["prefetch"] = prefetch
                    }
                    if let pushToken = pushToken {
                        params["pushToken"] = pushToken
                    }
                    return params
                }(),
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .updatePerson(_, firstName, lastName, jobTitle, email, phone, twitter, directories, avatarData):
            return Task.requestCompositeParameters(
                bodyParameters: {
                    var params: [String: Any] = [:]
                    firstName.flatMap({ params["firstName"] = $0 })
                    lastName.flatMap({ params["lastName"] = $0 })
                    jobTitle.flatMap({ params["jobTitle"] = $0 })
                    email.flatMap({ params["emailAddress"] = $0 })
                    phone.flatMap({ params["phone"] = $0 })
                    twitter.flatMap({ params["twitter"] = $0 })
                    directories.flatMap({ params["directories"] = $0 })
                    avatarData.flatMap({
                        params["avatar"] = [
                            "title": "avatar.png",
                            "type": "image/png",
                            "content": $0.base64EncodedString()
                        ]
                    })
                    return params
                }(),
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .inviteUser(email):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "emailAddress": email,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case .directory:
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "filter": "ACTIVE",
                    ],
                encoding: URLEncoding.default
            )
            
        case let .notices(noticeType, page):
            let diagId = User.current.diagnosticId
            let paging = "\(page)-\(defaultPageSize)"
            
            switch noticeType {
            case .news, .notice:
                return Task.requestParameters(
                    parameters: [
                        "diagId": diagId,
                        "paging": paging,
                        "filter": "type:\(noticeType.apiValue)",
                    ],
                    encoding: URLEncoding.default
                )
                
            case .all:
                return Task.requestParameters(
                    parameters: [
                        "diagId": diagId,
                        "paging": paging,
                    ],
                    encoding: URLEncoding.default
                )
            }
            
        case let .kudos(kudoType, personId, achievementId, page):
            let filters: [String?] = [
                (kudoType == .all) ? nil : kudoType.rawValue,
                "personId:\(personId)",
                achievementId.flatMap({ "achievementId:\($0)" })
            ]
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": filters.compactMap({ $0 }).joined(separator: ","),
                ],
                encoding: URLEncoding.default
            )
            
        case let .giveKudo(receiverId, achievementId, points, comment):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "achievementId": achievementId,
                    "receiverId": receiverId,
                    "points": points,
                    "comment": comment,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId,
                ]
            )
            
        case let .achievements(personId, page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": "enabled:true,personId:\(personId)",
                ],
                encoding: URLEncoding.default
            )

        case let .givableAchievements(page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": "enabled:true,currentUserCanGiveKudos:true",
                ],
                encoding: URLEncoding.default
            )

        case let .kudosLeaderboard(page, days):
            return Task.requestParameters(
                parameters: {
                    var params: [String: Any] = [
                        "diagId": User.current.diagnosticId,
                        "paging": "\(page)-\(defaultPageSize)",
                    ]
                    if let days = days {
                        params["days"] = days
                    }
                    return params
                }(),
                encoding: URLEncoding.default
            )
             
        case let .otherStreams(page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": "available",
                ],
                encoding: URLEncoding.default
            )
            
        case let .subscribeToStream(streamId):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "streamId": streamId,
                    "subscribed": true,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .sendMessage(message):
            return Task.requestCompositeParameters(
                bodyParameters: {
                    var params: [String: Any] = [:]
                    params["id"] = message.id
                    message.person.flatMap({ params["person"] = $0 })
                    message.text.flatMap({ params["text"] = $0 })
                    message.ownderDisplayName.flatMap({ params["ownerDisplayName"] = $0 })
                    message.lastUpdated.flatMap({ params["lastUpdated"] = $0 })
                    message.createdDate.flatMap({ params["createdDate"] = $0 })
                    params["streamId"] = message.streamId
                    message.likesCount.flatMap({ params["likesCount"] = $0 })
                    message.hasUserLikedMessage.flatMap({ params["hasUserLikedMessage"] = $0 })
                    message.isSystem.flatMap({ params["isSystem"] = $0 })
                    
                    return params
            }(),
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
            
        case let .searchDirectory(_, page),
             let .noticeAcknowledgedList(_, page),
             let .contentLibraryRoot(page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                ],
                encoding: URLEncoding.default
            )
        }
    }
}

extension VillageCoreAPI: AuthorizedTargetType {
    
    public var isAuthorized: Bool {
        switch self {
        case .foundationSettings,
             .validateIdentity,
             .initiateDomain,
             .login,
             .logout,
             .initiateResetPassword:
            return false
            
        case .me,
             .securityPolicies,
             .updatePerson,
             .inviteUser,
             .directory,
             .getPersonDetails,
             .notices,
             .noticeDetail,
             .noticeAcknowledgedList,
             .acknowledgeNotice,
             .contentLibraryRoot,
             .contentLibraryDirectory,
             .kudos,
             .giveKudo,
             .achievements,
             .givableAchievements,
             .kudosLeaderboard,
             .searchDirectory,
             .streamsHistory,
             .streamsMembers(_),
             .likeMessage(_),
             .dislikeMessage(_),
             .otherStreams(_),
             .subscriptions,
             .subscribeToStream(_),
             .streamDetails(_),
             .sendMessage(_):
            return true
        }
    }
    
}
