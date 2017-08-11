//
//  HiresMode.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/10/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class HiresMode: NSObject {
    static func putHiresPixel(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, pixel: UInt8, address: UInt16) {
        let pageBase: Address
        
        if(EmulatedSystemInstance!.videoSoftswitches.PAGE_2) {
            pageBase = 0x4000
        } else {
            pageBase = 0x2000
        }
        
        //Convert the address into an (X,Y) pixel coordinate.
        var offset = address - 0x2000
        if(offset >= 0x2000) { //Page 2 address
            offset -= 0x2000
        }
        
        //Find the row number.
        var rowNumber = offset / 0x80
        let lowByte = offset & 0x0FF
        
        if(0x28 ... 0x4F ~= lowByte || 0xA8 ... 0xCF ~= lowByte) {
            //Middle third.
            rowNumber += 64
            //cellX = (lowByte & ~(0x80)) - 0x28
        }
        else if(0x50 ... 0x77 ~= lowByte || 0xD0 ... 0xF7 ~= lowByte) {
            //Bottom third.
            rowNumber += 64
            //cellX = (lowByte & ~(0x80)) - 0x50
        }
        else if(0x78 ... 0x7F ~= lowByte || 0xF8 ... 0xFF ~= lowByte) {
            //Discard.
        }
        else {
            //Top third.
            rowNumber += 0
            //cellX = (lowByte & ~(0x80))
        }
        
        rowNumber += offset / 0x400
        
        let columnByte = (offset & 0x0007)
        
    }
}
