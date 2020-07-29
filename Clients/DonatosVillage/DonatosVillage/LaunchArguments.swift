//
//  LaunchArguments.swift
//  DonatosVillage
//
//  Created by Grayson Hansard on 6/29/20.
//  Copyright © 2020 Donatos. All rights reserved.
//

import Foundation

public class LaunchArguments {
	public enum Key: String {
		case isUITesting = "PeppTalkIsUITesting"
	}
	
	public lazy var isUITesting: Bool = { UserDefaults().bool(forKey: Key.isUITesting.rawValue ) }()
	
}
