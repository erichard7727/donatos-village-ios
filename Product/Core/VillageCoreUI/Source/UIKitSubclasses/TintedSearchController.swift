//
//  TintedSearchController.swift
//  VillageCoreUI
//
//  Created by Rob Feldmann on 5/11/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import UIKit

class TintedSearchController: UISearchController {
    override var searchBar: UISearchBar {
        if _searchBar == nil {
            let searchBar = TintedSearchBar()
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            searchBar.searchBarStyle = .minimal
            searchBar.barStyle = .default
            searchBar.isTranslucent = true
            searchBar.barTintColor = navigationController?.navigationBar.barTintColor ?? UINavigationBar.appearance().barTintColor
            searchBar.tintColor = UISearchBar.appearance().tintColor
            _searchBar = searchBar
        }
        return _searchBar!
    }
    private var _searchBar: UISearchBar?
}
