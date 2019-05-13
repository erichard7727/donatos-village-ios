//
//  HomeController.swift
//  VillageContainerApp
//
//  Created by Russell Stephenson on 10/19/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import VillageCore

class HomeController: UIViewController {
    
    fileprivate var homeStream: HomeStream?
    
    fileprivate var unreadMessageCounts: [String: Int]?
    
    fileprivate var lastUnreadGroupMessageCounts = 0
    fileprivate var initialLoad = false
    
    // Width and Height of recent activity collection view cells
    fileprivate var cellHeight: CGFloat!
    fileprivate var cellWidth: CGFloat!
    
    // Height of alert container and boolean for whether the alert is displayed
    fileprivate var alertHeight: CGFloat = 0.0
    fileprivate var isAlert: Bool = false
    
    fileprivate var activityLabelWidth: CGFloat = 0.0
    
    // Height of image inside recent activity collection view cells
    fileprivate let imageSize: CGFloat = 125.0
    
    // Boolean for collapsable collection view
    fileprivate var isRecentActivityOpen: Bool = false
    
    // Boolean to check whether the user is part of any groups
    fileprivate var groupsMembership: Bool {
        return !(homeStream?.streams ?? []).isEmpty
    }
    
    //Boolean to check whether cache has been loaded
    fileprivate var hasCacheLoaded: Bool = true
    
    fileprivate var backgroundColor: UIColor!
    
    fileprivate var progressIndicator: ProgressIndicator!
    
    fileprivate var dimView: UIView!
    
    fileprivate var FILE_NAME_CONST = "homestreamBanner.png"
    
    // Banner variables
    @IBOutlet weak var contentImageView: UIImageView! {
        didSet {
            contentImageView.image = UIImage.named("default-notice-header")
        }
    }
    @IBOutlet weak var contentTitleLabel: UILabel!
    
    // Variables for child scrollable views
    @IBOutlet weak var recentActivityCollectionView: UICollectionView!
    @IBOutlet weak var recentKudosCollectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Scroll views container
    @IBOutlet weak var containerView: UIView!
    
    // Constraints from the top of recent activity collection view to either the top of the super view or to the recent activity label
    @IBOutlet var constraintToView: NSLayoutConstraint!
    @IBOutlet weak var constraintToLabel: NSLayoutConstraint!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var recentActivityLabel: UILabel!
    @IBOutlet weak var recentKudosLabel: UILabel! {
        didSet {
            recentKudosLabel.text = "Recent \(Constants.Settings.kudosPluralLong)".uppercased()
        }
    }
    
    // Constraint to remove alertfrom the superview if no alert is present
    @IBOutlet weak var alertHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertImage: UIImageView!
    @IBOutlet weak var alertContainer: UIView!
    
    @IBOutlet weak var learnMoreButton: UIButton! {
        didSet {
            learnMoreButton.layer.cornerRadius = 16.0
        }
    }
    
    @IBOutlet weak var rightMenuButton: UIBarButtonItem!
    
    //delete once kudos is implemented
    @IBOutlet weak var kudosContainerHeight: NSLayoutConstraint!
    fileprivate var kudosHeight: CGFloat = 0
    
    fileprivate var kudosEnabled: Bool = true
    
    //MARK: Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
        let cellNib = UINib(nibName: "RecentActivityCell", bundle: Constants.bundle)
        recentActivityCollectionView.register(cellNib, forCellWithReuseIdentifier: "ActivityCell")
        
        let cellNib2 = UINib(nibName: "JoinGroupCell", bundle: Constants.bundle)
        recentActivityCollectionView.register(cellNib2, forCellWithReuseIdentifier: "JoinGroupCell")
        
        let kudosCellNib = UINib(nibName: "KudosHomeCell", bundle: Constants.bundle)
        recentKudosCollectionView.register(kudosCellNib, forCellWithReuseIdentifier: "KudosHomeCollectionCell")
        
        let kudosCellNib2 = UINib(nibName: "GiveKudosCell", bundle: Constants.bundle)
        recentKudosCollectionView.register(kudosCellNib2, forCellWithReuseIdentifier: "GiveKudosCell")
        
