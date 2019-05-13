//
//  ContentLibraryViewController.swift
//  VillageCore
//
//  Created by Michael Miller on 2/15/16.
//  Copyright © 2016 Dynamit. All rights reserved.
//

import UIKit
import VillageCore

// MARK: ContentLibraryViewController
final class ContentLibraryViewController: UIViewController {
    
    // MARK: Properties
    
    /// Base content item (folder) to show in.
    var baseContentItem: ContentLibraryItem? {
        didSet {
            guard let baseContentItem = baseContentItem else {
                return
            }
            
            guard baseContentItem.isDirectory else {
                assertionFailure()
                return
            }
            
            loadViewIfNeeded()
            
            title = baseContentItem.name
            
            self.loadingMoreContent = true
            activityIndicator.startAnimating()
            
            firstly {
                baseContentItem.getDirectory()
            }.then { (library) in
                if !library.isEmpty {
                    self.currentPage = self.currentPage + 1
                    self.contentItems = self.contentItems + library
                    self.tableview.reloadData()
                    self.tableview.reloadSections([0], with: .automatic)
                }
                
                self.emptyStateLabel.text = "There are no content items to display"
                self.emptyStateLabel.isHidden = self.contentItems.isEmpty ? false : true
            }.catch { (error) in
                let alert = UIAlertController.dismissable(title: "Error", message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
            }.always {
                self.loadingMoreContent = false
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    @IBOutlet weak var tableview: UITableView! {
        didSet {
            tableview.separatorStyle = UITableViewCell.SeparatorStyle.none
        }
    }
    
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    
    /// Indicates whether or not we're at the top level directory.
    var topLevel: Bool {
        return baseContentItem == nil
    }
    
    /// Content items to show.
    var contentItems: ContentLibrary = []
    var footerActivityIndicator = UIActivityIndicatorView(style: .gray)
    
    var currentPage: Int = 1
    var loadingMoreContent: Bool = false
    
    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        addBehaviors([
            LeftBarButtonBehavior(showing: .menuOrBack)
        ])
        
        self.tableview.tableFooterView = UIView(frame: CGRect.zero)
        displayProgressFooterView()
        self.activityIndicator.startAnimating()
        self.emptyStateLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = baseContentItem == nil ? .always : .never
        
        if baseContentItem == nil && contentItems.isEmpty {
            title = "Content Library"
            
            self.loadingMoreContent = true
            activityIndicator.startAnimating()
            
            firstly {
                ContentLibrary.getRootDirectory(page: currentPage)
            }.then { (library) in
                if !library.isEmpty {
                    self.currentPage = self.currentPage + 1
                    self.contentItems = self.contentItems + library
                    self.tableview.reloadData()
                    self.tableview.reloadSections([0], with: .automatic)
                }
                
                self.emptyStateLabel.text = "There are no content items to display"
                self.emptyStateLabel.isHidden = self.contentItems.isEmpty ? false : true
            }.catch { (error) in
                let alert = UIAlertController.dismissable(title: "Error", message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
            }.always {
                self.loadingMoreContent = false
                self.activityIndicator.stopAnimating()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass content item down to content viewer (web view).
        if segue.identifier == "PushContentDetailController" {
            guard let vc = segue.destination as? ContentDetailController else { return }
            guard let indexPath = tableview.indexPathForSelectedRow else { return }
            vc.contentItem = contentItems[(indexPath as NSIndexPath).row]
        }
    }
    
    func displayProgressFooterView() {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableview.frame.width, height: 44))
        footerActivityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        footerActivityIndicator.center = headerView.center
        headerView.addSubview(footerActivityIndicator)
        footerActivityIndicator.bringSubviewToFront(headerView)
        footerActivityIndicator.startAnimating()
        footerActivityIndicator.alpha = 0
        headerView.backgroundColor = UIColor.white
        tableview.tableFooterView = headerView
        tableview.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -headerView.frame.height, right: 0)
    }
}

// MARK: UITableViewDelegate
extension ContentLibraryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContentLibraryCell", for: indexPath) as! ContentLibraryCell

        let item = contentItems[(indexPath as NSIndexPath).row]
        
        cell.filetype = item.type
        
        cell.nameLabel.text = item.name
            
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        cell.modifiedLabel.text = item.modified.flatMap({ formatter.string(from: $0) }).map({ "Modified \($0)" })
        
        return cell
    }
    
    func loadMoreContent() {
        if topLevel {
            self.loadingMoreContent = true
            activityIndicator.startAnimating()
            
            firstly {
                ContentLibrary.getRootDirectory(page: currentPage)
            }.then { (library) in
                if !library.isEmpty {
                    self.currentPage = self.currentPage + 1
                    self.contentItems = self.contentItems + library
                    self.tableview.reloadData()
                    self.tableview.reloadSections([0], with: .automatic)
                }
                
                self.emptyStateLabel.text = "There are no content items to display"
                self.emptyStateLabel.isHidden = self.contentItems.isEmpty ? false : true
            }.catch { (error) in
                let alert = UIAlertController.dismissable(title: "Error", message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
            }.always {
                self.loadingMoreContent = false
                self.activityIndicator.stopAnimating()
            }
        }
    }
}

extension ContentLibraryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = contentItems[(indexPath as NSIndexPath).row]
        
        if item.type == .directory {
            // Push a new folder browser.
            let controller = UIStoryboard(name: "ContentLibrary", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ContentLibraryViewController") as! ContentLibraryViewController
            controller.baseContentItem = item
            navigationController?.pushViewController(controller, animated: true)
        } else {
            // Push content browser.
            let controller = UIStoryboard(name: "ContentLibrary", bundle: Constants.bundle).instantiateViewController(withIdentifier: "ContentDetailController") as! ContentDetailController
            controller.contentItem = item
            navigationController?.pushViewController(controller, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension ContentLibraryViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height {
            if !loadingMoreContent {
                footerActivityIndicator.alpha = 1
                loadingMoreContent = true
                loadMoreContent()
            }
        }
    }
}
