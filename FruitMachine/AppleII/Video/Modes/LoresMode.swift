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
            
            let colorHi = AppleIIBase.LoresMode.Colors.getColor(index: pixelNybbleHi)
            let colorLo = AppleIIBase.LoresMode.Colors.getColor(index: pixelNybbleLo)
            
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
        
        struct Colors {
            static let Black        = BitmapPixelsLE555.RGB32toLE555(r: 0, g: 0, b: 0)
            static let Magenta      = BitmapPixelsLE555.RGB32toLE555(r: 227, g: 30, b: 96)
            static let DarkBlue     = BitmapPixelsLE555.RGB32toLE555(r: 96, g: 78, b: 189)
            static let Purple       = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 68, b: 253)
            static let DarkGreen    = BitmapPixelsLE555.RGB32toLE555(r: 0, g: 163, b: 96)
            static let Gray1        = BitmapPixelsLE555.RGB32toLE555(r: 156, g: 156, b: 156)
            static let MediumBlue   = BitmapPixelsLE555.RGB32toLE555(r: 20, g: 207, b: 253)
            static let LightBlue    = BitmapPixelsLE555.RGB32toLE555(r: 208, g: 195, b: 255)
            static let Brown        = BitmapPixelsLE555.RGB32toLE555(r: 96, g: 114, b: 3)
            static let Orange       = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 106, b: 60)
            static let Gray2        = BitmapPixelsLE555.RGB32toLE555(r: 156, g: 156, b: 156)
            static let Pink         = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 160, b: 208)
            static let LightGreen   = BitmapPixelsLE555.RGB32toLE555(r: 20, g: 245, b: 60)
            static let Yellow       = BitmapPixelsLE555.RGB32toLE555(r: 208, g: 221, b: 141)
            static let Aquamarine   = BitmapPixelsLE555.RGB32toLE555(r: 114, g: 255, b: 208)
            static let White        = BitmapPixelsLE555.RGB32toLE555(r: 255, g: 255, b: 255)
            
            static func getColor(index: UInt8) -> BitmapPixelsLE555.PixelData {
                switch index {
                case 0: return AppleIIBase.LoresMode.Colors.Black
                case 1: return AppleIIBase.LoresMode.Colors.Magenta
                case 2: return AppleIIBase.LoresMode.Colors.DarkBlue
                case 3: return AppleIIBase.LoresMode.Colors.Purple
                case 4: return AppleIIBase.LoresMode.Colors.DarkGreen
                case 5: return AppleIIBase.LoresMode.Colors.Gray1
                case 6: return AppleIIBase.LoresMode.Colors.MediumBlue
                case 7: return AppleIIBase.LoresMode.Colors.LightBlue
                case 8: return AppleIIBase.LoresMode.Colors.Brown
                case 9: return AppleIIBase.LoresMode.Colors.Orange
                case 10: return AppleIIBase.LoresMode.Colors.Gray2
                case 11: return AppleIIBase.LoresMode.Colors.Pink
                case 12: return AppleIIBase.LoresMode.Colors.LightGreen
                case 13: return AppleIIBase.LoresMode.Colors.Yellow
                case 14: return AppleIIBase.LoresMode.Colors.Aquamarine
                case 15: return AppleIIBase.LoresMode.Colors.White
                default:
                    print("tried to get color > 15")
                    return AppleIIBase.LoresMode.Colors.Black
                }
                
            }
        }
    }

}