        self.progressIndicator = ProgressIndicator.progressIndicatorInView(self.view)
        
        cellWidth = self.view.frame.width * 0.95
        cellHeight = 113.0
        
        backgroundColor = UIColor.clear
        
        if !Constants.Settings.kudosEnabled {
            kudosHeight = kudosContainerHeight.constant
            kudosContainerHeight.constant = 0
        }
        
        setupBackgrounds()
        
        var navHeight: CGFloat = 0
        if let navController = self.navigationController {
            navHeight = navController.navigationBar.bounds.height + UIApplication.shared.statusBarFrame.height
        }
        
        alertHeight = alertHeightConstraint.constant
        alertHeightConstraint.constant = 0
        
        if containerViewHeightConstraint.constant < self.view.bounds.height - navHeight {
            containerViewHeightConstraint.constant = self.view.bounds.height - navHeight
            view.layoutIfNeeded()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClickOnView))
        self.alertContainer.addGestureRecognizer(tapGesture)
        
        scrollView.bounces = true
        
        recentKudosCollectionView.alpha = 0
        recentActivityCollectionView.alpha = 0
        
        recentActivityLabel.alpha = 0
        recentKudosLabel.alpha = 0
        
        NotificationCenter.default.addObserver(forName: Notification.Name.User.CurrentUserDidChange, object: nil, queue: .main) { [weak self] (_) in
            self?.closeRecentActivityClick()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !isRecentActivityOpen {
            hideNavigationBar()
        }
        
        // Deactivate this constraint since it serves no purpose other than it's constant value
        NSLayoutConstraint.deactivate([constraintToView])
        
        // Disable right menu button because it is only used when closing the recent activity collapse
        rightMenuButton.isEnabled = isRecentActivityOpen
        rightMenuButton.tintColor = isRecentActivityOpen ? UINavigationBar.appearance().tintColor : UIColor.clear
        
        getHomeStream()
    }
    
    func updateNewsItemVisual(title: String, id: String, image: UIImage?) {
        self.contentTitleLabel.textAlignment = .center
        self.contentTitleLabel.attributedText = NSAttributedString.shaddowedAttributedString(string: title, fontSize: 24, variant: "ExtraBld")
        if let i = image {
            self.contentImageView.image = i
        }
        self.learnMoreButton.alpha = 1
        self.learnMoreButton.isEnabled = true
    }
    
    func saveImageToDirectory(image: UIImage) {
        let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        // create a name for your image
        let fileURL = documentsDirectoryURL.appendingPathComponent(FILE_NAME_CONST)
        do {
            try image.pngData()?.write(to: fileURL)
        } catch {
            
        }
    }
    
    func getImageFromDirectory() -> UIImage? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: paths).appendingPathComponent(FILE_NAME_CONST)
        
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteImageFromDirectory() -> Bool {
        let fileManager = FileManager.default
        let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        // create a name for your image
        let fileURL = documentsDirectoryURL.appendingPathComponent(FILE_NAME_CONST)
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            return false
        }
        return true
    }
    
    func getHomeStream() {
        
        if homeStream == nil {
            progressIndicator.show()
        }
        
        firstly {
            HomeStream.fetch()
        }.then { [weak self] homeStream in
            self?.homeStream = homeStream
            self?.displayUI(homeStream: homeStream)
        }.catch { [weak self] error in
            let alert = UIAlertController(title: "Error", message: "There was a problem downloading your data.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in self?.getHomeStream() }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }.always { [weak self] in
            self?.progressIndicator.hide()
        }
    }
    
    func displayUI(homeStream: HomeStream) {
        if let notice = homeStream.notice,
           !notice.isAcknowledged
            && notice.acknowledgeRequired {
            self.isAlert = true
        } else {
            self.alertHeightConstraint.constant = 0
            self.alertImage.alpha = 0
            self.isAlert = false
        }
        
        if let news = homeStream.news {
            if !news.mediaAttachments.isEmpty {
                if let attachment = news.mediaAttachments.first(where: { $0.isThumbnailImage }) {
                    let filter = AspectScaledToFillSizeFilter(size: self.contentImageView.frame.size)
                    self.contentImageView.af_setImage(
                        withURL: attachment.url,
                        placeholderImage: UIImage.named("default-notice-header")!,
                        filter: filter,
                        progress: nil,
                        imageTransition: .crossDissolve(0.35),
                        runImageTransitionIfCached: false,
                        completion: { [weak self] image in
                            if let img = image.value {
                                self?.saveImageToDirectory(image: img)
                            }
                        }
                    )
                    self.updateNewsItemVisual(title: news.title, id: attachment.id, image: nil)
                }
            } else {
                self.updateNewsItemVisual(title: news.title, id: news.id, image: UIImage.named("default-notice-header")!)
                
            }
            self.contentTitleLabel.textAlignment = .center
        }
            

        self.recentActivityCollectionView.reloadData()
        
        self.recentKudosCollectionView.reloadData()
        
        if let title = self.homeStream?.notice?.title {
            self.alertTitle.text = "Action Required: " + title
            self.alertHeightConstraint.constant = self.alertHeight
        }
        
        self.recentActivityCollectionView.alpha = 1
        self.recentActivityLabel.alpha = 1
        self.recentKudosCollectionView.alpha = 1
        self.recentKudosLabel.alpha = 1
        self.recentKudosLabel.sizeToFit()

        self.alertTitle.alpha = 1
        let image = UIImage.named("notice-needs-action")
        let tintedImage = image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.alertImage.image = tintedImage
        self.alertImage.tintColor = .white
        self.view.updateConstraints()
        self.view.layoutIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        showNavigationBar()
    }
    
    func setupBackgrounds() {
        self.recentActivityCollectionView.backgroundView?.backgroundColor = UIColor.clear
        self.recentKudosCollectionView.backgroundView?.backgroundColor = UIColor.clear
        self.recentKudosCollectionView.backgroundColor = UIColor.clear
    }
    
    //MARK: Actions
    
    func showNavigationBar() {
        let animation = CATransition()
        animation.duration = 0.35
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade

        self.navigationController?.navigationBar.layer.add(animation, forKey: nil)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)

        UIView.animate(withDuration: 0.35, animations: {
            self.navigationController?.navigationBar.isTranslucent = false
            self.navigationController?.navigationBar.shadowImage = nil
        })
    }
    
    func hideNavigationBar() {
        
        let animation = CATransition()
        animation.duration = 0.35
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.fade

        let shaddow = NSShadow()
        shaddow.shadowColor = UIColor.black
        shaddow.shadowOffset = CGSize(width: 1, height: 1)
        shaddow.shadowBlurRadius = 10

        if let navController = self.navigationController {
            navController.navigationBar.layer.add(animation, forKey: nil)
            navController.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)

            UIView.animate(withDuration: 0.35, animations: {

                navController.navigationBar.isTranslucent = true
                navController.navigationBar.shadowImage = UIImage()
            })
        }
    }
    
    @IBAction func closeRecentActivityClick(_ sender: Any? = nil) {
        if isRecentActivityOpen {
            hideNavigationBar()
            // Animate constraint updates to collapse the recent activity collection view
            isRecentActivityOpen = false
            constraintToLabel.constant = 4
            if isAlert {
                alertHeightConstraint.constant = alertHeight
            }
            collectionViewBottomConstraint.constant = -48
            recentActivityCollectionView.scrollToItem(at: NSIndexPath(row: 0,section: 0) as IndexPath, at: .bottom, animated: false)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                if self.isAlert {
                    self.alertImage.alpha = 1.0
                }
                self.recentActivityCollectionView.backgroundColor = self.backgroundColor
                self.view.layoutIfNeeded()
                self.recentActivityCollectionView.reloadSections([0])
                self.rightMenuButton.isEnabled = false
                self.rightMenuButton.tintColor = UIColor.clear
                }, completion: {data in
                    self.scrollView.isScrollEnabled = true
                    self.scrollView.bounces = true
                    self.recentActivityCollectionView.isScrollEnabled = false
            })
        }
    }
    
    @IBAction func contentButtonClick(_ sender: UIButton) {
        // On Learn More button tap in the banner, take the user to the content item.
        let controller = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ViewNoticeVC") as! ViewNoticeViewController
        controller.notice = homeStream?.news
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc func onClickOnView(){
        let controller = UIStoryboard(name: "Notices", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ViewNoticeVC") as! ViewNoticeViewController
        controller.notice = homeStream?.notice
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: UICollectionViewDelegate

extension HomeController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case recentActivityCollectionView:
            if groupsMembership {
                if indexPath.row == 0 && !isRecentActivityOpen {
                    // Update constraint to expand the recent activity collection view
                    showNavigationBar()
                    isRecentActivityOpen = true
                    constraintToLabel.constant = constraintToLabel.constant - constraintToView.constant + alertHeight + kudosHeight + 64
                    alertHeightConstraint.constant = 0
                    self.scrollView.contentOffset.y = 0.0
                    collectionViewBottomConstraint.constant = containerView.frame.height - scrollView.frame.height
                    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                        self.alertImage.alpha = 0
                        collectionView.backgroundColor = UIColor.white
                        self.view.layoutIfNeeded()
                        collectionView.reloadSections([0])
                        self.rightMenuButton.isEnabled = true
                        self.rightMenuButton.tintColor = .white
                        }, completion: {data in
                            self.scrollView.isScrollEnabled = false
                            self.recentActivityCollectionView.isScrollEnabled = true
                            self.scrollView.bounces = false
                            self.recentActivityCollectionView.bounces = true
                    })
                } else if collectionView == recentActivityCollectionView  && isRecentActivityOpen {
                    recentActivityCollectionView.deselectItem(at: indexPath, animated: true)
                    guard let selectedGroup = homeStream?.streams[indexPath.item] else {
                        assertionFailure()
                        return
                    }
                    let vc = UIStoryboard(name: "Groups", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GroupViewController") as! GroupViewController
                    vc.group = selectedGroup
                    vc.delegate = self
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                let vc = UIStoryboard(name: "OtherGroupsListViewController", bundle: Constants.bundle).instantiateInitialViewController() as! OtherGroupsListViewController
                self.navigationController?.pushViewController(vc, animated: true)
            }
            
        case recentKudosCollectionView:
            if indexPath.row == 3 || indexPath.row == homeStream?.kudos.count {
                transitionToGiveKudos()
            } else {
                showKudos(indexPath: indexPath)
            }
        
        default:
            assertionFailure()
            break
        }
    }
    
    fileprivate func transitionToGiveKudos() {
        let controller = UIStoryboard(name: "Kudos", bundle: Constants.bundle).instantiateViewController(withIdentifier: "GiveKudosViewController") as! GiveKudosViewController
        sideMenuController?.setContentViewController(UINavigationController(rootViewController: controller), fadeAnimation: true)
    }
    
    func showKudos(indexPath: IndexPath) {
        self.modalPresentationStyle = .overCurrentContext
        let singleKudos = homeStream!.kudos[indexPath.item]
        let kudosCell = recentKudosCollectionView.cellForItem(at: indexPath) as! KudosHomeCell
        
        let regAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "ProximaNova-Regular", size: 15.0)!]
        let boldAttributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "ProximaNova-SemiBold", size: 15.0)!]
        let receiver = NSAttributedString(string: singleKudos.receiver.displayName ?? "Recipient", attributes: boldAttributes)
        let sender = NSAttributedString(string: singleKudos.sender.displayName ?? "Sender", attributes: boldAttributes)
        
        let title = NSMutableAttributedString()
        title.append(receiver)
        title.append(NSAttributedString(string: " received a \(Constants.Settings.kudosSingularShort) for \(singleKudos.achievementTitle) from ", attributes: regAttributes))
        title.append(sender)
        
        let vc = KudosModalView(nibName: "KudosModalView", bundle: Constants.bundle)
        vc.modalTransitionStyle = .crossDissolve
        vc.kudosTitle = title
        vc.kudosDescription = singleKudos.comment
        vc.points = singleKudos.points
        vc.avatar = kudosCell.avatarImageView.image
        vc.modalPresentationStyle = .overCurrentContext
        vc.dismissModal = { [weak self] in
            self?.removeDim()
        }
        self.animateDim()
        self.present(vc, animated: true, completion: nil)
    }
    
    func animateDim() {
        guard let navController = navigationController else {
            return
        }
        let blurEffect = UIBlurEffect(style: .dark)
        dimView = UIVisualEffectView(effect: blurEffect)
        dimView.frame = navController.view.frame
        dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimView.alpha = 0
        self.view.addSubview(dimView)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.dimView.alpha = 0.9
        })
    }
    
    func removeDim() {
        guard let navController = navigationController else {
            return
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.dimView.alpha = 0
        }, completion: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.dimView.removeFromSuperview()
            strongSelf.dimView = nil
            navController.navigationBar.layer.zPosition = 0
        })
    }
}

