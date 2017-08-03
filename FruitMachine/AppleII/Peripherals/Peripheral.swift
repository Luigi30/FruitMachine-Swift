//
//  Peripheral.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

protocol Peripheral {
    var slotNumber: Int { get }
    func installOverrides()
}
