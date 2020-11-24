import Promises
import UIKit
import VillageCore
import WebKit

final class MyScheduleViewController: UIViewController, NavBarDisplayable {
    
    // MARK: Outlets

	@IBOutlet private var webView: WKWebView!
    
    // MARK: Private Properties
    
    private var myScheduleUtility: MyScheduleUtility!
    private lazy var loadingViewController = LoadingViewController()
    private var webViewObservation: NSKeyValueObservation?
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("My Schedule", comment: "")
        webViewObservation = webView.observe(\.estimatedProgress, changeHandler: progressViewChangeHandler)
        addBehaviors([LeftBarButtonBehavior(showing: .menuOrBack)])
        loadMySchedule()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setOpaqueNavbarAppearance(for: navigationItem, in: navigationController)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        webViewObservation?.invalidate()
        webViewObservation = nil
    }
    
    // MARK: Lifecycle
    
    deinit {
        webViewObservation?.invalidate()
    }
    
    // MARK: Create
    
    public static func create(myScheduleUtility: MyScheduleUtility) -> MyScheduleViewController {
        let storyboard = UIStoryboard(name: "MySchedule", bundle: Constants.bundle)
        let controller = storyboard.instantiateInitialViewController() as! MyScheduleViewController
        controller.myScheduleUtility = myScheduleUtility
        return controller
    }
}

// MARK: - Private Methods

private extension MyScheduleViewController {
    
    func loadMySchedule() {
        add(loadingViewController)
        
        myScheduleUtility
            .makeSingleSignOnUrlRequest()
            .then { [weak self] request in
                guard let webView = self?.webView else { return }
                webView.load(request)
            }
            .catch { [weak self] error in
                guard let self = self else { return }
                self.loadingViewController.remove()
                self.handleError(error)
            }
    }
    
    func handleError(_ error: Error) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Error", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    func progressViewChangeHandler<Value>(webView: WKWebView, change: NSKeyValueObservedChange<Value>) {
        guard webView.estimatedProgress >= 1.0 else { return }
        loadingViewController.remove()
    }
}
