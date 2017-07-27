//
//  Conversions.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/23/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AddressConversions: NSObject {
    static func zeroPageAsUInt16(address: UInt8) -> UInt16 {
        return 0x0000 | UInt16(address)
    }
}
