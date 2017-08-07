//
//  LoresMode.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {

    class LoresMode: NSObject {
        static func putLoresPixel(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, pixel: UInt8, address: UInt16) {
            let pageOffset = address - 0x400
            let pixelPosition = VideoHelpers.getPixelOffset(memoryOffset: Int(pageOffset))
            if(pixelPosition.x == -1 && pixelPosition.y == -1) {
                return
            }
            
            let pixelNybbleHi = pixel & 0x0F
            let pixelNybbleLo = (pixel & 0xF0) >> 4
            
            let colorHi = AppleII.LoresColors.getColor(index: pixelNybbleHi)
            let colorLo = LoresColors.getColor(index: pixelNybbleLo)
            
            //One lores pixel is 7px wide and 4px tall for a resolution of 40x48.
            let baseOffset = EmulatedSystemInstance!.emulatorViewDelegate.scanlineOffsets[Int(pixelPosition.y)] + Int(pixelPosition.x)
            
            for charY in 0..<5 {
                let offsetHi = baseOffset + (AppleII.ScreenDelegate.PIXEL_WIDTH * charY)
                
                for charX in 0..<7 {
                    buffer![offsetHi + 6 - charX] = colorHi
                }
            }
            for charY in 4..<8 {
                let offsetLo = baseOffset + (AppleII.ScreenDelegate.PIXEL_WIDTH * charY)
                
                for charX in 0..<7 {
                    buffer![offsetLo + 6 - charX] = colorLo
                }
            }
            
        }
    }

}
