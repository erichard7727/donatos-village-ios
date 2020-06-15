//
//  Environment.swift
//  VillageCore
//
//  Created by Rob Feldmann on 2/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import Foundation

public enum Environment: String, Codable {
    case staging
    case production
}

extension Environment {
    
    struct Constants {
        static let licenseKey: String = "123456"
    }
    
    // MARK: - URLs

    private static let key: String = "CURRENT_ENVIRONMENT_KEY"

    private struct BaseURL {
        static let staging = URL(string: "https://donatos.villageappdev.com")!
        static let production = URL(string: "https://www.donatospepptalk.com")!
        static let apiComponent = "api"
    }
    
    private var baseURL: URL {
        switch self {
        case .staging:
            return BaseURL.staging
        case .production:
            return BaseURL.production
        }
    }
    
    public var appBaseURL: URL {
        return baseURL.appendingPathComponent(BaseURL.apiComponent)
    }
    
    // MARK: - Current Environment
    
    private static let defaultEnvironment: Environment = {
        #if DEBUG
            return .staging
        #else
            return .production
        #endif
    }()

    public static var current: Environment {
        get {
            guard let environmentRawValue = UserDefaults.standard.string(forKey: key),
                let selectedEnvironment = Environment(rawValue: environmentRawValue) else {
                return defaultEnvironment
            }
            return selectedEnvironment
        }

        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }

    
}
