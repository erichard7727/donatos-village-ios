//
//  ClientConfiguration.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

fileprivate class DummyClassForFindingFrameworkBundle { }

public extension Notification.Name {
    public struct ClientConfiguration {

        /// Posted whenever ClientConfiguration.current changes.
        public static let ConfigurationDidChange = Notification.Name(rawValue: "com.dynamit.villageCore.notification.name.clientConfiguration.configurationDidChange")
    }
}

public struct ClientConfiguration: Codable {
    
    public static var current: ClientConfiguration = { return getDefault() }() {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.ClientConfiguration.ConfigurationDidChange, object: current)
        }
    }
    
    public enum Error: Swift.Error {
        case missingConfigurationFile
        case invalidConfigurationFormat(DecodingError)
        
        public var localizedDescription: String {
            switch self {
            case .missingConfigurationFile:
                return "Could not find an NSDataAsset named 'client-configuration' in Bundle.main or in VillageCore."
                
            case .invalidConfigurationFormat(let decodingError):
                return decodingError.localizedDescription
            }
        }
    }
    
    public let licenseKey: String
    public let appBaseURL: String
    public let applicationName: String
    
    private static let bundle = Bundle(for: DummyClassForFindingFrameworkBundle.self)
    
    public init() throws {
        let configAsset: NSDataAsset
        if let clientAsset = NSDataAsset(name: "client-configuration", bundle: Bundle.main) {
            configAsset = clientAsset
        } else if let defaultAsset = NSDataAsset(name: "client-configuration", bundle: ClientConfiguration.bundle) {
            configAsset = defaultAsset
        } else {
            throw Error.missingConfigurationFile
        }
        
        do {
            let config = try PropertyListDecoder().decode(ClientConfiguration.self, from: configAsset.data)
            self = config
        } catch {
            throw Error.invalidConfigurationFormat(error as! DecodingError)
        }
    }
    
    private static func getDefault() -> ClientConfiguration {
        do {
            let clientConfig = try ClientConfiguration()
            return clientConfig
        } catch {
            fatalError("🛑 Failed to load essential client configuration: \(error.localizedDescription)")
        }
    }
    
}