// MARK: UICollectionViewDataSource

extension HomeController: UICollectionViewDataSource {
    
    private func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case recentActivityCollectionView:
            if groupsMembership {
                let streams = homeStream?.streams ?? []
                if isRecentActivityOpen {
                    return streams.count
                } else {
                    if streams.isEmpty {
                        return 1
                    } else {
                        return min(streams.count, 3)
                    }
                }
            } else {
                return 1
            }
            
        case recentKudosCollectionView:
            let kudos = homeStream?.kudos ?? []
            return min(kudos.count + 1, 4)
            
        default:
            assertionFailure()
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case recentActivityCollectionView:
            if groupsMembership == true {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActivityCell", for: indexPath) as! RecentActivityCell
                
                //Fixes issue where bounds are 1000
                self.view.layoutIfNeeded()
                activityLabelWidth = cell.firstActivityLabel.bounds.width
                
                if !isRecentActivityOpen {
                    cell.isPanelOpen = false
                } else {
                    cell.isPanelOpen = true
                }
                
                let groupItem = homeStream!.streams[indexPath.item]
                cell.setCell(groupItem: groupItem)
                
                if let messageItem = groupItem.details?.mostRecentMessage, let url = messageItem.author.avatarURL {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.firstAvatarImageView.frame.size,
                        radius: cell.firstAvatarImageView.frame.size.height / 2
                    )
                    cell.firstAvatarImageView.af_setImage(withURL: url, filter: filter)
                }
                
