import UIKit
import WebKit
import VillageCore

class MyScheduleViewController: UIViewController, NavBarDisplayable {
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
        title = NSLocalizedString("My Schedule", comment: "")
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)    
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setOpaqueNavbarAppearance(for: navigationItem, in: navigationController)
    }

	public func load(credentials: MySchedule.Credentials) {
		let body = "email=\(credentials.encryptedEmail)&securityKey=\(credentials.securityKey)"
        var request = try! URLRequest(url: MySchedule.loginUrl, method: .post)
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
