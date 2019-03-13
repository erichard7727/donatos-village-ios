//
//  VillageService.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/9/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Moya
import Promises
import SwiftyJSON

public enum ServiceError: Error {
    case connectionFailed(Error)
}

public enum VillageServiceError: Swift.Error {
    case apiError(message: String)
    case apiErrorUnknown
    case apiInvalidResponse
    
    var userDisplayableMessage: String {
        switch self {
        case .apiError(let message):
            return message
        default:
            return genericFailureMessage
        }
    }
    
    var genericFailureMessage: String {
        return "An error has occurred, your request could not be completed at this time."
    }
}

/// A wrapper around the VillageProvider Request -> Response flow that
/// provides common API handling behaviors (mainly error handling).
///
///  * The shared instance is used by all Village service classes (via the
///    `request` method) to perform network requests.
///  * This means that all requests are passed to the same VillageProvider
///    object (allowing requests to be queued after a 401 or 403 response
///    while the token is refreshed), and also that all requests have the same
///    basic handler logic applied to them.
public class VillageService {
    
    /// Shared instance
    public static let shared = VillageService()
    
    /// Allow public access only through the `shared` property
    private init() { }
    
    /// The VillageService class uses a User object for authentication context.
    /// By default, the `Shared` model class will set this to the Shared.user
    /// instance (for the shared VillageService instance), but any User could
    /// be substituted during testing
    private var user: User? = User.current
    
    private lazy var provider: VillageProvider<VillageCoreAPI> = {
        
        let getTokens: VillageProvider.GetTokenClosure = { self.user?.xsrfToken }
        
        let setTokens: VillageProvider.SetTokenClosure = { xsrfToken in
//            if let xsrfToken = xsrfToken {
                self.user?.xsrfToken = xsrfToken
//            }
        }
        
        let reAuthentication: VillageProvider<VillageCoreAPI>.ReAuthenticationClosure = { (reason, completion) in
            switch reason {
            case .unauthorized:
                firstly {
                    User.current.login()
                }.then { _ in
                    completion(true)
                }.catch { _ in
                    completion(false)
                }
                
//                let login = VillageCoreAPI.login(identity: "rob@dynamit.com", password: "Testing1", prefetch: nil, pushType: "apns", pushToken: nil, appPlatform: "", appVersion: "")
//                self.provider.request(login) { result in
//                    switch result {
//                    case .success(let response):
//                        do {
//                            _ = try response.filterSuccessfulStatusCodes()
//                            completion(true)
//                        } catch {
//                            completion(false)
//                        }
//
//                    case .failure(let error):
//                        completion(false)
//                    }
//                }
                
            case .xsrfToken:
                self.provider.request(.me, ignoreReAuthentication: true) { result in
                    switch result {
                    case .success(let response):
                        do {
                            _ = try response.filterSuccessfulStatusCodes()
                            completion(true)
                        } catch {
                            completion(false)
                        }
                        
                    case .failure(let error):
                        completion(false)
                    }
                }
            }
        }
        
        var plugins: [PluginType] = []
        
        //DEBUG MODES
        let mockResponsesEnabled = UserDefaults.standard.bool(forKey: "VILEnableMockedNetworking")
        let stubClosure = mockResponsesEnabled ? VillageProvider<VillageCoreAPI>.delayedStub(1.0) : MoyaProvider.neverStub
        
        let networkLoggingEnabled = true
        if networkLoggingEnabled {
            plugins.append(NetworkLoggerPlugin(verbose: true))
        }
        
        return VillageProvider<VillageCoreAPI>(
            stubClosure: stubClosure,
            plugins: plugins,
            getToken: getTokens,
            setToken: setTokens,
            reAuthenticate: reAuthentication
        )
    }()
    
    private let networkConditionsMaxRetries: Int = 1
    private let networkCondictionsRetryDelay: TimeInterval = 3.0
    
    /// This is the main function that ClubCorp Service classes use to make
    /// requests. It wraps the standard ClubCorp API reponse format
    /// (header/payload/error) providing common functionality for all requests.
    ///
    /// * First validates for successful status code
    ///     * On success, returns the response as JSON
    ///     * On failure, constructs a VillageServiceError.apiError with the message
    ///       from the Error > Description or Error > Explanation (if present)
    ///
    /// - Parameters:
    ///   - target: The request to make
    ///   - callbackQueue: A queue to call the completion handler on
    ///   - progress: Closure to be executed when progress changes
    /// - Returns: Promise<JSON>
    public func request(target: VillageCoreAPI, callbackQueue: DispatchQueue? = nil, progress: ProgressBlock? = nil) -> Promise<JSON> {
        return firstly {
            self.makeRequest(target: target, callBackQueue: callbackQueue, progress: progress, attemptNumber: 0)
        }.then { response -> JSON in
            do {
                let response = try response.filterSuccessfulStatusCodes()
                let json = try JSON(data: response.data)
                return json
            } catch {
                // the status code is invalid, check for the 'error' object in
                // the response, which contains the error description and
                // construct a VillageServiceError.apiError with that message
                guard let json = try? JSON(data: response.data) else { throw error }
                
                if let explanation = json["error"]["explanation"]["ReasonText"].string {
                    throw VillageServiceError.apiError(message: explanation)
                    
                } else if let description = json["error"]["description"].string {
                    throw VillageServiceError.apiError(message: description)
                    
                } else {
                    throw VillageServiceError.apiErrorUnknown
                }
            }
        }
    }
    
    /// Handles making the request to the moya provider & retrying recursively
    /// after a delay if it failed to get a response.
    ///
    /// - Parameters:
    ///   - target: The request to make
    ///   - callbackQueue: A queue to call the completion handler on
    ///   - progress: Closure to be executed when progress changes
    ///   - attemptNumber: The retry attempt count
    /// - Returns: Promise<Response>
    private func makeRequest(target: VillageCoreAPI, callBackQueue: DispatchQueue?, progress: ProgressBlock?, attemptNumber: Int) -> Promise<Response> {
        return Promise<Response> { fulfill, reject in
            self.provider.request(target, callbackQueue: callBackQueue, progress: progress, completion: { result in
                switch result {
                case let .success(response):
                    fulfill(response)
                    
                case let .failure(error):
                    if case MoyaError.underlying(VillageProvider<VillageCoreAPI>.Error.reAuthenticationFailed, _) = error {
                        reject(error)
                        return
                    }
                    
                    guard attemptNumber < self.networkConditionsMaxRetries else {
                        reject(ServiceError.connectionFailed(error)); return
                    }
                    
                    // Request failed to reach the server (or get a response) due to network conditions - retry after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.networkCondictionsRetryDelay, execute: {
                        firstly {
                            self.makeRequest(target: target, callBackQueue: callBackQueue, progress: progress, attemptNumber: attemptNumber + 1)
                        }.then { json in
                            fulfill(json)
                        }.catch { error in
                            reject(error)
                        }
                    })
                }
            })
        }
    }
    
}
