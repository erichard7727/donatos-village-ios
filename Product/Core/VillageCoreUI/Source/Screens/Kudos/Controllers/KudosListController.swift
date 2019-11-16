//
//  KudosListController.swift
//  VillageContainerApp
//
//  Created by Rob Feldmann on 3/31/17.
//  Copyright © 2017 Dynamit. All rights reserved.
//

import UIKit
import AlamofireImage
import Promises
import VillageCore

class KudosListController: UIViewController, StatefulUserInterface {
    
    enum List {
        case allStream
        case received(receiver: Person)
        case given(giver: Person)
        
//        var filter: FetchKudosFilters {
//            switch self {
//            case .allStream(_):
//                return .all
//
//            case .received(_):
//                return .received
//
//            case .given(_):
//                return .given
//            }
//        }
    }
    
    // MARK: - StatefulUserInterface
    
    enum UIState {
        case loading, content, empty
    }
    
    var interfaceState: UIState = .loading
    
    // MARK: - Pulic Vars
    
    var list: List!
    
    // MARK: - Private Outlets
    
    @IBOutlet fileprivate weak var tableView: UITableView? {
        didSet {
            tableView?.delegate = self
            
            tableView?.register(
                UINib(nibName: "KudoCell", bundle: Constants.bundle),
                forCellReuseIdentifier: "KudoCell"
            )
            
            tableView?.rowHeight = UITableView.automaticDimension
            tableView?.estimatedRowHeight = 30
            tableView?.tableFooterView = UIView()
            
            refreshControl = UIRefreshControl()
            refreshControl!.tintColor = UIColor.darkGray
            refreshControl!.addTarget(self, action: #selector(onRefresh(_:)), for: .valueChanged)
            tableView?.addSubview(refreshControl!)
        }
    }
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView? {
        didSet {
            loadingIndicator?.startAnimating()
        }
    }
    
    @IBOutlet weak var emptyLabel: UILabel? {
        didSet {
            emptyLabel?.isHidden = true
        }
    }
    
    // MARK: - Private Vars
    
    fileprivate var refreshControl: UIRefreshControl?
    
    var kudosList: [String: Kudos] = [:]
    var tupleArray: [(key: String, value: Kudos)] = []
    
    fileprivate var contentIDsLoading: Set<String> = []
    
    fileprivate var currentPage = 1
    
    fileprivate var loadingMoreKudos: Bool = false
    
//    fileprivate var receiverId: Int?
    
    fileprivate var currentUserId: Int?
    
    let progressIndicator = UIActivityIndicatorView(style: .gray)
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
        self.loadData() { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.tupleArray.count < 1 {
                strongSelf.setState(.empty, animated: true)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.list! {
        case .allStream:
            self.title = Constants.Settings.kudosSingularShort + " Stream"
        case .received(_), .given(_):
            self.title = "My " + Constants.Settings.kudosPluralShort
        }
        displayProgressFooterView()
    }
    
    // MARK: - Target/Action
    
    @objc internal func onRefresh(_ sender: AnyObject? = nil) {
        loadData() {
            [weak self] in
            self?.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Private Methods
    
    fileprivate func loadData(completionHandler: (() -> Void)? = nil) {
        self.loadingMoreKudos = true

        if currentPage == 1 && !kudosList.isEmpty {
            // Clear out existing data so we can reload it
            kudosList = [:]
        }
        
        let kudosPromise: Promise<Kudos> = {
            switch self.list {
            case .received(let receiver)?:
                return receiver.kudosReceived(page: self.currentPage)
                
            case .given(let giver)?:
                return giver.kudosGiven(page: self.currentPage)
            
            default:
                return User.current.getPerson().then { $0.kudosStream(page: self.currentPage) }
            }
        }()
        
        firstly {
            kudosPromise
        }.then { (kudos) in
            if self.kudosList.isEmpty && kudos.isEmpty {
                self.setState(.empty)
            }

            guard !kudos.isEmpty else {
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, yyyy"
            
            let groupedKudos = Dictionary(grouping: kudos, by: { kudo in kudo.date })
                .flatMap({ (key, value) -> [String: Kudos] in
                    return [formatter.string(from: key) : value]
                })
            
            groupedKudos.forEach({ (date, kudos) in
                let mergedKudos = self.kudosList[date, default: []] + kudos
                self.kudosList[date] = mergedKudos
            })
            
            self.tupleArray = self.kudosList
                .sorted { formatter.date(from: $0.0)!.compare(formatter.date(from: $1.0)!) == .orderedDescending }
            
            self.setState(.content, animated: true)
            
            guard let tableview = self.tableView else {
                return
            }
            
            tableview.reloadData()
            tableview.reloadSections(IndexSet(integersIn: 0...self.kudosList.count - 1), with: .none)
            self.currentPage = self.currentPage + 1
        }.catch { (error) in
            let alert = UIAlertController.dismissable(title: "Error Fetching Kudos", message: error.localizedDescription)
            self.present(alert, animated: true, completion: nil)
        }.always {
            self.loadingMoreKudos = false
            self.progressIndicator.alpha = 0
            completionHandler?()
        }
    }
}

extension KudosListController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return tupleArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionKey = tupleArray[section]
        return sectionKey.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "KudoCell", for: indexPath) as! KudoCell
        let array = tupleArray[indexPath.section].value
        let kudo = array[indexPath.row]
        
        let regAttributes = [NSAttributedString.Key.font: UIFont(name: "ProximaNova-Regular", size: 15.0)!]
        let boldAttributes = [NSAttributedString.Key.font: UIFont(name: "ProximaNova-SemiBold", size: 15.0)!]
        
        let receiverName = kudo.receiver.displayName ?? [kudo.receiver.firstName, kudo.receiver.lastName].compactMap({ $0 }).joined(separator: " ")
        let receiver = NSAttributedString(string: receiverName, attributes: boldAttributes)
        
        let senderName = kudo.sender.displayName ?? [kudo.sender.firstName, kudo.sender.lastName].compactMap({ $0 }).joined(separator: " ")
        let sender = NSAttributedString(string: senderName, attributes: boldAttributes)
        
        let title = NSMutableAttributedString()
        switch self.list! {
        case .allStream:
            // Ex: Jane Smith received kudos for Teamwork from John Doe
            title.append(receiver)
            title.append(NSAttributedString(string: " received a \(Constants.Settings.kudosSingularShort) for \(kudo.achievementTitle) from ", attributes: regAttributes))
            title.append(sender)
            
        case .received(_):
            // Ex: John Doe gave you kudos for Teamwork
            title.append(sender)
            if currentUserId == kudo.receiver.id {
                title.append(NSAttributedString(string: " gave you a \(Constants.Settings.kudosSingularShort) for \(kudo.achievementTitle)", attributes: regAttributes))
            } else {
                title.append(NSAttributedString(string: " gave ", attributes: regAttributes))
                title.append(receiver)
                title.append(NSAttributedString(string:  " a \(Constants.Settings.kudosSingularShort) for \(kudo.achievementTitle)", attributes: regAttributes))
            }
            
        case .given(_):
            // Ex: You gave Jane Smith kudos for Teamwork
            title.append(NSAttributedString(string: "You gave ", attributes: regAttributes))
            title.append(receiver)
            title.append(NSAttributedString(string: " a \(Constants.Settings.kudosSingularShort) for \(kudo.achievementTitle)", attributes: regAttributes))
            
        }
        
        cell.configure(kudo: kudo, delegate: self)

        return cell
        
    }

}

// MARK: - KudoStreamViewDelegate

extension KudosListController: KudoStreamViewDelegate {

    func kudoStreamView(_ view: KudoStreamView, didSelectMoreOptions kudo: Kudo) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(
            title: "Report as Inappropriate",
            style: .destructive,
            handler: { [weak self] (_) in
                let confirm = UIAlertController(
                    title: "Confirm Report as Inappropriate",
                    message: "Are you sure you want to report this \(Constants.Settings.kudosSingularShort) as inappropriate? It will be removed immedaitely and your name will be recorded as the reporter.",
                    preferredStyle: .alert
                )
                confirm.addAction(UIAlertAction(
                    title: "Report as Inappropriate",
                    style: .destructive,
                    handler: { (_) in
                        kudo.flag().then({ [weak self] (flaggedKudo) in
                            self?.currentPage = 1
                            self?.loadData()
                        })
                }
                ))
                confirm.addAction(UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                ))
                self?.present(confirm, animated: true, completion: nil)
            }
        ))
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
        self.present(alert, animated: true, completion: nil)
    }

    func kudoStreamView(_ view: KudoStreamView, didSelectPerson person: Person) {
        let vc = UIStoryboard(name: "Directory", bundle: Constants.bundle).instantiateViewController(withIdentifier: "PersonProfileViewController") as! PersonProfileViewController
        vc.person = person
        vc.delegate = self
        self.show(vc, sender: self)
    }


}

