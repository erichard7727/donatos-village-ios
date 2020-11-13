//
//  LoadingViewController.swift
//  VillageCoreUI
//
//  Created by Sasho Jadrovski on 11/9/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import UIKit

final class LoadingViewController: UIViewController {
    
    // MARK: Private Properties
    
    private lazy var activityIndicatorView = UIActivityIndicatorView.default
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupActivityIndicatorView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
            self?.activityIndicatorView.startAnimating()
        }
    }
}

// MARK: - UIActivityIndicatorView

private extension UIActivityIndicatorView {
    
    static var `default`: UIActivityIndicatorView {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .large)
        }
        return UIActivityIndicatorView(style: .gray)
    }
}

// MARK: - Private Methods

private extension LoadingViewController {
    
    func setupActivityIndicatorView() {
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
