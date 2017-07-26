//
//  MemoryInterface.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class MemoryInterface: NSObject {
    
    fileprivate var memory: [UInt8]
    
    var read_overrides: [ReadOverride]
    var write_overrides: [WriteOverride]
    
    override init() {
        memory = [UInt8](repeating: 0x00, count: 65536)
        read_overrides = [ReadOverride]()
        write_overrides = [WriteOverride]()
    }
    
    func readByte(offset: UInt16) -> UInt8 {
        for override in read_overrides {
            if case override.rangeStart ... override.rangeEnd = offset {
                override.action(CPU.sharedInstance, nil)
            }
        }
        
        //No match.
        return memory[Int(offset)]
    }
    
    func writeByte(offset: UInt16, value: UInt8) {
        for override in read_overrides {
            if case override.rangeStart ... override.rangeEnd = offset {
                override.action(CPU.sharedInstance, value)
            }
        }
        
        memory[Int(offset)] = value
    }
    
    func readWord(offset: UInt16) -> UInt16 {
        let low: UInt8 = memory[Int(offset)]
        let high: UInt8 = memory[Int(offset+1)]
        return (UInt16(high) << 8) | UInt16(low)
    }
    
    func loadBinary(path: String) {
        do {
            let fileContent: NSData = try NSData(contentsOfFile: path)
            fileContent.getBytes(&memory, range: NSRange(location: 0, length: 65536))
        } catch {
            print(error)
        }
    }
}
