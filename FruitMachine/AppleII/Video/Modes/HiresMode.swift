//
//  HiresMode.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/10/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {

    class HiresMode: NSObject {
        static func putHiresByte(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, pixel: UInt8, address: UInt16) {
            
            let pageBase: Address
            
            if(EmulatedSystemInstance!.videoSoftswitches.PAGE_2) {
                pageBase = 0x4000
            } else {
                pageBase = 0x2000
            }
            
            //Convert the address into an (X,Y) pixel coordinate.
            var offset = address - pageBase
            
            /*
            if(offset >= 0x2000) { //Page 2 address
                offset -= 0x2000
            }
             */
            
            //Find the row number.
            var rowNumber = 0
            let lowByte = UInt8(offset & 0xFF)
            var columnByte: UInt8 = 0x00
            
            if(0x28 ... 0x4F ~= lowByte || 0xA8 ... 0xCF ~= lowByte) {
                //Middle third.
                rowNumber += 64
                columnByte = (lowByte & 0x7F) - 0x28
            }
            else if(0x50 ... 0x77 ~= lowByte || 0xD0 ... 0xF7 ~= lowByte) {
                //Bottom third.
                rowNumber += 128
                columnByte = (lowByte & 0x7F) - 0x50
            }
            else if(0x78 ... 0x7F ~= lowByte || 0xF8 ... 0xFF ~= lowByte) {
                //Discard.
                return
            }
            else	 {
                //Top third.
                rowNumber += 0
                columnByte = lowByte & 0x7F
            }
        
            rowNumber += Int(offset / 0x400) /* One line per 0x400 */
            
            while offset > 0x400 {
                offset -= 0x400
            }
            rowNumber += Int((offset / 0x80) * 8)
            
            //if(pixel & 0x80)
            
            let dot0 = (pixel & 0x01) == 0x01
            let dot1 = (pixel & 0x02) == 0x02
            let dot2 = (pixel & 0x04) == 0x04
            let dot3 = (pixel & 0x08) == 0x08
            let dot4 = (pixel & 0x10) == 0x10
            let dot5 = (pixel & 0x20) == 0x20
            let dot6 = (pixel & 0x40) == 0x40
            
            let pixelRowOffset = Int(rowNumber * AppleII.ScreenDelegate.PIXEL_WIDTH)
            let pixelColumnOffset = Int(UInt16(columnByte) * 7)
            
            if(pixelRowOffset + pixelColumnOffset == (5 * AppleII.ScreenDelegate.PIXEL_WIDTH)) {
                let x = 0
            }
            
            if(dot0) {
                buffer![pixelRowOffset + 0 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 0 + pixelColumnOffset] = AppleII.LoresColors.Black
            }
            
            if(dot1) {
                buffer![pixelRowOffset + 1 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 1 + pixelColumnOffset] = AppleII.LoresColors.Black
            }
            
            if(dot2) {
                buffer![pixelRowOffset + 2 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 2 + pixelColumnOffset] = AppleII.LoresColors.Black
            }
            
            if(dot3) {
                buffer![pixelRowOffset + 3 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 3 + pixelColumnOffset] = AppleII.LoresColors.Black
            }
            
            if(dot4) {
                buffer![pixelRowOffset + 4 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 4 + pixelColumnOffset] = AppleII.LoresColors.Black
            }
            
            if(dot5) {
                buffer![pixelRowOffset + 5 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 5 + pixelColumnOffset] = AppleII.LoresColors.Black
            }
            
            if(dot6) {
                buffer![pixelRowOffset + 6 + pixelColumnOffset] = AppleII.LoresColors.White
            } else {
                buffer![pixelRowOffset + 6 + pixelColumnOffset] = AppleII.LoresColors.Black
            }

        }
    }

}
