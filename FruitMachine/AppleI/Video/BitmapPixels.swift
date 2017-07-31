//
//  BitmapPixels.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/30/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class BitmapPixels: NSObject {
    //2bpp bitmap data so that we're byte-aligned for ease of use.
    struct PixelData {
        var data: UInt8 = 0
    }
    
    static let bitsPerComponent: UInt8 = 2
    static let bitsPerPixel: UInt = 8
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    static let ColorBlack = PixelData(data: 0b11000000)
    static let ColorWhite = PixelData(data: 0b11111111)
}
