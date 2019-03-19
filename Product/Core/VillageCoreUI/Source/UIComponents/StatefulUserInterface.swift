//
//  StatefulUserInterface.swift
//  VillageCore
//
//  Created by Colin Drake on 11/5/15.
//  Copyright © 2015 Dynamit. All rights reserved.
//

import UIKit

/// A user interface object that contains state and displays the UI differently for each one.
///
/// This protocol provides a simply implementation of switching out and animating state. For state animations that are more complex than a simple time-based, animation optional change, a custom approach should be used instead. This is a protocol/implementation for "simple" cases.
///
/// Note:
/// - `StateType` will usually be an `enum`.
/// - `setState()` should be the function you call when changing the state.
///
/// NOTICE: Not sure if we're going to end up keeping this metaphor...
protocol StatefulUserInterface: class {
    /// Interface state type.
    associatedtype StateType
    
    /// Current state of the user interface.
    var interfaceState: StateType { get set }
    
    /**
     Updates the user interface for the given state.
     
     Note: this method will always be called on the main queue and can potentially be wrapped in an animation block.
     
     - parameter state: the state to change to.
     - parameter previousState: the prior value of the interface state.
     */
    func updateUserInterfaceForState(_ state: StateType, previousState: StateType)
}

extension StatefulUserInterface {
    /**
     Updates the user interface state.
     
     - parameter state: the new state to change to.
     - parameter animated: whether or not to wrap the change in an animation block. Defaults to `false`.
     - parameter animationDuration: the amount of time to animate in, if `animated` is `true`. Defaults to `0.3`.
     */
    /* mutating */ func setState(_ state: StateType, animated: Bool = false, animationDuration: TimeInterval = 0.3, options: UIView.AnimationOptions = []) {
        let oldValue = interfaceState
        interfaceState = state
        
        PerformAnimatedInMainContext(animated, duration: animationDuration, options: options) {
            self.updateUserInterfaceForState(self.interfaceState, previousState: oldValue)
        }
    }
    
    func PerformAnimatedInMainContext(_ animated: Bool = true, duration: TimeInterval = 0.3, options: UIView.AnimationOptions = [], block: @escaping () -> ()) {
        DispatchQueue.main.async {
            if (animated) {
                UIView.animate(withDuration: duration, delay: 0.0, options: options,
                               animations: block, completion: nil)
            } else {
                block()
            }
        }
    }
}
