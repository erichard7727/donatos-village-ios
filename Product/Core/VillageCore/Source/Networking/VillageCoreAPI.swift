//
//  VillageCoreAPI.swift
//  VillageCore
//
//  Created by Rob Feldmann on 02/07/19.
//  Copyright © 2019 Dynamirt. All rights reserved.
//

import Moya

fileprivate let defaultPageSize = 50

/// Describes all of the Village Core API Endpoints
///
/// - foundationSettings: Gets basic configuration data. To be called
///     immediately upon application initialization.
public enum VillageCoreAPI {
    
    public enum KudoType: String {
        case received
        case given
    }
    
    // Foundation Settings
    case foundationSettings(licenseKey: String)
    
    // Authorization
    case validateIdentity(identity: String)
    case login(identity: String, password: String, prefetch: String?, pushType: String, pushToken: String?, appPlatform: String, appVersion: String)
    case initiateResetPassword(emailAddress: String)
    case logout
    
    // People
    case me
    case securityPolicies(userId: String)
    
    // Directory
    case directory(page: Int)
    case getPersonDetails(personId: String)
    
    // Kudos
    case kudos(_ kudoType: KudoType, personId: String, page: Int)
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
            
        case .login(_):
            return "accounts/1.0/login"
            
        case .initiateResetPassword(_):
            return "auth/1.0/auth_initiate_reset_password"
            
        case .logout:
            return "accounts/1.0/logout"
            
        case .me:
            return "people/1.0/me"
            
        case let .securityPolicies(userId):
            return "people/1.0/\(userId)/policy"
            
        case let .directory(page):
            return "people/1.0/people/\(page)-\(defaultPageSize)"
            
        case let .getPersonDetails(personId):
            return "people/1.0/person/\(personId)"
            
        case .kudos(_):
            return "kudos/1.0/kudos"
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
             .kudos(_):
            return .get
            
        case .validateIdentity(_),
             .login(_),
             .initiateResetPassword(_),
             .logout:
            return .post
        }
    }

    public var sampleData: Data {
        switch self {
        case .foundationSettings(_),
             .validateIdentity(_),
             .login(_),
             .initiateResetPassword(_),
             .logout,
             .me,
             .securityPolicies(_),
             .directory(_),
             .getPersonDetails(_),
             .kudos(_):
            return Data()
        }
    }

    public var task: Task {
        switch self {
        case .foundationSettings(_),
             .me,
             .securityPolicies(_),
             .getPersonDetails(_):
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
            
        case .logout:
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId
                ],
                encoding: URLEncoding.default
            )
            
        case .directory(_):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "filter": "ACTIVE",
                    ],
                encoding: URLEncoding.default
            )
            
        case let .kudos(kudoType, personId, page):
            return Task.requestParameters(
                parameters: [
                    "diagId": User.current.diagnosticId,
                    "paging": "\(page)-\(defaultPageSize)",
                    "filter": "\(kudoType.rawValue),personId:\(personId)",
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
             .login(_),
             .logout,
             .initiateResetPassword(_):
            return false
            
        case .me,
             .securityPolicies(_),
             .directory(_),
             .getPersonDetails(_),
             .kudos(_):
            return true
        }
    }
    
}
