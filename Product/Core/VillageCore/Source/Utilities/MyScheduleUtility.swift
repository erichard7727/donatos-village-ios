import Foundation
import Promises

public struct MyScheduleUtility {
	public struct Credentials {
		public let encryptedEmail: String
		public let securityKey: String
	}

	public enum Errors: Error {
		case missingProperty(name: String)
	}
    
    private static let loginUrl = URL(string: "https://schedule.donatos.com/schedule/pepptalk/getloginUser")!

    public static func makeUrlRequest() -> Promise<URLRequest> {
        return firstly {
            fetchCredentials(using: VillageService.shared)
        }.then {
            composeUrlRequest(with: $0)
        }
    }

	private init() {}
}

// MARK: - Private Methods

private extension MyScheduleUtility {
    
    static func fetchCredentials(using service: VillageService) -> Promise<Credentials> {
        return service
            .request(target: VillageCoreAPI.fetchCredentials)
            .then { json -> Credentials in
                guard let encryptedEmail = json["credentials", "encryptedEmail"].string else {
                    throw Errors.missingProperty(name: "encryptedEmail")
                }
                guard let securityKey = json["credentials", "securityKey"].string else {
                    throw Errors.missingProperty(name: "securityKey")
                }
                return Credentials(encryptedEmail: encryptedEmail, securityKey: securityKey)
            }
    }

    static func composeUrlRequest(with credentials: Credentials) -> Promise<URLRequest> {
        return Promise<URLRequest> { fulfull, reject in
            let body = "email=\(credentials.encryptedEmail)&securityKey=\(credentials.securityKey)"
            do {
                var request = try URLRequest(url: loginUrl, method: .post)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = body.data(using: .utf8)
                fulfull(request)
            } catch {
                reject(error)
            }
        }
    }
}
