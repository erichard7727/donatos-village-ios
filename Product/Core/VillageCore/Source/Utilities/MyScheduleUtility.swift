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
    
    private let service: VillageService
    private static let loginUrl = URL(string: "https://schedule.donatos.com/schedule/pepptalk/getloginUser")!
    
    public init(service: VillageService) {
        self.service = service
    }

    public func makeUrlRequest() -> Promise<URLRequest> {
        return fetchCredentials(using: service).then(composeUrlRequest)
    }

    private func fetchCredentials(using service: VillageService) -> Promise<Credentials> {
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

    private func composeUrlRequest(with credentials: Credentials) -> Promise<URLRequest> {
        return Promise { fulfull, reject in
            let body = "email=\(credentials.encryptedEmail)&securityKey=\(credentials.securityKey)"
            do {
                var request = try URLRequest(url: Self.loginUrl, method: .post)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = body.data(using: .utf8)
                fulfull(request)
            } catch {
                reject(error)
            }
        }
    }
}
