//
//  DiskII.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

/*
 Commands:
 0 = PHASE 0 OFF
 1 = PHASE 0 ON
 2 = PHASE 1 OFF
 3 = PHASE 1 ON
 4 = PHASE 2 OFF
 5 = PHASE 2 ON
 6 = PHASE 3 OFF
 7 = PHASE 3 ON
 8 = TURN MOTOR OFF
 9 = TURN MOTOR ON
 A = SELECT DRIVE 1
 B = SELECT DRIVE 2
 C = Q6 -> L
 D = Q6 -> H
 E = Q7 -> L
 F = Q7 -> H
 
 Q6 Q7
 L  L   READ
 H  L   SENSE WRITE PROTECT OR PREWRITE STATE
 L  H   WRITE
 H  H   WRITE LOAD
 */

class DiskII: NSObject, Peripheral {
    enum MotorPhase {
        case Phase0
        case Phase1
        case Phase2
        case Phase3
    }
    
    /* Notifications */
    static let N_Drive1MotorOn  = NSNotification.Name(rawValue: "Drive1MotorOn")
    static let N_Drive2MotorOn  = NSNotification.Name(rawValue: "Drive2MotorOn")
    static let N_Drive1MotorOff = NSNotification.Name(rawValue: "Drive1MotorOff")
    static let N_Drive2MotorOff = NSNotification.Name(rawValue: "Drive2MotorOff")
    
    /* Softswitches */
    struct Softswitches {
        var Phase0 = false
        var Phase1 = false
        var Phase2 = false
        var Phase3 = false
        var MotorPowered = false
        var DriveSelect = false //false = 1, true = 2
        var Q6 = false
        var Q7 = false
    }
    
    let slotNumber: Int
    let romManager: ROMManager
    var readMemoryOverride: ReadOverride? = nil
    var readIOOverride: ReadOverride? = nil
    var writeIOOverride: WriteOverride? = nil
    var softswitches = Softswitches()
    
    var currentTrack: Int = 0
    var motorPhase: MotorPhase = .Phase0
    
    var diskImage = DiskImage(diskPath: "/Users/luigi/apple2/master.dsk")
    
    init(slot: Int, romPath: String) {
        slotNumber = slot
        romManager = ROMManager(path: romPath, atAddress: 0x0, size: 256)
        
        super.init()
        
        readMemoryOverride = ReadOverride(start: UInt16(0xC000 + (0x100 * slotNumber)),
                                    end: UInt16(0xC0FF + (0x100 * slotNumber)),
                                    readAnyway: false,
                                    action: actionReadMemory)
        
        readIOOverride = ReadOverride(start: UInt16(0xC080 + (0x10 * slotNumber)),
                                      end: UInt16(0xC08F + (0x10 * slotNumber)),
                                      readAnyway: false,
                                      action: actionDispatchOperation)
        
        writeIOOverride = WriteOverride(start: UInt16(0xC080 + (0x10 * slotNumber)),
                                        end: UInt16(0xC08F + (0x10 * slotNumber)),
                                        writeAnyway: false,
                                        action: actionDispatchOperation)
    }
    
    //http://ftp.twaren.net/NetBSD/misc/wrstuden/Apple_PDFs/Software%20control%20of%20IWM.pdf
    private func actionDispatchOperation(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
        let operationNumber = UInt8(address & 0xFF) - UInt8(0x80 & 0xFF) - UInt8(0x10 * slotNumber)
        
        print("Disk II command: \(operationNumber)")
        
        //Update the softswitches.
        switch(operationNumber) {
        case 0:
            softswitches.Phase0 = false
        case 1:
            softswitches.Phase0 = true
            if(motorPhase == .Phase1) {
                motorPhase = .Phase0
                if(currentTrack % 2 == 0) {
                    if(currentTrack >= 0) { currentTrack -= 1 }
                }
            } else if(motorPhase == .Phase3) {
                motorPhase = .Phase0
                if(currentTrack % 2 == 1) {
                    if(currentTrack <= 34) { currentTrack += 1 }
                }
            }
        case 2:
            softswitches.Phase1 = false
        case 3:
            softswitches.Phase1 = true
            if(motorPhase == .Phase0 || motorPhase == .Phase2) {
                motorPhase = .Phase1
            }
        case 4:
            softswitches.Phase2 = false
        case 5:
            softswitches.Phase2 = true
            if(motorPhase == .Phase3) {
                motorPhase = .Phase2
                if(currentTrack % 2 == 0) {
                    if(currentTrack >= 0) { currentTrack -= 1 }
                }
            } else if(motorPhase == .Phase1) {
                motorPhase = .Phase2
                if(currentTrack % 2 == 0) {
                    if(currentTrack <= 34) { currentTrack += 1 }
                }
            }
        case 6:
            softswitches.Phase3 = false
        case 7:
            softswitches.Phase3 = true
            if(motorPhase == .Phase0 || motorPhase == .Phase2) {
                motorPhase = .Phase3
            }
        case 8:
            softswitches.MotorPowered = false
            if(softswitches.DriveSelect == false) {
                NotificationCenter.default.post(name: DiskII.N_Drive1MotorOff, object: nil)
            } else {
                NotificationCenter.default.post(name: DiskII.N_Drive2MotorOff, object: nil)
            }
        case 9:
            softswitches.MotorPowered = true
            if(softswitches.DriveSelect == false) {
                NotificationCenter.default.post(name: DiskII.N_Drive1MotorOn, object: nil)
            } else {
                NotificationCenter.default.post(name: DiskII.N_Drive2MotorOn, object: nil)
            }
        case 10:
            softswitches.DriveSelect = false
        case 11:
            softswitches.DriveSelect = true
        case 12:
            softswitches.Q6 = false
            if(byte == nil) { //read
                //write to Q6L -> read byte
            }
        case 13:
            softswitches.Q6 = true
        case 14:
            softswitches.Q7 = false
        case 15:
            softswitches.Q7 = true
        default:
            print("Unknown command? This can't happen.")
        }
        
        return 0x00
    }
    
    func installOverrides() {
        CPU.sharedInstance.memoryInterface.read_overrides.append(readMemoryOverride!)
        CPU.sharedInstance.memoryInterface.read_overrides.append(readIOOverride!)
        CPU.sharedInstance.memoryInterface.write_overrides.append(writeIOOverride!)
    }
    
    private func actionReadMemory(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
        let offset: UInt16 = 0xC000 + UInt16(slotNumber*0x100)
        let local = address - offset
        
        return getMemoryMappedByte(address: local)
    }
    
    private func getMemoryMappedByte(address: UInt16) -> UInt8 {
        //Disk II just maps its ROM to the memory addressed by the slot.
        
        return romManager.ROM[Int(address)]
    }
}
