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

extension CPU {
    func disassemble(fromAddress: UInt16, length: UInt16) -> [Disassembly] {
        var disassembly: [Disassembly] = [Disassembly]()
        
        var currentAddress: UInt16 = fromAddress
        let endAddress: UInt16 = fromAddress + length
        
        while(currentAddress < endAddress) {
            let instruction = memoryInterface.readByte(offset: currentAddress)
            let operation = InstructionTable[instruction]
            var data = [UInt8]()
            
            if(operation != nil) {
                for index in 1...operation!.bytes {
                    data.append(memoryInterface.readByte(offset:currentAddress + UInt16(index-1)))
                }
                
                disassembly.append(Disassembly(instruction: operation, address: currentAddress, data: data))
                currentAddress = currentAddress + UInt16(operation!.bytes)
            } else {
                currentAddress = currentAddress + 1
            }
        }
        
        return disassembly
    }
}
