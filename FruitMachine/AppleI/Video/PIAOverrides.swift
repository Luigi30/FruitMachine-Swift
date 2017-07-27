//
//  Overrides.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class PIAOverrides: NSObject {
    static let writeDSP = WriteOverride(start: 0xD012, end: 0xD012, writeValue: false, action: PIAOverrides.actionWriteDSP)
    static func actionWriteDSP(terminal: AnyObject, byte: UInt8?) -> Void {
        //(terminal as! Terminal).putCharacter(charIndex: byte!)
        AppleI.sharedInstance.terminal.putCharacter(charIndex: byte!)
    }
    
    static let readDSP = ReadOverride(start: 0xD012, end: 0xD012, writeValue: false, action: PIAOverrides.actionReadDSP)
    static func actionReadDSP(terminal: AnyObject, byte: UInt8?) -> Void {
        CPU.sharedInstance.memoryInterface.writeByte(offset: 0xD012, value: CPU.sharedInstance.memoryInterface.readByte(offset: 0xD012, bypassOverrides: true) & 0x7F, bypassOverrides: true) //the display is always ready
    }
    
}