                if isRecentActivityOpen {
                    if let messageItem = groupItem.details?.mostRecentMessage,
                       let attachment = messageItem.attachment {
                        cell.showProgressIndicator(true)
                        cell.messageImageViewHeightConstraint.constant = self.imageSize
                        if attachment.type == "image/gif" {
                            Alamofire.request(attachment.url, method: .get)
                                .responseImage { response in
                                    cell.showProgressIndicator(false)
                                    guard let image = response.data else {
                                        return
                                    }
                                    if let attachmentImage = UIImage(animatedImageData: image as Data) {
                                        cell.configureCellAnimatedAttachment(attachmentImage)
                                        cell.activityIndicatorView.stopAnimating()
                                        cell.activityIndicatorView.alpha = 0
                                    }
                                }
                        } else {
                            let size = CGSize(width: cell.messageImageView.frame.size.width, height: self.imageSize)
                            let filter = AspectScaledToFillSizeFilter(
                                size: size
                            )
                            cell.showProgressIndicator(true)
                            cell.messageImageView.af_setImage(
                                withURL: attachment.url,
                                filter: filter,
                                imageTransition: UIImageView.ImageTransition.crossDissolve(0.35),
                                runImageTransitionIfCached: false)
                            cell.activityIndicatorView.stopAnimating()
                            cell.activityIndicatorView.alpha = 0
                        }
                    }
                }
                
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "JoinGroupCell", for: indexPath) as! JoinGroupCell
                return cell
            }
            
        case recentKudosCollectionView:
            if indexPath.row == 3 || indexPath.row == homeStream?.kudos.count ?? 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GiveKudosCell", for: indexPath) as! GiveKudosCell
                
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KudosHomeCollectionCell", for: indexPath) as! KudosHomeCell
                
                let kudo = homeStream!.kudos[indexPath.item]
                cell.nameLabel.text = kudo.receiver.displayName
                cell.pointLabel.text = "+\(kudo.points)pts"
                cell.titleLabel.text = kudo.achievementTitle
                
                if let url = kudo.receiver.avatarURL {
                    let filter = AspectScaledToFillSizeWithRoundedCornersFilter(
                        size: cell.avatarImageView.frame.size,
                        radius: cell.avatarImageView.frame.size.height / 2
                    )
                    
                    cell.avatarImageView.af_setImage(withURL: url, filter: filter)
                }
                return cell
            }
            
        default:
            assertionFailure()
            return collectionView.dequeueReusableCell(withReuseIdentifier: "ActivityCell", for: indexPath)
        }
    }
}

