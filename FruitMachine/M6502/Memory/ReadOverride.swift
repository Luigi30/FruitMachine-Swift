//
//  ReadOverride.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

/* A ReadOverride is special behavior that occurs when a memory address is read.
   Memory-mapped registers, peripherals, etc. */

final class ReadOverride: MemoryOverride {
    let doRead: Bool //do we write anyway?
    
    init(start: UInt16, end: UInt16, readAnyway: Bool, action: @escaping (AnyObject, UInt8?) -> UInt8?) {
        doRead = readAnyway
        super.init(start: start, end: end, action: action)
    }
}
