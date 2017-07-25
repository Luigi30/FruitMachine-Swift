//
//  IntegerExtensions.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension UInt16 {
    static func + (left: UInt16, right: UInt8) -> UInt16 {
        return left + UInt16(right)
    }
    
    func asHexString() -> String {
        return String(format: "%04X", self)
    }
}
