//
//  VillageProvider.swift
//  VillageCore
//
//  Created by Rob Feldmann on 02/07/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Moya
import Result

// MARK: -

private extension VillageProvider {

    /// Encapsulates all of the information necesssary to re-create
    /// a Moya request so that it can be enqueued for later.
    ///
    /// Also adopts `Cancellable` so it can be cancled.
    private class QueuedRequest: Cancellable {
        let target: Target
        let callbackQueue: DispatchQueue?
        let progress: ProgressBlock?
        let completion: Completion

        init(target: Target, callbackQueue: DispatchQueue?, progress: ProgressBlock?, completion: @escaping Completion) {
            self.target = target
            self.callbackQueue = callbackQueue
            self.progress = progress
            self.completion = completion
        }

        // Cancellable Adherance
        var isCancelled = false
        func cancel() {
            isCancelled = true
        }
    }
}

// MARK: -

private extension VillageProvider {

    /// The `VillageAuthPlugin` is a Moya plugin that handles the
    /// authentication headers for the Village API.
    ///
    /// The `AuthorizedTargetType` is a target type extension that defines
    /// which endpoints should require the auth token as a header.
    ///
    /// - For each request, if it is NOT a GET request, it will add the
    ///     X-XSRF-TOKEN header
    /// - Each response is inspected, and the XSRF token is stored if it is
    ///   present in the response.
    ///
    /// The plugin does not know anything about how the tokens are stored. It
    /// takes a `GetTokenClosure` which is uses to get the current token, and
    /// a `SetTokenClosure` to update the value. The storage behavior is
    /// determined by implementor of the `SetTokenClosure`.
    struct VillageAuthPlugin: PluginType {
        let getToken: GetTokenClosure
        let setToken: SetTokenClosure

        func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
            guard target.method != .get, let xsrfToken = getToken() else {
                // XSRF Tokens are only required for non-GET requests
                // therefore don't do any unnecessary work
                return request
            }
            
            var mutableRequest = request
            mutableRequest.addValue(xsrfToken, forHTTPHeaderField: "X-XSRF-TOKEN")
            return mutableRequest
        }

        func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
            switch result {
            case let .success(response):
                if let headers = response.response?.allHeaderFields,
                   let xsrfToken = headers.valueForCaseInsensitiveKey("X-XSRF-TOKEN") as? String {
                    setToken(xsrfToken)
                }

            case .failure(_):
                break
            }

            // Don't update the the token if we didn't receive on, or on
            // network or other major failures
            return
        }

    }
}

// MARK: -

public  protocol AuthorizedTargetType: TargetType {

    /// Indicates that the target's endpoint requires an authenticated
    /// Village session
    var isAuthorized: Bool { get }
}

internal class VillageProvider<Target>: MoyaProvider<Target> where Target: AuthorizedTargetType {

    // Internal Declarations
    internal typealias Token = String
    internal typealias GetTokenClosure = () -> Token?
    internal typealias SetTokenClosure = (Token?) -> Void
    
    internal enum ReAuthenticationReason: Int {
        /// Received a 401 Unauthorized response
        case unauthorized = 401
        
        /// Received a 403 Forbidden response
        case xsrfToken = 403
    }
    
    internal typealias ReAuthenticationClosure = (_ reason: ReAuthenticationReason, _ completion: @escaping (_ success: Bool) -> Void) -> Void

    /// Custom errors that VillageProvider may return.
    ///
    /// - reAuthenticationFailed: An attempt to re-authenticate after a 401 was unsuccessful
    internal enum Error: Swift.Error {
        case reAuthenticationFailed
    }

    // Private Declarations

    private let reAuthenticate: ReAuthenticationClosure

    private let callbackQueue: DispatchQueue

    private let reAuthenticationInProgressQueue: DispatchQueue = DispatchQueue.init(label: "com.dynamit.villagecore.villageProvider.reAuthenticationInProgressQueue", qos: .default, attributes: .concurrent)

    /// Not thread-safe. Use self.reAuthenticationInProgress accessor instead.
    private var _reAuthenticationInProgress = false
    
