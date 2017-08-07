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

class DiskII: NSObject, Peripheral, HasROM {
    let debug = false
    
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
    
    static let N_Drive1TrackChanged  = NSNotification.Name(rawValue: "Drive1TrackChanged")
    static let N_Drive2TrackChanged  = NSNotification.Name(rawValue: "Drive2TrackChanged")
    
    var motor1OffTimer: Timer?
    var motor2OffTimer: Timer?

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
    var mediaPosition: Int = 0
    var motorPhase: MotorPhase = .Phase0
    
    var preloadedByte: UInt8 = 0x00
    
    var diskImage: DiskImage?
    
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
    
    func attachDiskImage(imagePath: String) {
        diskImage = DiskImage(diskPath: imagePath)
    }
    
    //http://ftp.twaren.net/NetBSD/misc/wrstuden/Apple_PDFs/Software%20control%20of%20IWM.pdf
    private func actionDispatchOperation(something: AnyObject, address: UInt16, byte: UInt8?) -> UInt8?
    {
        let operationNumber = UInt8(address & 0xFF) - UInt8(0x80 & 0xFF) - UInt8(0x10 * slotNumber)
        
        if(debug) { print("Disk II command: \(operationNumber)") }
        
        //Update the softswitches.
        switch(operationNumber) {
        case 0:
            softswitches.Phase0 = false
        case 1:
            softswitches.Phase0 = true
            if(motorPhase == .Phase1) {
                motorPhase = .Phase0
                if(currentTrack % 2 == 0 && currentTrack > 0)
                {
                    currentTrack -= 1
                }
                if(debug) { print("Drive now on track \(currentTrack)") }
                //updateCurrentTrackDisplay(drive: softswitches.DriveSelect)
            } else if(motorPhase == .Phase3) {
                motorPhase = .Phase0
                if(currentTrack % 2 == 1 && currentTrack < 34) {
                    currentTrack += 1
                }
                if(debug) { print("Drive now on track \(currentTrack)") }
                //updateCurrentTrackDisplay(drive: softswitches.DriveSelect)
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
                if(currentTrack % 2 == 1 && currentTrack > 0) {
                    currentTrack -= 1
                }
                if(debug) { print("Drive now on track \(currentTrack)") }
                //updateCurrentTrackDisplay(drive: softswitches.DriveSelect)
            } else if(motorPhase == .Phase1) {
                motorPhase = .Phase2
                if(currentTrack % 2 == 0 && currentTrack < 34) {
                    currentTrack += 1;
                }
                if(debug) { print("Drive now on track \(currentTrack)") }
                //updateCurrentTrackDisplay(drive: softswitches.DriveSelect)
            }
        case 6:
            softswitches.Phase3 = false
        case 7:
            softswitches.Phase3 = true
            if(motorPhase == .Phase0 || motorPhase == .Phase2) {
                motorPhase = .Phase3
            }
        case 8:
            //softswitches.MotorPowered = false
            if(softswitches.DriveSelect == false) {
                NotificationCenter.default.post(name: DiskII.N_Drive1MotorOff, object: nil)
                motor1OffTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                           target: self,
                                                           selector: #selector(disableDrive1Motor),
                                                           userInfo: nil,
                                                           repeats: false)
                if(debug) { print("Drive 1 Motor will turn off in 1 second") }
            } else {
                NotificationCenter.default.post(name: DiskII.N_Drive2MotorOff, object: nil)
                motor2OffTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(disableDrive2Motor),
                                     userInfo: nil,
                                     repeats: false)
                if(debug) { print("Drive 2 Motor will turn off in 1 second") }
            }
        case 9:
            softswitches.MotorPowered = true
            if(softswitches.DriveSelect == false) {
                NotificationCenter.default.post(name: DiskII.N_Drive1MotorOn, object: nil)
                motor1OffTimer?.invalidate()
                if(debug) { print("Drive 1 Motor is on") }
            } else {
                NotificationCenter.default.post(name: DiskII.N_Drive2MotorOn, object: nil)
                motor1OffTimer?.invalidate()
                if(debug) { print("Drive 2 Motor is on") }
            }
        case 10:
            softswitches.DriveSelect = false
            if(debug) { print("Drive 1 selected") }
        case 11:
            softswitches.DriveSelect = true
            if(debug) { print("Drive 2 selected") }
        case 12:
            softswitches.Q6 = false
            let trk = CPU.sharedInstance.memoryInterface.readByte(offset: 0xB7EC, bypassOverrides: true)
            let sec = CPU.sharedInstance.memoryInterface.readByte(offset: 0xB7ED, bypassOverrides: true)
            let mode = CPU.sharedInstance.memoryInterface.readByte(offset: 0xB7F4, bypassOverrides: true)
            if(trk == 2 && sec == 4 && mode == 1)
            {
                _ = 1
            }
            let modeString: String
            switch (mode) {
            case 0:
                modeString = "seeking"
            case 1:
                modeString = "reading"
            case 2:
                modeString = "writing"
            case 4:
                modeString = "formatting"
            default:
                modeString = "???"
            }
            if(debug) { print("Head is at nibble \(mediaPosition) of track \(currentTrack). DOS is \(modeString) T\(trk) S\(sec).") }
            updateCurrentTrackSectorDisplay(drive: softswitches.DriveSelect, track: currentTrack, sector: Int(sec))
            