//MARK: UICollectionViewDelegateFlowLayout
extension HomeController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //check if the recent activity is open and adjust the size of the collection view cell
        if collectionView == recentActivityCollectionView {
            if groupsMembership {
                if isRecentActivityOpen {
                    let firstmessage = homeStream!.streams[indexPath.item].details?.mostRecentMessage
                    
                    var size: CGSize = CGSize(width: 0.0, height: 0.0)
                    if let font = UIFont(name: "ProximaNova-Light", size: 17.0) {
                        var height: CGFloat = 0.0
                        
                        //adjust size based on label size
                        if firstmessage != nil {
                            height = (firstmessage?.body.heightWithConstraintWidth(width: activityLabelWidth, font: font))! + cellHeight
                        } else {
                            height = cellHeight
                        }
                        
                        //adjust size if there's an attachment
                        if firstmessage?.attachment != nil {
                            size = CGSize(width: CGFloat(cellWidth), height: CGFloat(height + imageSize))
                        } else {
                            size = CGSize(width: CGFloat(cellWidth), height: CGFloat(height))
                        }
                    }
                    return size
                } else if !isRecentActivityOpen {
                    let width = cellWidth - (CGFloat(indexPath.row) * 10)
                    let size = CGSize(width: width, height: cellHeight)
                    return size
                }
            }
        } else if collectionView == recentKudosCollectionView {
            return CGSize(width: 130.0, height: 130.0)
        }
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == recentActivityCollectionView && !isRecentActivityOpen {
            let spacing = 10 - cellHeight
            return CGFloat(spacing)
        } else if collectionView == recentKudosCollectionView {
            return CGFloat(24)
        }
        return CGFloat(8)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
    }
    
    //get number of lines for a label
    func getNumberOfLines(height: CGFloat) -> Int {
        if let font = UIFont(name: "ProximaNova-Light", size: 17.0) {
            let characterSize = lroundf(Float(font.leading))
            let labelHeight = lroundf(Float(height))
            return labelHeight / characterSize
        }
        return 0
    }
}

// MARK: - GroupViewControllerDelegate

extension HomeController: GroupViewControllerDelegate {
    
    func didLeaveGroup(_ group: VillageCore.Stream, controller: GroupViewController) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}


extension String {
    //get height of a label
    func heightWithConstraintWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let rect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let bounds = self.boundingRect(with: rect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return bounds.height
    }
}

extension NSAttributedString {
    
    static func shaddowedAttributedString(string: String, fontSize: CGFloat, variant: String) -> NSAttributedString {
        var fontName: String = ""
        if variant != "" {
            fontName = "ProximaNova-" + variant
        } else {
            fontName = "ProximaNova"
        }
        
        let font = UIFont.init(name: fontName, size: fontSize)!
        let shaddow = NSShadow()
        shaddow.shadowColor = UIColor.black
        shaddow.shadowOffset = CGSize(width: 1, height: 1)
        shaddow.shadowBlurRadius = 10
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .shadow: shaddow
        ]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
}
