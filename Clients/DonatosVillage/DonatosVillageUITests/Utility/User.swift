//
//  User.swift
//  DonatosVillageUITests
//
//  Created by Grayson Hansard on 6/30/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import Foundation

public enum User {
	case Admin
	
	public var email: String {
		switch self {
		case .Admin:
			return "admin@village.com"
		}
	}
	
	public var password: String {
		switch self {
		case .Admin:
			return "<look this up in LastPass and don't commit it here!>"
		}
	}
}