    private let queuedRequestsQueue: DispatchQueue = DispatchQueue.init(label: "com.dynamit.villagecore.villageProvider.queuedRequestsQueue", qos: .default, attributes: .concurrent)

    /// Not thread-safe. Instead, use:
    ///  - self.add(_ newQueuedRequest: QueuedRequest)
    ///  - self.removeAllQueuedRequests(_ completion: @escaping ([QueuedRequest]) -> Void)
    private var _queuedRequests: [QueuedRequest] = []

    // Init

    internal init(endpointClosure: @escaping EndpointClosure = VillageProvider.defaultEndpointMapping,
         requestClosure: @escaping RequestClosure = VillageProvider.defaultRequestMapping,
         stubClosure: @escaping StubClosure = VillageProvider.neverStub,
         callbackQueue: DispatchQueue = .main,
         manager: Manager = MoyaProvider<Target>.defaultAlamofireManager(),
         plugins: [PluginType] = [],
         trackInflights: Bool = false,
         getToken: @escaping GetTokenClosure,
         setToken: @escaping SetTokenClosure,
         reAuthenticate: @escaping ReAuthenticationClosure) {

        self.callbackQueue = callbackQueue

        self.reAuthenticate = reAuthenticate

        super.init(endpointClosure: endpointClosure,
                   requestClosure: requestClosure,
                   stubClosure: stubClosure,
                   callbackQueue: callbackQueue,
                   manager: manager,
                   plugins: plugins + [VillageAuthPlugin(getToken: getToken, setToken: setToken)],
                   trackInflights: trackInflights)
    }

    // MoyaProvider Overrides
    
    /// Public designated request-making method.
    ///
    /// - Parameters:
    ///   - target: The request to make
    ///   - callbackQueue: A queue to call the completion handler on
    ///   - progress: Closure to be executed when progress changes
    ///   - completion: Closure to be executed when a request has completed
    /// - Returns: Token to cancel the request later
    @discardableResult
    override func request(_ target: Target, callbackQueue: DispatchQueue? = nil, progress: ProgressBlock? = nil, completion: @escaping Completion) -> Cancellable {
        return self.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion, isFromQueuedRequest: false, ignoreReAuthentication: false)
    }
    
    
    /// Request-making method that adds the option to ignore or bypass the
    /// automatic Re-Authentication mechanism.
    ///
    /// - Parameters:
    ///   - target: The request to make
    ///   - callbackQueue: A queue to call the completion handler on
    ///   - progress: Closure to be executed when progress changes
    ///   - ignoreReAuthentication: Ignores any authentication errors (401 or
    ///       403) and sends the request anyway. Useful for XSRF token refreshes
    ///   - completion: Closure to be executed when a request has completed
    /// - Returns: Token to cancel the request later
    @discardableResult
    internal func request(_ target: Target, callbackQueue: DispatchQueue? = nil, progress: ProgressBlock? = nil, ignoreReAuthentication: Bool, completion: @escaping Completion) -> Cancellable {
        return self.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion, isFromQueuedRequest: false, ignoreReAuthentication: ignoreReAuthentication)
    }
    
}

// MARK: - Private Methods

private extension VillageProvider {

    private var reAuthenticationInProgress: Bool {
        get {
            return reAuthenticationInProgressQueue.sync {
                _reAuthenticationInProgress
            }
        }
        set {
            reAuthenticationInProgressQueue.async(flags: .barrier) {
                self._reAuthenticationInProgress = newValue
            }
        }
    }

    private func add(_ newQueuedRequest: QueuedRequest) {
        queuedRequestsQueue.async(flags: .barrier) {
            self._queuedRequests.append(newQueuedRequest)
        }
    }

    /// Removes and returns all of the currently queued requests.
    ///
    /// - Parameter completion: A closure containing the removed requests.
    private func removeAllQueuedRequests(_ completion: @escaping ([QueuedRequest]) -> Void) {
        queuedRequestsQueue.async(flags: .barrier) {
            let queuedRequests = self._queuedRequests
            self._queuedRequests.removeAll()
            completion(queuedRequests)
        }
    }
    
