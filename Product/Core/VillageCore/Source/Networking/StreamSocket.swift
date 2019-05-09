//
//  StreamSocket.swift
//  VillageCore
//
//  Created by Rob Feldmann on 5/8/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation
import SwiftWebSocket
import SwiftyJSON

public enum StreamSocketError: Error {
    case badUrl
}

public protocol StreamSocketDelegate: class {
    func streamSocket(_ streamSocket: StreamSocket, didReceiveMessage message: Message)
    func streamSocket(_ streamSocket: StreamSocket, message messageId: String, wasLiked isLiked: Bool, by personId: Int)
}

public final class StreamSocket {
    
    /// Create a StreamSocket with a deferred connection; the connection is not
    /// opened until the .establishConnection() method is called.
    ///
    /// - Parameters:
    ///   - stream: The stream to monitor via this webSocket
    ///   - delegate: The object to receive notifications of incoming updates
    /// - Throws: StreamSocketError if something goes wrong
    public init(stream: Stream, delegate: StreamSocketDelegate) throws {
        self.stream = stream

        var urlComponents = URLComponents()
        urlComponents.scheme = "wss"
        urlComponents.host = URL(string: ClientConfiguration.current.appBaseURL)!.host
        urlComponents.path = "/api/streams/1.0/messages/\(stream.id)"
        urlComponents.query = "diagId=\(User.current.diagnosticId)"
        
        guard let url = urlComponents.url else {
            throw StreamSocketError.badUrl
        }
        
        self.url = url

        webSocket = WebSocket()
        webSocket.allowSelfSignedSSL = true
        webSocket.event.open = webSocketDidOpen
        webSocket.event.message = webSocketDidReceiveData(_:)
        webSocket.event.end = webSocketDidEnd(code:reason:wasClean:error:)
        self.delegate = delegate
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.closeConnection()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.establishConnection()
        }
    }
    
    /// Opens a deferred or closed connection. If the connection is already
    /// opened, this method does nothing.
    public func establishConnection() {
        webSocket.open(request: request)
    }

    /// Closes an open connection. If the connection is already
    /// closed, this method does nothing.
    public func closeConnection() {
        webSocket.close()
    }
    
    public let stream: Stream
    
    private let webSocket: WebSocket
    
    private weak var delegate: StreamSocketDelegate?
    
    private let url: URL
    
    private lazy var request: URLRequest = {
        var request = URLRequest(url: url)
        let cookieHeaders = HTTPCookieStorage.shared.cookies.map({ HTTPCookie.requestHeaderFields(with: $0) }) ?? [:]
        let combinedHeaders = (request.allHTTPHeaderFields ?? [:])?.merging(cookieHeaders, uniquingKeysWith: {(_, new) in return new })
        request.allHTTPHeaderFields = combinedHeaders
        return request
    }()
    
    deinit {
        webSocket.close()
    }

}

// MARK: - Private Methods

private extension StreamSocket { }

// MARK: - WebSocketEvents

private extension StreamSocket {
    
    /// An event to be called when the WebSocket connection's readyState changes to .open;
    /// this indicates that the connection is ready to send and receive data.
    private func webSocketDidOpen() { }
    
    /// An event to be called when a message is received from the server.
    private func webSocketDidReceiveData(_ data: Any) {
        guard let stringData = data as? String else {
            assertionFailure()
            return
        }
        
        let json = JSON(parseJSON: stringData)
        
        guard let action = json["action"].string else {
            // Ignore non-actions
            return
        }
        
        switch action {
        case "created":
            guard let incomingMessage = Message(from: json["message"]) else {
                assertionFailure("Unsupported created item")
                return
            }
            delegate?.streamSocket(self, didReceiveMessage: incomingMessage)
            
        case "updated":
            guard let messageId = json["message"]["id"].string else {
                assertionFailure("Unsupported updated item")
                return
            }
            
            if let likedByPersonId = json["likedBy"].int {
                delegate?.streamSocket(self, message: messageId, wasLiked: true, by: likedByPersonId)
            } else if let unlikedByPersonId = json["unlikedBy"].int {
                delegate?.streamSocket(self, message: messageId, wasLiked: false, by: unlikedByPersonId)
            } else {
                assertionFailure("Unsupported message update")
            }
            
        default:
            assertionFailure("Unhandled action \(action)")
            break
        }
    }
    
    /// An event to be called when the WebSocket process has ended;
    /// this event is guarenteed to be called once and can be used
    /// as an alternative to the "close" or "error" events.
    private func webSocketDidEnd(code : Int, reason : String, wasClean : Bool, error : Error?) { }
    
}
