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
    
    static let Black = PixelData(data: 0b11000000)
    static let White = PixelData(data: 0b11111111)
}

class BitmapPixelsARGB32 : NSObject {
    struct PixelData {
        var a: UInt8 = 255
        var r: UInt8 = 0
        var g: UInt8 = 0
        var b: UInt8 = 0
    }
    
    static let bitsPerComponent: UInt8 = 8
    static let bitsPerPixel: UInt = 32
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    static let White = PixelData(a: 255, r: 200, g: 200, b: 200)
    static let Black = PixelData(a: 255, r: 0, g: 0, b: 0)
}

class BitmapPixelsBE555 : NSObject {
    struct PixelData {
        var data: UInt16 = 0
    }
    
    static let bitsPerComponent: UInt8 = 5
    static let bitsPerPixel: UInt = 16
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    static let White = PixelData(data: 0b1111111101111111)
    static let Black = PixelData(data: 0b0000000000000000)
}
