//
//  Disassembly.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/22/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class Disassembly: NSObject {
    let instruction: CPUInstruction?
    let address: UInt16
    let data: [UInt8]
    
    init(instruction: CPUInstruction?, address: UInt16, data: [UInt8]) {
        self.instruction = instruction
        self.address = address
        self.data = data
    }
}
