//
//  Overrides.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleI {

    class PIAOverrides: NSObject {
        static let writeDSP = WriteOverride(start: 0xD012, end: 0xD012, writeAnyway: false, action: PIAOverrides.actionWriteDSP)
        static func actionWriteDSP(terminal: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {

            let pia = AppleI.sharedInstance.pia["display"]!
            
            if(pia.getMode() == .Output) {
                //Writing to DSP sets DSP.7
                AppleI.sharedInstance.pia["display"]!.data = byte! | 0x80
                
                //Output our character to the terminal
                AppleI.sharedInstance.terminal.putCharacter(charIndex: byte!)
                
                AppleI.sharedInstance.pia["display"]!.data = byte! & ~(0x80)
            }
            return nil
        }
        
        static let writeDSPCR = WriteOverride(start: 0xD013, end: 0xD013, writeAnyway: false, action: PIAOverrides.actionWriteDSPCR)
        static func actionWriteDSPCR(terminal: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            AppleI.sharedInstance.pia["display"]?.control = byte!
            return nil
        }
        
        static let readDSP = ReadOverride(start: 0xD012, end: 0xD012, readAnyway: false, action: PIAOverrides.actionReadDSP)
        static func actionReadDSP(terminal: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            
            //DSP.7 is unset when the character is accepted by the terminal
            return AppleI.sharedInstance.pia["display"]!.data
        }
        /* */
        
        static let readKBDCR = ReadOverride(start: 0xD011, end: 0xD011, readAnyway: false, action: PIAOverrides.actionReadKBDCR)
        static func actionReadKBDCR(terminal: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            return AppleI.sharedInstance.pia["keyboard"]!.control
        }
        
        /* */
        static let readKBD = ReadOverride(start: 0xD010, end: 0xD010, readAnyway: false, action: PIAOverrides.actionReadKBD)
        static func actionReadKBD(terminal: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            //Reading KBD clears KBDCR.7
            AppleI.sharedInstance.pia["keyboard"]!.control = AppleI.sharedInstance.pia["keyboard"]!.control & ~(0x80)
            
            //KBD.7 is tied to +5V
            return AppleI.sharedInstance.pia["keyboard"]!.data | 0x80
        }
        
    }

}