    /// Cancels an array of `QueuedRequest`s with the specified error
    ///
    /// - Parameters:
    ///   - requests: The array of queued requests to cancel
    ///   - error: The error reason
    private func cancel(_ requests: [QueuedRequest], withError error: Error) {
        // fire off the completions of any queued requests
        requests.forEach({ (request) in
            let moyaError = MoyaError.underlying(error, nil)
            (request.callbackQueue ?? self.callbackQueue).async {
                request.completion(Result(error: moyaError))
            }
        })
    }

    private func performReAuthentication(_ reason: ReAuthenticationReason) {
        reAuthenticationInProgress = true

        reAuthenticate(reason) { success in
            self.reAuthenticationInProgress = false

            self.removeAllQueuedRequests({ (queuedRequests) in
                if success {
                    // fire off any queued requests
                    _ = queuedRequests.map(self.requestFromQueued)
                } else {
                    // fire off the completions of any queued requests
                    self.cancel(queuedRequests, withError: .reAuthenticationFailed)
                }
            })
        }

    }
    
    /// Private designated request-making method.
    ///
    /// This method adds an additional `isFromQueuedRequest` property so that
    /// we can handle errors differently from queued requests and prevent
    /// infinite loops from happening.
    ///
    /// - Parameters:
    ///   - target: The request to make
    ///   - callbackQueue: A queue to call the completion handler on
    ///   - progress: Closure to be executed when progress changes
    ///   - completion: Closure to be executed when a request has completed
    ///   - isFromQueuedRequest: Whether the request is from a previosly
    ///       queued request or not
    ///   - ignoreReAuthentication: Whether to bypass the reauth mechanism, which
    ///       is necessary for XSRF token refreshes
    /// - Returns: Token to cancel the request later
    func request(_ target: Target, callbackQueue: DispatchQueue? = nil, progress: ProgressBlock? = nil, completion: @escaping Completion, isFromQueuedRequest: Bool, ignoreReAuthentication: Bool) -> Cancellable {
        
        if ignoreReAuthentication || target.isAuthorized == false {
            // this is not an authorized request; send it through normally
            return super.request(target, callbackQueue: callbackQueue, progress: progress, completion: completion)
        }
        
        guard !reAuthenticationInProgress else {
            // a re-authorization is currently being attempted, therefore add this
            // request to the queue until the re-auth is completed
            let queuedRequest = QueuedRequest(target: target, callbackQueue: callbackQueue, progress: progress, completion: completion)
            self.add(queuedRequest)
            return queuedRequest
        }
        
        return super.request(target, callbackQueue: callbackQueue, progress: progress) { (result) in
            if case let .success(response) = result,
               let reAuthReason = ReAuthenticationReason(rawValue: response.statusCode) {
                
                if isFromQueuedRequest {
                    // call the original completion
                    (callbackQueue ?? self.callbackQueue).async {
                        completion(result)
                        
                        // the re-authentication attempt must have failed and we can't
                        // queue up requests any further else we'll be in an endless loop
                        self.removeAllQueuedRequests({ (queuedRequests) in
                            // fire off the completions of any queued requests
                            self.cancel(queuedRequests, withError: .reAuthenticationFailed)
                        })
                    }
                } else {
                    // queue this request while attempting to re-authenticate
                    self.add(QueuedRequest(target: target, callbackQueue: callbackQueue, progress: progress, completion: completion))
                    
                    self.performReAuthentication(reAuthReason)
                }
            } else {
                // the request did not return a statusCode indicating re-auth
                // was necessary; call the original completion
                (callbackQueue ?? self.callbackQueue).async {
                    completion(result)
                }
            }
        }
    }

    @discardableResult private func requestFromQueued(_ queuedRequest: QueuedRequest) -> Cancellable? {
        guard !queuedRequest.isCancelled else {
            (queuedRequest.callbackQueue ?? self.callbackQueue).async {
                self.cancelCompletion(queuedRequest.completion, target: queuedRequest.target)
            }
            return nil
        }
        return self.request(queuedRequest.target, callbackQueue: queuedRequest.callbackQueue, progress: queuedRequest.progress, completion: queuedRequest.completion, isFromQueuedRequest: true, ignoreReAuthentication: false)
    }

}
