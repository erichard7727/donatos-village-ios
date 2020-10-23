import Foundation
import Promises

public struct MySchedule {
	public struct Credentials {
		public let encryptedEmail: String
		public let securityKey: String
	}

	public enum Errors: Error {
		case missingProperty(name: String)
	}

	public static let loginUrl = URL(string: "https://schedule.donatos.com/schedule/pepptalk/getloginUser")!

	public static func fetchCredentials(using service: VillageService) -> Promise<Credentials> {
		return service.request(target: VillageCoreAPI.fetchCredentials)
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

	private init() {}
}
