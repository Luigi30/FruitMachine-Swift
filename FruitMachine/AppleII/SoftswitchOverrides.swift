//
//  SoftswitchOverrides.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {

    class SoftswitchOverrides: NSObject {
        /* Keyboard port */
        static let readKeyboard = ReadOverride(start: 0xC000, end: 0xC000, readAnyway: false, action: SoftswitchOverrides.actionReadKeyboard)
        static func actionReadKeyboard(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            //let b = CPU.sharedInstance.memoryInterface.readByte(offset: 0xC000, bypassOverrides: true)
            //CPU.sharedInstance.memoryInterface.writeByte(offset: 0xC000, value: b)
            //return b
            return EmulatedSystemInstance!.keyboardController.KEYBOARD
        }
        
        static let clearKeypressStrobeR = ReadOverride(start: 0xC010, end: 0xC010, readAnyway: false, action: SoftswitchOverrides.actionClearKeypressStrobe)
        static let clearKeypressStrobeW = WriteOverride(start: 0xC010, end: 0xC010, writeAnyway: false, action: SoftswitchOverrides.actionClearKeypressStrobe)
        static func actionClearKeypressStrobe(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            //Clears b7 of $C000 on write.
            
            //let b = CPU.sharedInstance.memoryInterface.readByte(offset: 0xC000, bypassOverrides: true)
            //CPU.sharedInstance.memoryInterface.writeByte(offset: 0xC000, value: b & 0x7F, bypassOverrides: true)
            //CPU.sharedInstance.memoryInterface.writeByte(offset: 0xC010, value: b & 0x7F, bypassOverrides: true)

            //return b
            let b = EmulatedSystemInstance!.keyboardController.KEYBOARD
            EmulatedSystemInstance!.keyboardController.KEYBOARD = b & 0x7F
            EmulatedSystemInstance!.keyboardController.STROBE = b & 0x7F
            return b
        }
        
        /* Video settings */
        static let switchC050R = ReadOverride(start: 0xC050, end: 0xC050, readAnyway: false, action: SoftswitchOverrides.actionSwitchC050)
        static let switchC050W = WriteOverride(start: 0xC050, end: 0xC050, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC050)
        static func actionSwitchC050(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.TEXT_MODE = false
            return 0x00
        }
        
        static let switchC051R = ReadOverride(start: 0xC051, end: 0xC051, readAnyway: false, action: SoftswitchOverrides.actionSwitchC051)
        static let switchC051W = WriteOverride(start: 0xC051, end: 0xC051, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC051)
        static func actionSwitchC051(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.TEXT_MODE = true
            return 0x00
        }
        
        static let switchC052R = ReadOverride(start: 0xC052, end: 0xC052, readAnyway: false, action: SoftswitchOverrides.actionSwitchC052)
        static let switchC052W = WriteOverride(start: 0xC052, end: 0xC052, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC052)
        static func actionSwitchC052(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.MIX_MODE = false
            return 0x00
        }
        
        static let switchC053R = ReadOverride(start: 0xC053, end: 0xC053, readAnyway: false, action: SoftswitchOverrides.actionSwitchC053)
        static let switchC053W = WriteOverride(start: 0xC053, end: 0xC053, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC053)
        static func actionSwitchC053(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.MIX_MODE = true
            return 0x00
        }
        
        static let switchC054R = ReadOverride(start: 0xC054, end: 0xC054, readAnyway: false, action: SoftswitchOverrides.actionSwitchC054)
        static let switchC054W = WriteOverride(start: 0xC054, end: 0xC054, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC054)
        static func actionSwitchC054(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.PAGE_2 = false
            return 0x00
        }
        
        static let switchC055R = ReadOverride(start: 0xC055, end: 0xC055, readAnyway: false, action: SoftswitchOverrides.actionSwitchC055)
        static let switchC055W = WriteOverride(start: 0xC055, end: 0xC055, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC055)
        static func actionSwitchC055(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.PAGE_2 = true
            return 0x00
        }
        
        static let switchC056R = ReadOverride(start: 0xC056, end: 0xC056, readAnyway: false, action: SoftswitchOverrides.actionSwitchC056)
        static let switchC056W = WriteOverride(start: 0xC056, end: 0xC056, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC056)
        static func actionSwitchC056(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.HIRES_MODE = false
            return 0x00
        }
        
        static let switchC057R = ReadOverride(start: 0xC057, end: 0xC057, readAnyway: false, action: SoftswitchOverrides.actionSwitchC057)
        static let switchC057W = WriteOverride(start: 0xC057, end: 0xC057, writeAnyway: false, action: SoftswitchOverrides.actionSwitchC057)
        static func actionSwitchC057(dummy: AnyObject, address: UInt16, byte: UInt8?) -> UInt8? {
            EmulatedSystemInstance!.videoSoftswitches.HIRES_MODE = true
            return 0x00
        }
    }
    
}
