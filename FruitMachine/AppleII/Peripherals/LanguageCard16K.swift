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
    
    /* Off: $D000-$DFFF -> RAM bank 2. On: $D000-$DFFF -> RAM bank 1 */
    var LCBNK: Bool = false
    
    /* Off: Reads of $D000-$FFFF -> ROM. On: Reads of $D000-$FFFF -> RAM */
    var LCRAM: Bool = false
    
    /* Off: Writes of $D000-$FFFF do nothing. On: Writes of $D000-$FFFF -> RAM */
    var LCWRITE: Bool = false
    
    var lastReadSwitch: UInt8 = 0x00
    
    //16KB of RAM on the Language Card.
    var ram = [UInt8](repeating: 0xCC, count: 16384)
    
    var readIOOverride: ReadOverride? = nil
    var writeIOOverride: WriteOverride? = nil
    
    var RDLCBNKOverride: ReadOverride? = nil
    var RDLCRAMOverride: ReadOverride? = nil

    var readLanguageCardAddressingOverride: ReadOverride? = nil
    var writeLanguageCardAddressingOverride: WriteOverride? = nil
    
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
        
        RDLCBNKOverride = ReadOverride(start: UInt16(0xC011 + (0x10 * slotNumber)),
                                        end: UInt16(0xC011 + (0x10 * slotNumber)),
                                        readAnyway: false,
                                        action: actionRDLCBNK)

        RDLCRAMOverride = ReadOverride(start: UInt16(0xC012 + (0x10 * slotNumber)),
                                       end: UInt16(0xC012 + (0x10 * slotNumber)),
                                       readAnyway: false,
                                       action: actionRDLCRAM)
        
        readIOOverride = ReadOverride(start: UInt16(0xC080 + (0x10 * slotNumber)),
                                      end: UInt16(0xC08F + (0x10 * slotNumber)),
                                      readAnyway: false,
                                      action: actionDispatchOperation)
        
        writeIOOverride = WriteOverride(start: UInt16(0xC080 + (0x10 * slotNumber)),
                                      end: UInt16(0xC08F + (0x10 * slotNumber)),
                                      writeAnyway: false,
                                      action: actionDispatchOperation)
        
        readLanguageCardAddressingOverride = ReadOverride(start: UInt16(0xD000),
                                                          end: UInt16(0xFFFF),
                                                          readAnyway: false,
                                                          action: actionReadLanguageCard)
        
        writeLanguageCardAddressingOverride = WriteOverride(start: UInt16(0xD000),
                                                            end: UInt16(0xFFFF),
                                                            writeAnyway: false,
                                                            action: actionWriteLanguageCard)

        CPU.sharedInstance.memoryInterface.read_overrides.append(RDLCBNKOverride!)
        CPU.sharedInstance.memoryInterface.read_overrides.append(RDLCRAMOverride!)
        CPU.sharedInstance.memoryInterface.read_overrides.append(readIOOverride!)
        CPU.sharedInstance.memoryInterface.write_overrides.append(writeIOOverride!)
        CPU.sharedInstance.memoryInterface.read_overrides.append(readLanguageCardAddressingOverride!)
        CPU.sharedInstance.memoryInterface.write_overrides.append(writeLanguageCardAddressingOverride!)
    }
    
    private func actionRDLCBNK(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        return (LCBNK ? 0x80 : 0x00)
    }
    
    private func actionRDLCRAM(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        return (LCRAM ? 0x80 : 0x00)
    }
    
    private func actionReadLanguageCard(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        /* Redirect reads according to the language card switches. */
        if(address >= 0xE000) {
            if(LCRAM) {
                /* Map to language card RAM. */
                return ram[Int(address - UInt16(0xC000))]
            } else {
                /* Map $E000-$FFFF to ROM. */
                return CPU.sharedInstance.memoryInterface.readByte(offset: address, bypassOverrides: true)
            }
        }
        else {
            if(LCRAM && LCBNK) {
                /* Bank 1 */
                return ram[Int(address - UInt16(0xD000))]
            } else if(LCRAM && !LCBNK) {
                /* Bank 2 */
                return ram[Int(address - UInt16(0xC000))]
            } else {
                return CPU.sharedInstance.memoryInterface.readByte(offset: address, bypassOverrides: true)
            }
        }
    }
    
    private func actionWriteLanguageCard(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        if(LCWRITE) {
            if(address <= 0xDFFF) {
                if(LCBNK) {
                    /* Bank 1 */
                    ram[Int(address - UInt16(0xD000))] = byte!
                }
                else {
                    /* Bank 2 */
                    ram[Int(address - UInt16(0xC000))] = byte!
                }
            } else {
            /* High 8K is written. */
            ram[Int(address - UInt16(0xC000))] = byte!
            }
        }

        return nil
    }
    
    private func actionDispatchOperation(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        let operationNumber = UInt8(address & 0xFF) - UInt8(0x80 & 0xFF) - UInt8(0x10 * slotNumber)
        var isRead = false
        if(byte == nil) {
            isRead = true
        }

        switch operationNumber {
        case 0:
            LCRAM = true
            LCBNK = false
            LCWRITE = false
        case 1:
            LCRAM = false
            LCBNK = false
            if(lastReadSwitch == 0x01) {
                LCWRITE = true
            }
        case 2:
            LCRAM = false
            LCBNK = false
            LCWRITE = false
        case 3:
            LCRAM = true
            LCBNK = false
            if(lastReadSwitch == 0x03) {
                LCWRITE = true
            }
        case 4:
            LCRAM = true
            LCBNK = false
            LCWRITE = false
        case 5:
            LCRAM = false
            LCBNK = true
            if(lastReadSwitch == 0x05) {
                LCWRITE = true
            }
        case 6:
            LCRAM = false
            LCBNK = false
            LCWRITE = false
        case 7:
            LCRAM = true
            LCBNK = false
            if(lastReadSwitch == 0x07) {
                LCWRITE = true
            }
        case 8:
            LCRAM = true
            LCBNK = true
            LCWRITE = false
        case 9:
            LCRAM = false
            LCBNK = true
            if(lastReadSwitch == 0x09) {
                LCWRITE = true
            }
        case 0xA:
            LCRAM = false
            LCBNK = true
            LCWRITE = false
        case 0xB:
            LCRAM = true
            LCBNK = true
            if(lastReadSwitch == 0x0B) {
                LCWRITE = true
            }
        case 0xC:
            LCRAM = true
            LCBNK = true
            LCWRITE = false
        case 0xD:
            LCRAM = false
            LCBNK = true
            if(lastReadSwitch == 0x0D) {
                LCWRITE = true
            }
        case 0xE:
            LCRAM = false
            LCBNK = true
            LCWRITE = false
        case 0xF:
            LCRAM = true
            LCBNK = true
            if(lastReadSwitch == 0x0F) {
                LCWRITE = true
            }
        default:
            print("shouldn't happen")
        }
        
        lastReadSwitch = operationNumber
        
        //print("Language Card command: \(isRead == false ? "Read" : "Write") $\(operationNumber.asHexString()). LCRAM \(LCRAM) LCBNK \(LCBNK) LCWRITE \(LCWRITE)")
        print("LC: offset \(operationNumber.asHexString()) | new state \(LCRAM ? "R" : "x")\(LCWRITE ? "W" : "x") dxxx=\(LCBNK ? "0000" : "1000")")
        
        return 0x00
    }
    
}
