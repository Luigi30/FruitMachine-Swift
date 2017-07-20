//
//  MemoryInterface.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class MemoryInterface: NSObject {
    var memory: [UInt8]
    
    override init() {
        memory = [UInt8](repeating: 0x00, count: 65536)
    }
}
