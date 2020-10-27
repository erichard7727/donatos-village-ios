//
//  EventStreamView.swift
//  VillageCoreUI
//
//  Created by Jack Miller on 9/19/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit
import VillageCore
import AlamofireImage
import Alamofire

protocol EventStreamViewDelegate: class {
    func eventStreamView(_ view: EventStreamView, didSelectEvent event: Notice)
}

class EventStreamView: NibView {
    
    // View Model
    var event: Notice?
    
    // Delegate
    weak var delegate: EventStreamViewDelegate?
    
    // Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var rsvpStatusLabel: UILabel!
    @IBOutlet private weak var yesButton: RSVPButton!
    @IBOutlet private weak var maybeButton: RSVPButton!
    @IBOutlet private weak var noButton: RSVPButton!
    @IBOutlet private weak var seeDetailsButton: UIButton!
    @IBOutlet weak var imageContainerView: UIView!
    @IBOutlet weak var imageContainerViewHeightConstraint: NSLayoutConstraint!
    
    override func setupViews() {
        self.applyCardStyle()
    }

    convenience init(event: Notice, delegate: EventStreamViewDelegate? = nil) {
        self.init()
        self.event = event
        self.delegate = delegate
        self.reloadViewData()
    }
    
    func reloadViewData() {
        titleLabel.text = event?.title
        
        if let imageUrl = event?.mediaAttachments.compactMap({ $0.url }).first {
            Alamofire.DataRequest.addAcceptableImageContentTypes(["binary/octet-stream"])
            backgroundImageView.vlg_setImage(withURL: imageUrl) { response in
                guard let image = response.value else { return }
                let aspectRatio = image.size.width / image.size.height
                self.imageContainerViewHeightConstraint.constant = self.imageContainerView.frame.width / aspectRatio
            }
        }

        if (event?.eventRsvpStatus ?? .none) == Notice.RSVPResponse.none && event?.acknowledgeRequired == true {
            rsvpStatusLabel.text = "RSVP Needed"
        } else {
            rsvpStatusLabel.text = "RSVP"
        }
        
        if let date = event?.eventStartDateTime {
            let dateString = date.longformFormat.uppercased()
            let df = DateFormatter()
            df.dateFormat = "h a"
            let timeString = df.string(from: date)
            dateLabel.text = dateString + " • " + timeString
        }
        
        self.configureRsvpButtons()
    }
    
    func configureRsvpButtons() {
        guard let event = event else { assertionFailure(); return }
        
        switch event.eventRsvpStatus {
        case .yes:
            yesButton.setSelectedStyle(true)
            maybeButton.setSelectedStyle(false)
            noButton.setSelectedStyle(false)
        case .no:
            yesButton.setSelectedStyle(false)
            maybeButton.setSelectedStyle(false)
            noButton.setSelectedStyle(true)
        case .maybe:
            yesButton.setSelectedStyle(false)
            maybeButton.setSelectedStyle(true)
            noButton.setSelectedStyle(false)
        case .none:
            yesButton.setSelectedStyle(false)
            maybeButton.setSelectedStyle(false)
            noButton.setSelectedStyle(false)
            
        }
    }
    
    @IBAction func replyYes() {
        self.submitResponse(.yes)
        self.event?.eventRsvpStatus = .yes
        self.configureRsvpButtons()
    }
    
    @IBAction func replyNo() {
        self.submitResponse(.no)
        self.event?.eventRsvpStatus = .no
        self.configureRsvpButtons()
    }
    
    @IBAction func replyMaybe() {
        self.submitResponse(.maybe)
        self.event?.eventRsvpStatus = .maybe
        self.configureRsvpButtons()
    }
    
    private func submitResponse(_ response: Notice.RSVPResponse) {
        guard let event = event else { assertionFailure(); return }
        
        firstly {
            event.rsvp(response)
        }.then { notice in
            self.event = notice
            self.reloadViewData()
        }.catch { _ in
            let alert = UIAlertController(title: "Error", message: "There was a problem submitting your response.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self.submitResponse(response) }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        }
    }
    
    @IBAction func seeDetails() {
        guard let event = event else { assertionFailure(); return }
        delegate?.eventStreamView(self, didSelectEvent: event)
    }
}

