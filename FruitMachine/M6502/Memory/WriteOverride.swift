//
//  WriteOverride.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

/* A ReadOverride is special behavior that occurs when a memory address is written.
 Memory-mapped registers, peripherals, etc. */

class WriteOverride: MemoryOverride {
    let doWrite: Bool //do we write anyway?
    
    init(start: UInt16, end: UInt16, writeAnyway: Bool, action: @escaping (AnyObject, UInt8?) -> UInt8?) {
        doWrite = writeAnyway
        super.init(start: start, end: end, action: action)
    }
}
