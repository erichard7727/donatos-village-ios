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

class ViewNoticeViewController: UIViewController, NavBarDisplayable {
    
    var notice: Notice!

    var didUpdateNotice: ((Notice) -> Void)?

    var progressIndicator: ProgressIndicator!
    
    @IBOutlet weak var acknowledgeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!

    @IBOutlet private var rsvpContainer: UIView!
    @IBOutlet private var rsvpSegmentedControl: UISegmentedControl!

    weak var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setOpaqueNavbarAppearance(for: navigationItem, in: navigationController)
        self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)

        if notice.type == .event {
            updateRSVP(for: self.notice)
            rsvpContainer.isHidden = false
            acknowledgeHeightConstraint.constant = 0
        } else {
            rsvpContainer.isHidden = true

            if (notice.acknowledgeRequired && notice.isAcknowledged) || !notice.acknowledgeRequired {
                rsvpContainer.isHidden = true
                acknowledgeHeightConstraint.constant = 0
            }
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
            title: NSLocalizedString("Confirm", comment: ""),
            message: NSLocalizedString("By confirming here you are agreeing that you have read this notice and any attachments", comment: ""),
            preferredStyle: .alert
        )
        
        let noAlertAction = UIAlertAction(title: NSLocalizedString("No, take me back", comment: ""), style: .default, handler: nil)
        
        let yesAlertAction = UIAlertAction(title: NSLocalizedString("Yes, I read it", comment: ""), style: .default, handler: { action in
            guard let notice = self.notice else {
                return
            }
            
            firstly {
                notice.acknowledge()
            }.then { [weak self] notice in
                self?.didUpdateNotice?(notice)
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

    @IBAction func rsvpChanged(_ sender: UISegmentedControl) {
        let rsvp: Notice.RSVPResponse?
        if sender.selectedSegmentIndex == 0 {
            rsvp = .yes
        } else if sender.selectedSegmentIndex == 1 {
            rsvp = .maybe
        } else if sender.selectedSegmentIndex == 2 {
            rsvp = .no
        } else {
            rsvp = nil
        }

        guard let response = rsvp else {
            assertionFailure()
            return
        }

        progressIndicator.show()

        firstly {
            notice.rsvp(response)
        }.then { [weak self] (notice) in
            self?.notice = notice
            self?.updateRSVP(for: notice)
            self?.didUpdateNotice?(notice)
        }.catch { [weak self] _ in
            let alert = UIAlertController.dismissable(title: "Error", message: "There was a problem updating your RSVP status. Please try again.")
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.progressIndicator.hide()
        }
    }

    private var isRootViewController: Bool {
        return (navigationController?.viewControllers ?? []).count <= 1
    }
    
    private func installBackButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.named("back-button")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(navigateBack(_:))
        )
    }
    
    private func installMenuButton() {
        guard isRootViewController else {
            return
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage.named("menu-icon")?.withRenderingMode(.alwaysTemplate),
            style: .plain,
            target: self,
            action: #selector(showMenu(_:))
        )
    }
    
    @objc private func navigateBack(_ sender: Any? = nil) {
        guard
            let webView = self.webView,
            webView.canGoBack,
            let backURL = webView.backForwardList.backList.last?.url,
            webView.backForwardList.currentItem?.url != backURL
        else {
            navigationController?.popViewController(animated: true)
            return
        }
        
        var backRequest = URLRequest(url: backURL)
        let cookieHeaders = HTTPCookieStorage.shared.cookies.map({ HTTPCookie.requestHeaderFields(with: $0) }) ?? [:]
        let combinedHeaders = (backRequest.allHTTPHeaderFields ?? [:])?.merging(cookieHeaders, uniquingKeysWith: {(_, new) in return new })
        backRequest.allHTTPHeaderFields = combinedHeaders
        
        webView.goBack()
        DispatchQueue.main.async {
            webView.load(backRequest)
        }

        self.installMenuButton()
    }
    
    @objc private func showMenu(_ sender: Any? = nil) {
        showSideMenu()
    }

    private func updateRSVP(for notice: Notice) {
        guard notice.type == .event else { return }

        switch notice.eventRsvpStatus {
        case .yes:
            rsvpSegmentedControl.selectedSegmentIndex = 0
        case .maybe:
            rsvpSegmentedControl.selectedSegmentIndex = 1
        case .no:
            rsvpSegmentedControl.selectedSegmentIndex = 2
        case .none:
            rsvpSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }
}

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
            installBackButton()
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
