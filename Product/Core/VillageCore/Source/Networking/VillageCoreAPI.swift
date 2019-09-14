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
        case events
        
        fileprivate var apiValue: String {
            switch self {
            case .notice:
                return "notice"
                
            case .news:
                return "news"
                
            case .events:
                return "event"
                
            case .all:
                assertionFailure()
                return ""
            }
        }
    }

    public enum RSVPResponse: String {
        case no = "NO"
        case maybe = "MAYBE"
        case yes = "YES"
    }
    
    public enum KudoType: String {
        case all = ""
        case received
        case given
    }
    
    public enum StreamType: String {
        case open
        case memberInvites = "open_invite"
        case closed
        case global
    }
    
    public struct MessageAttachment {
        let data: Data
        let mimeType: String
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
    case rsvpEvent(noticeId: String, response: RSVPResponse)
    
    // Content Library
    case contentLibraryRoot(page: Int)
    case contentLibraryDirectory(contentId: String)
    
    // Kudos
    case kudos(_ kudoType: KudoType, personId: String, achievementId: String?, page: Int)
    case achievements(personId: String, page: Int)
    case givableAchievements(page: Int)
    case giveKudo(receiverId: Int, achievementId: String, points: Int, comment: String)
    case kudosLeaderboard(page: Int, days: Int?)
    case flagKudo(kudoId: Int)
    
    // Streams
    case streamsHistory
    case homeStream(page: Int)
    case subscribedStreams
    case otherStreams(page: Int)
    case searchOtherStreams(term: String, page: Int)
    case streamDetails(streamId: String)
    case streamMembers(streamId: String)
    case streamMessages(streamId: String, page: Int)
    case streamMessagesStartingAfter(messageId: String, streamId: String, page: Int)
    case createOrUpdateStream(streamId: String, type: StreamType, name: String, description: String, ownerId: String)
    case inviteToStream(streamId: String, userIds: [String])
    case setSubscribed(subscribed: Bool, streamId: String)
    case sendMessage(streamId: String, messageId: String, body: String, attachment: MessageAttachment?)
    case setMessageLiked(isLiked: Bool, messageId: String, streamId: String)
    
    // Direct Messages
    case directMessageStreams
    case inviteToDirectMessage(userIds: [String])

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

        case let .rsvpEvent(noticeId, _):
            return "notice/1.0/\(noticeId)/rsvp"
            
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

        case .homeStream:
            return "streams/1.0/home"
            
        case .streamsHistory:
            return "streams/1.0/history"
        
        case let .streamMembers(streamId):
            return "streams/1.0/members/\(streamId)"
            
        case let .streamMessages(streamId, _):
            return "streams/1.0/messages/\(streamId)"
            
        case let .streamMessagesStartingAfter(messageId, streamId, _):
            return "streams/1.0/messages/\(streamId)/@\(messageId)"
            
        case let .createOrUpdateStream(streamId, _, _, _, _):
            return "streams/1.0/stream/\(streamId)"
            
        case .inviteToStream:
            return "streams/1.0/invite/\(UUID().uuidString)"
            
        case let .setMessageLiked(isLiked, messageId, streamId):
            return "streams/1.0/messages/\(streamId)/\(messageId)/\(isLiked ? "like" : "dislike")"

        case .otherStreams, .searchOtherStreams:
            return "streams/1.0/streams"
            
        case .subscribedStreams, .setSubscribed:
            return "streams/1.0/subscriptions"

        case let .sendMessage(streamId, messageId, _, _):
            return "streams/1.0/messages/\(streamId)/@\(messageId)"

        case let .streamDetails(streamId):
            return "streams/1.0/stream/\(streamId)"
            
        case .directMessageStreams:
            return "dm/1.0/streams"
            
        case .inviteToDirectMessage:
            return "dm/1.0"

        case let .flagKudo(kudoId):
            return "kudos/1.0/kudos/\(kudoId)/flag"
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
             .givableAchievements,
             .kudosLeaderboard,
             .searchDirectory,
             .streamsHistory,
             .homeStream,
             .streamMembers,
             .streamMessages,
             .streamMessagesStartingAfter,
             .otherStreams,
             .searchOtherStreams,
             .subscribedStreams,
             .streamDetails,
             .directMessageStreams:
            return .get
            
        case .validateIdentity,
             .initiateDomain,
             .login,
             .initiateResetPassword,
             .logout,
             .inviteUser,
             .acknowledgeNotice,
             .giveKudo,
             .inviteToDirectMessage:
            return .post
            
        case .updatePerson,
             .createOrUpdateStream,
             .inviteToStream,
             .setMessageLiked,
             .setSubscribed,
             .sendMessage,
             .flagKudo,
             .rsvpEvent:
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
             .rsvpEvent,
             .contentLibraryRoot,
             .contentLibraryDirectory,
             .kudos,
             .giveKudo,
             .achievements,
             .givableAchievements,
             .kudosLeaderboard,
             .searchDirectory,
             .streamsHistory,
             .homeStream,
             .streamMembers,
             .streamMessages,
             .streamMessagesStartingAfter,
             .createOrUpdateStream,
             .inviteToStream,
             .setMessageLiked,
             .otherStreams,
             .searchOtherStreams,
             .subscribedStreams,
             .setSubscribed,
             .streamDetails,
             .sendMessage,
             .directMessageStreams,
             .inviteToDirectMessage,
             .flagKudo:
            return Data()
        }
    }

    public var task: Task {
        switch self {
        case .foundationSettings,
             .me,
             .securityPolicies,
             .getPersonDetails,
             .noticeDetail,
             .acknowledgeNotice,
             .contentLibraryDirectory,
             .streamsHistory,
             .streamMembers,
             .setMessageLiked,
             .subscribedStreams,
             .streamDetails,
             .directMessageStreams,
             .flagKudo:
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId
                ],
                encoding: URLEncoding.default
            )

        case let .rsvpEvent(_, response):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "eventRsvpStatus": response.rawValue,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
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
            
        case .logout:
            return Task.requestCompositeParameters(
                bodyParameters: {
                    var params: [String: Any] = [:]
                    if let pushToken = User.current.pushToken {
                        params["pushToken"] = pushToken
                    }
                    return params
                }(),
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
            case .news, .notice, .events:
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

        case let .searchDirectory(_, page),
             let .noticeAcknowledgedList(_, page),
             let .contentLibraryRoot(page),
             let .homeStream(page),
             let .streamMessages(_, page),
             let .streamMessagesStartingAfter(_, _, page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                ],
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

        case let .searchOtherStreams(term, page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": "available",
                    "search": term,
                ],
                encoding: URLEncoding.default
            )
            
        case let .setSubscribed(subscribed, streamId):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "streamId": streamId,
                    "subscribed": subscribed,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .sendMessage(_, messageId, body, attachment):
            let urlParams: [String: Any] = [
                "diagId": User.current.diagnosticId
            ]
            
            if let attachment = attachment {
                let content = MultipartFormData(
                    provider: .data(attachment.data),
                    name: "content",
                    fileName: "Image",
                    mimeType: attachment.mimeType
                )
                let id = MultipartFormData(provider: .data(messageId.data(using: .utf8)!), name: "id")
                let body = MultipartFormData(provider: .data(body.data(using: .utf8)!), name: "text")
                let title = MultipartFormData(provider: .data("Image".data(using: .utf8)!), name: "title")
                let type = MultipartFormData(provider: .data(attachment.mimeType.data(using: .utf8)!), name: "type")
                return Task.uploadCompositeMultipart([content, id, body, title, type], urlParameters: urlParams)
            } else {
                return Task.requestCompositeParameters(
                    bodyParameters: [
                        "id": messageId,
                        "text": body,
                    ],
                    bodyEncoding: JSONEncoding.default,
                    urlParameters: urlParams
                )
            }

        case let .createOrUpdateStream(streamId, type, name, description, _):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "id": streamId,
                    "name": name,
                    "description": description,
                    "streamType": type.rawValue
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .inviteToStream(streamId, userIds):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "streamId": streamId,
                    "userIds": userIds,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
            )
            
        case let .inviteToDirectMessage(userIds):
            return Task.requestCompositeParameters(
                bodyParameters: [
                    "parties": userIds,
                ],
                bodyEncoding: JSONEncoding.default,
                urlParameters: [
                    "diagId": User.current.diagnosticId
                ]
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
             .rsvpEvent,
             .contentLibraryRoot,
             .contentLibraryDirectory,
             .kudos,
             .giveKudo,
             .achievements,
             .givableAchievements,
             .kudosLeaderboard,
             .searchDirectory,
             .homeStream,
             .streamsHistory,
             .streamMembers,
             .streamMessages,
             .streamMessagesStartingAfter,
             .createOrUpdateStream,
             .inviteToStream,
             .setMessageLiked,
             .otherStreams,
             .searchOtherStreams,
             .subscribedStreams,
             .setSubscribed,
             .streamDetails,
             .sendMessage,
             .directMessageStreams,
             .inviteToDirectMessage,
             .flagKudo:
            return true
        }
    }
    
}