            if(softswitches.Q7 == false && byte == nil) {
                //in read mode and a read was requested. get the next nibble
                return readByteOfTrack(track: currentTrack, advance: softswitches.MotorPowered ? 1 : 0)
            }
            if(softswitches.Q7 == true && byte == nil) {
                //in write mode
                writeNibbleOfTrack(track: currentTrack, advance: softswitches.MotorPowered ? 1 : 0, nibble: preloadedByte)
                return 0x00
            }
            
            if(debug) { print("Disk II: Operation failed!") }
            
        case 13:
            //WRITE PROTECT SENSE MODE
            softswitches.Q6 = true
        case 14:
            if(debug) { print("Disk II: READ STATUS REGISTER") }
            softswitches.Q7 = false
            return 0x00 | (diskImage!.writeProtect ? 0x80 : 0x00) | (softswitches.MotorPowered ? 0x20 : 0x00)
        case 15:
            softswitches.Q7 = true
            
            //STA $C
            if(softswitches.Q6 == true && byte != nil) {
                preloadedByte = byte!
                if(debug) { print("WRITE LOAD: shift register contains \(preloadedByte.asHexString())") }
            }
            
        default:
            if(debug) { print("Unknown command? This can't happen.") }
        }
        
        return 0x00
    }
    
    func readByteOfTrack(track: Int, advance: Int) -> UInt8 {
        if(diskImage == nil) { return 0x00 } //No disk inserted, fail.
        
        let trackData = diskImage?.encodedTracks[track]
        if(trackData == nil) { return 0x00 } //No disk inserted, fail.
        
        let result = trackData![mediaPosition]
        //Advance the drive to the next byte
        mediaPosition = (mediaPosition + advance) % trackData!.count
        
        return result
    }
    
    func writeNibbleOfTrack(track: Int, advance: Int, nibble: UInt8) {
        if(diskImage == nil) { return} //No disk inserted, fail.
        
        let trackData = diskImage?.encodedTracks[track]
        if(trackData == nil) { return } //No disk inserted, fail.
        
        if(debug) { print("wrote \(nibble.asHexString()) to disk") }
        
        diskImage!.encodedTracks[track][mediaPosition] = nibble
        mediaPosition = (mediaPosition + advance) % trackData!.count
    }
    
    
    func updateCurrentTrackSectorDisplay(drive: Bool, track: Int, sector: Int) {
        if(drive == false) {
            NotificationCenter.default.post(name: DiskII.N_Drive1TrackChanged, object: (currentTrack, sector))
        }
        else {
            NotificationCenter.default.post(name: DiskII.N_Drive2TrackChanged, object: (currentTrack, sector))
        }
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
    
    @objc func disableDrive1Motor() {
        softswitches.MotorPowered = false
        if(debug) { print("Drive 1 Motor is now off") }
    }
    
    @objc func disableDrive2Motor() {
        softswitches.MotorPowered = false
        if(debug) { print("Drive 2 Motor is now off") }
    }
}
