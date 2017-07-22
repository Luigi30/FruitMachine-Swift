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
    
    override init() {
        memory = [UInt8](repeating: 0x00, count: 65536)
    }
    
    func readByte(offset: UInt16) -> UInt8 {
        return memory[Int(offset)]
    }
    
    func writeByte(offset: UInt16, value: UInt8) {
        memory[Int(offset)] = value
    }
    
    func readWord(offset: UInt16) -> UInt16 {
        return UInt16(memory[Int(offset)] | (memory[Int(offset+1)] << 8))
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