// MARK: - UITableViewDelegate

extension KudosListController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30))
        view.backgroundColor = UIColor.white
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "ProximaNova-SemiBold", size: 15.0)
        label.textColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 0.9494881466)
        view.addSubview(label)
        
        let viewsDict = ["label": label]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[label]-|", options: [], metrics: nil, views: viewsDict))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]-|", options: [], metrics: nil, views: viewsDict))
        
        label.text = tupleArray[section].key.uppercased()
        
        return view
    }

}

// MARK: - StatefulUserInterface

extension KudosListController {
    
    func updateUserInterfaceForState(_ state: KudosListController.UIState, previousState: KudosListController.UIState) {
        
        switch state {
        case .loading:
            loadingIndicator?.startAnimating()
            
        case .content:
            loadingIndicator?.stopAnimating()
            
            tableView?.isHidden = false
            emptyLabel?.isHidden = true
            
        case .empty:
            loadingIndicator?.stopAnimating()
            
            tableView?.isHidden = true
            
            if case .allStream = list! {
                emptyLabel?.text = "There aren't any \(Constants.Settings.kudosPluralShort) to show yet."
            } else {
                let verb: String
                switch list! {
                case .allStream,
                     .received(_):
                    verb = "received"
                case .given(_):
                    verb = "given"
                }
                emptyLabel?.text = "You have not \(verb) any \(Constants.Settings.kudosPluralShort) yet."
            }
            
            emptyLabel?.isHidden = false
        }
    }
    
}

extension KudosListController: UIScrollViewDelegate {
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: (self.tableView?.frame.width)!, height: 44))
        progressIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        progressIndicator.center = headerView.center
        headerView.addSubview(progressIndicator)
        progressIndicator.bringSubviewToFront(headerView)
        progressIndicator.startAnimating()
        progressIndicator.alpha = 0
        headerView.backgroundColor = UIColor.white
        tableView?.tableFooterView = headerView
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height + 44 {
            if !loadingMoreKudos {
                progressIndicator.alpha = 1
                loadingMoreKudos = true
                self.loadData(completionHandler: nil)
            }
        }
    }
}

// MARK: - PersonProfileViewControllerDelegate

extension KudosListController: PersonProfileViewControllerDelegate {

    func shouldShowAndStartDirectMessage(_ directMessage: VillageCore.Stream, controller: ContactPersonViewController) {
        let dataSource = DirectMessageStreamDataSource(stream: directMessage)
        let vc = StreamViewController(dataSource: dataSource)
        self.show(UINavigationController(rootViewController: vc), sender: self)
    }

}
