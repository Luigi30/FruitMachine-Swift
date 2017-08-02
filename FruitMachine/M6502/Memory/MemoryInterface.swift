//
//  MemoryInterface.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/20/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

final class MemoryInterface: NSObject {
    enum pageMode {
        case ro
        case rw
        case null
    }
    
    
    fileprivate var memory: [UInt8]
    
    var read_overrides: [ReadOverride]
    var write_overrides: [WriteOverride]
    
    var pages: [pageMode] = [pageMode](repeating: .null, count: 256)
    
    override init() {
        memory = [UInt8](repeating: 0x00, count: 65536)
        read_overrides = [ReadOverride]()
        write_overrides = [WriteOverride]()
    }
    
    func getPage(offset: UInt16) -> UInt8 {
        return UInt8(offset >> 8)
    }
    
    func readByte(offset: UInt16, bypassOverrides: Bool = false) -> UInt8 {
        if(!bypassOverrides) {
            for override in read_overrides {
                if case override.rangeStart ... override.rangeEnd = offset {
                    let readValue = override.action(CPU.sharedInstance, nil)
                    if(!override.doRead) {
                        return readValue!
                    }
                }
            }
        }
        
        //If no override, check if there's memory here.
        if(pages[Int(getPage(offset: offset))] == pageMode.null) {
            return 0x00
        }
        
        //No match.
        return memory[Int(offset)]
    }
    
    func writeByte(offset: UInt16, value: UInt8, bypassOverrides: Bool = false) {
        
        if(!bypassOverrides) {
            for override in write_overrides {
                if case override.rangeStart ... override.rangeEnd = offset {
                    _ = override.action(CPU.sharedInstance, value)
                    if(!override.doWrite) {
                        return
                    }
                }
            }
        }
        
        //If no override, check if there's memory here to write.
        if(pages[Int(getPage(offset: offset))] != pageMode.rw) {
            return
        }
        
        memory[Int(offset)] = value
    }
    
    func readWord(offset: UInt16) -> UInt16 {
        let low: UInt8 = memory[Int(offset)]
        let high: UInt8 = memory[Int(offset+1)]
        return (UInt16(high) << 8) | UInt16(low)
    }
    
    func loadBinary(path: String, offset: UInt16, length: Int) {
        do {
            let fileContent: NSData = try NSData(contentsOfFile: path)
            fileContent.getBytes(&memory[Int(offset)], range: NSRange(location: 0, length: length))
        } catch {
            print(error)
        }
    }
}
