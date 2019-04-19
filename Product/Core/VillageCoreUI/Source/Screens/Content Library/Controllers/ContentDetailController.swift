//
//  ContentDetailController.swift
//  VillageCore
//
//  Created by Colin Drake on 2/26/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import WebKit
import SafariServices
import VillageCore
//import FirebaseAnalytics

/// View controller for content detail view.
final class ContentDetailController: UIViewController {
    // MARK: Properties

    /// Web view for displaying content.
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: view.bounds)
        view.addSubview(webView)
        return webView
    }()

    /// Content item to display.
    var contentItem: ContentLibraryItem?

    var progressIndicator: ProgressIndicator!

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])

        setUpWebView()

        self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)

        self.progressIndicator.show()
    }

    func setUpWebView() {
        guard let contentItem = self.contentItem else { return }

        title = contentItem.name

        do {
            // Instantiate full-screen web view.
            webView.scrollView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
            webView.navigationDelegate = self
            webView.load(try contentItem.request())
        } catch {
            let alert = UIAlertController.dismissable(title: "We're Sorry", message: "The selected item could not be displayed.")
            self.present(alert, animated: true, completion: nil)
        }

        switch contentItem.type {
        case .link:
            AnalyticsService.logEvent(name: AnalyticsEventViewItem, parameters: [AnalyticsParameterItemLocationID: "content library" as NSObject, AnalyticsParameterItemCategory: "link" as NSObject, AnalyticsParameterItemName: "Link \(contentItem.name)" as NSObject])
        case .file:
            AnalyticsService.logEvent(name: AnalyticsEventViewItem, parameters: [AnalyticsParameterItemLocationID: "content library" as NSObject, AnalyticsParameterItemCategory: "file" as NSObject, AnalyticsParameterItemName: "File \(contentItem.name)" as NSObject])
        case .contentPage:
            AnalyticsService.logEvent(name: AnalyticsEventViewItem, parameters: [AnalyticsParameterItemLocationID: "content library" as NSObject, AnalyticsParameterItemCategory: "page" as NSObject, AnalyticsParameterItemName: "Page \(contentItem.name)" as NSObject])
        default:
            break
        }
    }

}

extension ContentDetailController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressIndicator.hide()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard contentItem?.type == .link else {
            // Allow everything else to go through immediately
            decisionHandler(.allow)
            return
        }
        
        guard let url = navigationAction.request.url,
              !url.absoluteString.contains(ClientConfiguration.current.appBaseURL)
        else {
            // Allow this webview to process Village links so the user will remain authenticated
            decisionHandler(.allow)
            return
        }
        
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { [weak self] (success) in
            let nav = self?.navigationController
            nav?.popViewController(animated: false)
            
            if !success {
                // not a universal link or app not installed
                let sfvc = SFSafariViewController(url: url)
                nav?.visibleViewController?.present(sfvc, animated: true, completion: nil)
            }
        }
        
        decisionHandler(.cancel)
    }
}
