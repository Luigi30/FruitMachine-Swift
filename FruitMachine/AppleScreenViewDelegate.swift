//
//  AppleScreenViewDelegate.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleScreenViewDelegate: NSObject, CALayerDelegate {
    let PIXEL_WIDTH = 200
    let PIXEL_HEIGHT = 192
    
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
    
    override init()
    {
        indexedPixels = [UInt8](repeating: 0x00, count: 200*192)
        colorValues = [PixelData](repeating: PixelData(a: 255, r: 0, g: 0, b: 0), count: 256)
        colorValues[1] = PixelData(a: 0, r: 200, g: 200, b: 200
        )
    }
    
    func convertIndexedPixelsToRGB(pixels: [UInt8]) -> [PixelData] {
        var rgbPixels = [PixelData](repeating: PixelData(a: 255, r: 0, g: 0, b: 0), count: 200*192)
        
        for (num, colorIndex) in pixels.enumerated() {
            rgbPixels[num] = colorValues[Int(colorIndex)]
        }
        
        return rgbPixels
    }
    
    func putCharacterPixels(charPixels: [UInt8], pixelPosition: CGPoint) {
        //Calculate the offset to reach the desired position.
        let baseOffset = (Int(pixelPosition.y) * PIXEL_WIDTH) + Int(pixelPosition.x)
        
        for charY in 0..<CharacterGenerator.CHAR_HEIGHT {
            for charX in 0..<CharacterGenerator.CHAR_WIDTH {
                indexedPixels[baseOffset + (PIXEL_WIDTH * charY) + CharacterGenerator.CHAR_WIDTH - charX] = (charPixels[charY] & UInt8(1 << charX)) > 0 ? 1 : 0
            }
        }
    }
    
    func getPixelOffset(charCellX: Int, charCellY: Int) -> CGPoint {
        return CGPoint(x: charCellX * 5, y: charCellY * 8)
    }

    /* Draw the screen. */
    func draw(_ layer: CALayer, in ctx: CGContext) {
        let bounds = layer.bounds
        ctx.interpolationQuality = CGInterpolationQuality.none
        
        var pixels = convertIndexedPixelsToRGB(pixels: indexedPixels)
        let pixelProvider = CGDataProvider(data: NSData(bytes: &pixels, length: pixels.count * MemoryLayout<PixelData>.size))
        
        let renderedImage = CGImage(width: PIXEL_WIDTH, height: PIXEL_HEIGHT, bitsPerComponent: Int(bitsPerComponent), bitsPerPixel: Int(bitsPerPixel), bytesPerRow: PIXEL_WIDTH * Int(MemoryLayout<PixelData>.size), space: colorSpace, bitmapInfo: bitmapInfo, provider: pixelProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        ctx.draw(renderedImage!, in: bounds)
        //draw stuff here
    }
    
}
