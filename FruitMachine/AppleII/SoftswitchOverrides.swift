//
//  SoftswitchOverrides.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleII {

    class SoftswitchOverrides: NSObject {
        static let readKeyboard = ReadOverride(start: 0xC000, end: 0xC000, readAnyway: false, action: SoftswitchOverrides.actionReadKeyboard)
        static func actionReadKeyboard(dummy: AnyObject, byte: UInt8?) -> UInt8? {
            //let b = CPU.sharedInstance.memoryInterface.readByte(offset: 0xC000, bypassOverrides: true)
            //CPU.sharedInstance.memoryInterface.writeByte(offset: 0xC000, value: b)
            //return b
            return AppleII.sharedInstance.keyboardController.KEYBOARD
        }
        
        static let clearKeypressStrobeR = ReadOverride(start: 0xC010, end: 0xC010, readAnyway: false, action: SoftswitchOverrides.actionClearKeypressStrobe)
        static let clearKeypressStrobeW = WriteOverride(start: 0xC010, end: 0xC010, writeAnyway: false, action: SoftswitchOverrides.actionClearKeypressStrobe)
        static func actionClearKeypressStrobe(dummy: AnyObject, byte: UInt8?) -> UInt8? {
            //Clears b7 of $C000 on write.
            
            //let b = CPU.sharedInstance.memoryInterface.readByte(offset: 0xC000, bypassOverrides: true)
            //CPU.sharedInstance.memoryInterface.writeByte(offset: 0xC000, value: b & 0x7F, bypassOverrides: true)
            //CPU.sharedInstance.memoryInterface.writeByte(offset: 0xC010, value: b & 0x7F, bypassOverrides: true)

            //return b
            let b = AppleII.sharedInstance.keyboardController.KEYBOARD
            AppleII.sharedInstance.keyboardController.KEYBOARD = b & 0x7F
            AppleII.sharedInstance.keyboardController.STROBE = b & 0x7F
            return b
        }
    }
    
}
