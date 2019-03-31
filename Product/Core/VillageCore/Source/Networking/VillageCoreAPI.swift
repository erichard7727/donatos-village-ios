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
    
    // Kudos
    case kudos(_ kudoType: KudoType, personId: String, page: Int)
    
    // Streams
    case streamsHistory
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
            
        case .validateIdentity(_):
            return "auth/1.0/auth_validate_identity"
            
        case .initiateDomain:
            return "auth/1.0/auth_initiate_domain_confirmation"
            
        case .login(_):
            return "accounts/1.0/login"
            
        case .initiateResetPassword(_):
            return "auth/1.0/auth_initiate_reset_password"
            
        case .logout:
            return "accounts/1.0/logout"
            
        case .inviteUser(_):
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
            
        case .kudos(_):
            return "kudos/1.0/kudos"
            
        case .streamsHistory:
            return "streams/1.0/history"
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
        case .foundationSettings(_),
             .me,
             .securityPolicies(_),
             .directory(_),
             .getPersonDetails(_),
             .notices,
             .noticeDetail,
             .noticeAcknowledgedList,
             .kudos(_),
             .searchDirectory(_),
             .streamsHistory:
            return .get
            
        case .validateIdentity(_),
             .initiateDomain,
             .login(_),
             .initiateResetPassword(_),
             .logout,
             .inviteUser(_),
             .acknowledgeNotice:
            return .post
            
        case .updatePerson:
            return .put
        }
    }

    public var sampleData: Data {
        switch self {
        case .foundationSettings(_),
             .validateIdentity(_),
             .initiateDomain,
             .login(_),
             .initiateResetPassword(_),
             .logout,
             .inviteUser(_),
             .me,
             .securityPolicies(_),
             .updatePerson,
             .directory(_),
             .getPersonDetails(_),
             .notices,
             .noticeDetail,
             .noticeAcknowledgedList,
             .acknowledgeNotice,
             .kudos(_),
             .searchDirectory(_),
             .streamsHistory:
            return Data()
        }
    }

    public var task: Task {
        switch self {
        case .foundationSettings(_),
             .logout,
             .me,
             .securityPolicies(_),
             .getPersonDetails(_),
             .noticeDetail,
             .acknowledgeNotice,
             .streamsHistory:
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
            
        case .directory(_):
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
            
        case let .kudos(kudoType, personId, page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": "\(kudoType.rawValue),personId:\(personId)",
                ],
                encoding: URLEncoding.default
            )
            
        case let .searchDirectory(_, page),
             let .noticeAcknowledgedList(_, page):
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
        case .foundationSettings(_),
             .validateIdentity(_),
             .initiateDomain,
             .login(_),
             .logout,
             .initiateResetPassword(_):
            return false
            
        case .me,
             .securityPolicies(_),
             .updatePerson,
             .inviteUser(_),
             .directory(_),
             .getPersonDetails(_),
             .notices,
             .noticeDetail,
             .noticeAcknowledgedList,
             .acknowledgeNotice,
             .kudos(_),
             .searchDirectory(_),
             .streamsHistory:
            return true
        }
    }
    
}
