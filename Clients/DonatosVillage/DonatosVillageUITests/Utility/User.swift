//
//  User.swift
//  DonatosVillageUITests
//
//  Created by Grayson Hansard on 6/30/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import Foundation

public enum User {
	case automationStoreAssociation
	
	public var email: String {
		switch self {
		case .automationStoreAssociation:
			return "support+testautomation2@willowtreeapps.com"
		}
	}
	
	public var password: String {
		switch self {
		case .automationStoreAssociation:
			return "8ZNA9G5@d1vH"
		}
	}
}
