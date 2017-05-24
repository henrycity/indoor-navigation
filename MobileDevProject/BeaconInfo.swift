//
//  BeaconInfoClass.swift
//  MobileDevProject
//
//  Created by Leendert Eloff on 10-05-17.
//  Copyright © 2017 Alexander van den Herik. All rights reserved.
//

import Foundation
import UIKit

class BeaconInfo{
    
    var value: NSNumber
    var button: UIButton
    var coordinate: CGPoint
    
    init(value: NSNumber, button: UIButton, coordinate: CGPoint) {
        self.value = value
        self.button = button
        self.coordinate = coordinate
    }
}
