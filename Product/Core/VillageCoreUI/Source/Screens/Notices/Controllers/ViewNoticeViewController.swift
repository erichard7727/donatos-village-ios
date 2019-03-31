//
//  ViewNoticeViewController.swift
//  VillageContainerApp
//
//  Created by Justin Munger on 8/31/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import WebKit
import VillageCore

class ViewNoticeViewController: UIViewController {
    
    var notice: Notice!

    var progressIndicator: ProgressIndicator!
    
    @IBOutlet weak var acknowledgeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    weak var webView: WKWebView?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)
        
        if (notice.acknowledgeRequired && notice.isAcknowledged) || !notice.acknowledgeRequired {
            acknowledgeHeightConstraint.constant = 0
        }
        
        // Configure title, etc.
        title = notice.title
        
        do {
            let request = try notice.detailRequest()
            
            // Instantiate full-screen web view.
            let webView = WKWebView(frame: containerView.bounds)
            webView.translatesAutoresizingMaskIntoConstraints = true
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.navigationDelegate = self
            webView.uiDelegate = self
            webView.load(request)
            containerView.addSubview(webView)
            self.webView = webView
            
            self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)
        } catch {
            let alert = UIAlertController.dismissable(title: "Error", message: "Unable to load content.")
            self.present(alert, animated: true, completion: nil)
        }
    }
        
    @IBAction func acknowledgeButtonPressed(_ sender: UIButton) {
        let acknowledgeAlertController = UIAlertController(
            title: "Do you Acknowledge?",
            message: "Please review this notice and any attachments. After reviewing, click the Yes button below and your acknowledgement will be recorded.", preferredStyle: .alert)
        
        let noAlertAction = UIAlertAction(title: "No", style: .default, handler: nil)
        
        let yesAlertAction = UIAlertAction(title: "Yes", style: .default, handler: { action in
            guard let notice = self.notice else {
                return
            }
            
            firstly {
                notice.acknowledge()
            }.then { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }.catch { [weak self] error in
                let alert = UIAlertController.dismissable(title: "Error", message: error.vlg_userDisplayableMessage)
                self?.present(alert, animated: true, completion: nil)
            }.always { [weak self] in
                self?.progressIndicator.hide()
            }
        })

        acknowledgeAlertController.addAction(noAlertAction)
        acknowledgeAlertController.addAction(yesAlertAction)
        
        present(acknowledgeAlertController, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: UIBarButtonItem!) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        }
    }
    
}

//extension ViewNoticeViewController {
//    @IBAction override func backButtonPressed(_ sender: UIBarButtonItem) {
//        if let navigationController = self.navigationController {
//            navigationController.popViewController(animated: true)
//        }
//    }
//}

extension ViewNoticeViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressIndicator.hide()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.progressIndicator.show()
    }
}

extension ViewNoticeViewController: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

extension URLRequest {
    mutating func addHeaders(_ headers: [String: String]) {
        if let existingHeaders = allHTTPHeaderFields {
            var allHeaders = existingHeaders
            allHeaders.merge(headers, uniquingKeysWith: {(_, new) in new })
            allHTTPHeaderFields = allHeaders
        } else {
            allHTTPHeaderFields = headers
        }
    }
}
