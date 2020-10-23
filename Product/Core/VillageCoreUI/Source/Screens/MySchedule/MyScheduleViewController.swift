import UIKit
import WebKit
import VillageCore

class MyScheduleViewController: UIViewController {
	public static func create() -> MyScheduleViewController {
		let storyboard = UIStoryboard(name: "MySchedule", bundle: Constants.bundle)
        return storyboard.instantiateInitialViewController() as! MyScheduleViewController
 	}

	@IBOutlet weak var webView: WKWebView? {
		didSet {
			loadInitialRequest()
		}
	}
	private var initialRequest: URLRequest? {
		didSet {
			loadInitialRequest()
		}
	}

	override func viewDidLoad() {
        super.viewDidLoad()
    }

	public func load(credentials: MySchedule.Credentials) {
		let url = URL(string: "https://schedule.donatos.com/schedule/pepptalk/getloginUser")!
		let body = "email=\(credentials.encryptedEmail)&securityKey=\(credentials.securityKey)"
		var request = try! URLRequest(url: url, method: .post)
		request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
		request.httpBody = body.data(using: .utf8)
		initialRequest = request
	}

	private func loadInitialRequest() {
		guard let request = initialRequest, let view = webView else { return }
		view.load(request)
		initialRequest = nil
	}
}
