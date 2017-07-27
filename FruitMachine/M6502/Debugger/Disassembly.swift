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
    
    func getAddressString() -> String {
        return String(format: "%04X", address)
    }
    
    func getInstructionString() -> String {
        switch(instruction!.addressingMode) {
        case .accumulator:
            return String(format: "%@ A", instruction!.mnemonic)
        case .immediate:
            return String(format: "%@ #$%02X", instruction!.mnemonic, data[1])
        case .implied:
            return String(format: "%@", instruction!.mnemonic)
        case .relative:
            var destination: UInt16 = address
            if((data[1] & 0x80) == 0x80) {
                destination = destination + 1 - UInt16(~data[1])
            } else {
                destination = destination + 2 + UInt16(data[1])
            }
            return String(format: "%@ #$%04X", instruction!.mnemonic, destination)
        case .absolute:
            return String(format: "%@ $%02X%02X", instruction!.mnemonic, data[2], data[1])
        case .zeropage:
            return String(format: "%@ $%02X", instruction!.mnemonic, data[1])
        case .indirect:
            return String(format: "%@ ($%02X%02X)", instruction!.mnemonic, data[2], data[1])
        case .absolute_indexed_x:
            return String(format: "%@ $%02X%02X,X", instruction!.mnemonic, data[2], data[1])
        case .absolute_indexed_y:
            return String(format: "%@ $%02X%02X,Y", instruction!.mnemonic, data[2], data[1])
        case .zeropage_indexed_x:
            return String(format: "%@ $%02X,X", instruction!.mnemonic, data[1])
        case .zeropage_indexed_y:
            return String(format: "%@ $%02X,Y", instruction!.mnemonic, data[1])
        case .indexed_indirect:
            return String(format: "%@ ($%02X,X)", instruction!.mnemonic, data[1])
        case .indirect_indexed:
            return String(format: "%@ ($%02X),Y", instruction!.mnemonic, data[1])
        }
    }
    
    func getDataString() -> String {
        var dataStr = ""
        for byte in data {
            dataStr += String(format: "%02X ", byte)
        }
        return dataStr
    }
}

extension CPU {
    func disassemble(fromAddress: UInt16, length: UInt16) -> [Disassembly] {
        var disassembly: [Disassembly] = [Disassembly]()
        
        var currentAddress: UInt16 = fromAddress
        let endAddress: UInt16 = max(fromAddress &+ length, 0xFFFF)
        
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
