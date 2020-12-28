//
//  LinkMenuItemView.swift
//  VillageCoreUI
//
//  Created by Nikola Angelkovik on 12/24/20.
//  Copyright © 2020 WillowTree. All rights reserved.
//

import Foundation

final class LinkMenuItemView: UIView {
    
    // MARK: Public Properties
    
    var onTap: (LinkMenuItemModel) -> Void = { _ in }
    
    // MARK: Private Properties
    
    private let linkMenuItemModel: LinkMenuItemModel
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var gestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(handleTap(_:))
    )
    
    // MARK: Initialization
    
    init(linkMenuItemModel: LinkMenuItemModel) {
        self.linkMenuItemModel = linkMenuItemModel
        super.init(frame: .zero)
        commonInit()
        titleLabel.text = linkMenuItemModel.title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Private Methods

private extension LinkMenuItemView {
    
    func commonInit() {
        addGestureRecognizer(gestureRecognizer)
        setupTitleLabel()
    }
    
    func setupTitleLabel() {
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: Actions
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        onTap(linkMenuItemModel)
    }
}
