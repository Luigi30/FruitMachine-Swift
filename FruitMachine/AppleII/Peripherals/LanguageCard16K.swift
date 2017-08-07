//
//  LanguageCard16K.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/6/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class LanguageCard16K: NSObject, Peripheral, HasROM {
    var slotNumber: Int
    var romManager: ROMManager
    
    //16KB of RAM on the Language Card.
    var ram = [UInt8](repeating: 0xCC, count: 16384)
    
    var readIOOverride: ReadOverride? = nil
    var writeIOOverride: WriteOverride? = nil
    
    func installOverrides() {
        func installOverrides() {
            CPU.sharedInstance.memoryInterface.read_overrides.append(readIOOverride!)
            CPU.sharedInstance.memoryInterface.write_overrides.append(writeIOOverride!)
        }
    }
    
    init(slot: Int, romPath: String) {
        slotNumber = slot
        romManager = ROMManager(path: romPath, atAddress: 0x0, size: 2048)
        
        super.init()
        
        readIOOverride = ReadOverride(start: UInt16(0xC080 + (0x10 * slotNumber)),
                                      end: UInt16(0xC08F + (0x10 * slotNumber)),
                                      readAnyway: false,
                                      action: actionDispatchOperation)
        
        writeIOOverride = WriteOverride(start: UInt16(0xC080 + (0x10 * slotNumber)),
                                        end: UInt16(0xC08F + (0x10 * slotNumber)),
                                        writeAnyway: false,
                                        action: actionDispatchOperation)
    }
    
    private func actionDispatchOperation(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        let operationNumber = UInt8(address & 0xFF) - UInt8(0x80 & 0xFF) - UInt8(0x10 * slotNumber)
        var isRead = false
        if(byte == nil) {
            isRead = true
        }
        
        print("Language Card command: \(isRead == false ? "Read" : "Write") $\(operationNumber.asHexString())")
        
        return 0x00
    }
    
    
    
}
