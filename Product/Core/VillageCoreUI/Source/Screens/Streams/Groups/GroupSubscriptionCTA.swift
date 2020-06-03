//
//  GroupSubscriptionCTA.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 11/15/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import Promises

class GroupSubscriptionCTA: NibView {
    typealias ResponseHandler = (Response) -> Void

    enum Response {
        case didSubscribe(success: Bool)
        case viewDetails(VillageCore.Stream)
        case fetchDetailsErrored
    }

    var stream: VillageCore.Stream? {
        didSet {
            setupViews()
        }
    }

    var responseHandler: ResponseHandler?

    // Outlets
    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var subscribeButton: UIButton! {
        didSet {
            subscribeButton.layer.masksToBounds = true
        }
    }
    @IBOutlet private weak var subscribeLoader: UIActivityIndicatorView!

    @IBOutlet private weak var viewDetailsButton: UIButton! {
        didSet {
            viewDetailsButton.layer.masksToBounds = true
            viewDetailsButton.layer.borderColor = UIColor.vlgGreen.cgColor
            viewDetailsButton.layer.borderWidth = 2
        }
    }
    @IBOutlet private weak var detailLoader: UIActivityIndicatorView!

    convenience init(stream: VillageCore.Stream, responseHandler: @escaping ResponseHandler) {
        self.init()
        self.stream = stream
        self.responseHandler = responseHandler
        setupViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        [subscribeButton, viewDetailsButton].forEach { (button) in
            button.layer.cornerRadius = button.bounds.height / 2
        }
    }

    override func setupViews() {
        guard let stream = self.stream else {
            assertionFailure()
            titleLabel.text = ""
            return
        }
        let regAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "ProximaNova-Regular", size: 17)!,
        ]
        let title = NSMutableAttributedString(
            string: "You are viewing ",
            attributes: regAttributes
        )
        title.append(NSAttributedString(
            string: "\"\(stream.name)\"",
            attributes: [
                .font: UIFont(name: "ProximaNova-SemiBold", size: 17)!,
            ]
        ))
        title.append(NSAttributedString(
            string: ".",
            attributes: regAttributes
        ))
        titleLabel.attributedText = title
    }

    @IBAction func subscribe() {
        guard
            let stream = self.stream,
            let handler = responseHandler
        else { assertionFailure(); return }

        firstly { () -> Promise<Void> in
            setButton(subscribeButton, isLoading: true)
            return stream.subscribe()
        }.then {
            handler(.didSubscribe(success: true))
        }.catch { _ in
            handler(.didSubscribe(success: false))
        }.always { [weak self] in
            guard let `self` = self else { return }
            self.setButton(self.subscribeButton, isLoading: false)
        }
    }

    @IBAction func viewDetails() {
        guard
            let stream = self.stream,
            let handler = responseHandler
        else { assertionFailure(); return }

        firstly { () -> Promise<VillageCore.Stream> in
            if stream.hasDetails {
                return Promise(stream)
            } else {
                setButton(viewDetailsButton, isLoading: true)
                return stream.getDetails()
            }
        }.then { stream in
            handler(.viewDetails(stream))
        }.catch { _ in
            handler(.fetchDetailsErrored)
        }.always { [weak self] in
            guard let `self` = self else { return }
            self.setButton(self.viewDetailsButton, isLoading: false)
        }
    }

    private var _preLoadingText: String?
    private func setButton(_ button: UIButton, isLoading: Bool) {
        view.isUserInteractionEnabled = !isLoading

        let loader: UIActivityIndicatorView = {
            switch button {
            case subscribeButton:
                return subscribeLoader

            case viewDetailsButton:
                return detailLoader

            default:
                fatalError()
            }
        }()

        switch (loader.isAnimating, isLoading) {
        case (false, true):
            _preLoadingText = button.title(for: .normal)
            button.setTitle(nil, for: .normal)
            loader.startAnimating()
        case (true, false):
            button.setTitle(_preLoadingText, for: .normal)
            loader.stopAnimating()
        case (true, true),
             (false, false):
            return
        }
    }
}
