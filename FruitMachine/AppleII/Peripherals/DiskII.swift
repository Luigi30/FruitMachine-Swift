//
//  DiskII.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class DiskII: NSObject, Peripheral {
    let slotNumber: Int
    let romManager: ROMManager
    var readMemoryOverride: ReadOverride? = nil
    var writeMemoryOverride: WriteOverride? = nil
    
    init(slot: Int, romPath: String) {
        slotNumber = slot
        romManager = ROMManager(path: romPath, atAddress: 0x0, size: 256)
        
        super.init()
        
        readMemoryOverride = ReadOverride(start: UInt16(0xC000 + (0x100 * slotNumber)),
                                    end: UInt16(0xC0FF + (0x100 * slotNumber)),
                                    readAnyway: false,
                                    action: actionReadMemory)
    }
    
    func actionReadMemory(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
        let offset: UInt16 = 0xC000 + UInt16(slotNumber*0x100)
        let local = address - offset
        
        return getMemoryMappedByte(address: local)
    }
    
    private func getMemoryMappedByte(address: UInt16) -> UInt8 {
        //Disk II just maps its ROM to the memory addressed by the slot.
        
        return romManager.ROM[Int(address)]
    }
    
    func installOverrides() {
        CPU.sharedInstance.memoryInterface.read_overrides.append(readMemoryOverride!)
    }
}
