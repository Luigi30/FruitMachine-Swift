//
//  MemoryOverride.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class MemoryOverride: NSObject {
    let rangeStart: UInt16
    let rangeEnd: UInt16
    let writeValue: Bool
    
    let action: (CPU, UInt8?) -> Void 
    
    init(start: UInt16, end: UInt16, writeValue: Bool, action: @escaping (AnyObject, UInt8?) -> Void) {
        rangeStart = start
        rangeEnd = end
        self.writeValue = writeValue
        
        self.action = action
    }
}
