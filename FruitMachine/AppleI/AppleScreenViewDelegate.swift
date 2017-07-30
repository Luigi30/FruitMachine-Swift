//
//  AppleScreenViewDelegate.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleScreenViewDelegate: NSObject, CALayerDelegate {
    static let PIXEL_WIDTH = 320
    static let PIXEL_HEIGHT = 192
    
    /* Pixel data stuff. */
    struct PixelData {
        var a: UInt8 = 255
        var r: UInt8
        var g: UInt8
        var b: UInt8
    }
    
    let bitsPerComponent: UInt = 8
    let bitsPerPixel: UInt = 32
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    /* */
    
    var indexedPixels: [UInt8]
    var colorValues: [PixelData]
    
    var rgbPixels = [PixelData](repeating: PixelData(a: 255, r: 0, g: 0, b: 0), count: AppleScreenViewDelegate.PIXEL_WIDTH*AppleScreenViewDelegate.PIXEL_HEIGHT)
    
    override init()
    {
        indexedPixels = [UInt8](repeating: 0x00, count: AppleScreenViewDelegate.PIXEL_WIDTH*AppleScreenViewDelegate.PIXEL_HEIGHT)
        colorValues = [PixelData](repeating: PixelData(a: 255, r: 0, g: 0, b: 0), count: 256)
        colorValues[1] = PixelData(a: 0, r: 200, g: 200, b: 200
        )
    }
    
    func convertIndexedPixelsToRGB(pixels: [UInt8]) -> [PixelData] {
        for (num, colorIndex) in pixels.enumerated() {
            rgbPixels[num] = colorValues[Int(colorIndex)]
        }
        
        return rgbPixels
    }
    
    func putCharacterPixels(charPixels: [UInt8], pixelPosition: CGPoint) {
        //Calculate the offset to reach the desired position.
        let baseOffset = (Int(pixelPosition.y) * AppleScreenViewDelegate.PIXEL_WIDTH) + Int(pixelPosition.x)
        
        for charY in 0..<CharacterGenerator.CHAR_HEIGHT {
            //for charX in 0..<CharacterGenerator.CHAR_WIDTH {
            for charX in 0..<8 {
                indexedPixels[baseOffset + (AppleScreenViewDelegate.PIXEL_WIDTH * charY) + 7 - charX] = (charPixels[charY] & UInt8(1 << charX)) > 0 ? 1 : 0
            }
        }
    }
    
    func getPixelOffset(charCellX: Int, charCellY: Int) -> CGPoint {
        return CGPoint(x: charCellX * 8, y: charCellY * 8)
    }
    
    func getPixelOffset(charCellIndex: Int) -> CGPoint {
        return getPixelOffset(charCellX: charCellIndex % Terminal.CELLS_WIDTH, charCellY: charCellIndex / Terminal.CELLS_WIDTH)
    }

    /* Draw the screen. */
    func draw(_ layer: CALayer, in ctx: CGContext) {
        let bounds = layer.bounds
        
        var pixels = convertIndexedPixelsToRGB(pixels: indexedPixels)
        let pixelProvider = CGDataProvider(data: NSData(bytes: &pixels, length: pixels.count * MemoryLayout<PixelData>.size))
        
        let renderedImage = CGImage(width: AppleScreenViewDelegate.PIXEL_WIDTH,
                                    height: AppleScreenViewDelegate.PIXEL_HEIGHT,
                                    bitsPerComponent: Int(bitsPerComponent),
                                    bitsPerPixel: Int(bitsPerPixel),
                                    bytesPerRow: AppleScreenViewDelegate.PIXEL_WIDTH * Int(MemoryLayout<PixelData>.size),
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo,
                                    provider: pixelProvider!,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: CGColorRenderingIntent.defaultIntent)
        
        ctx.draw(renderedImage!, in: bounds)
    }
    
}
