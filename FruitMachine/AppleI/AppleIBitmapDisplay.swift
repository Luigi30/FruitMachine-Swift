//
//  AppleScreenViewDelegate.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleIBitmapDisplay: NSObject, CALayerDelegate {
    static let PIXEL_WIDTH = 320
    static let PIXEL_HEIGHT = 192
    
    /* Pixel data stuff. */
    let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
    
    var rgbPixels = [BitmapPixels.PixelData](repeating: BitmapPixels.ColorBlack, count: AppleIBitmapDisplay.PIXEL_WIDTH*AppleIBitmapDisplay.PIXEL_HEIGHT)
    
    func putCharacterPixels(charPixels: [UInt8], pixelPosition: CGPoint) {
        //Calculate the offset to reach the desired position.
        let baseOffset = (Int(pixelPosition.y) * AppleIBitmapDisplay.PIXEL_WIDTH) + Int(pixelPosition.x)
        
        for charY in 0..<CharacterGenerator.CHAR_HEIGHT {
            let offsetY = AppleIBitmapDisplay.PIXEL_WIDTH * charY
            
            for charX in 0..<8 {
                rgbPixels[baseOffset + offsetY + 7 - charX] = (charPixels[charY] & UInt8(1 << charX)) > 0 ? BitmapPixels.ColorWhite : BitmapPixels.ColorBlack
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
        
        let pixelProvider = CGDataProvider(data: NSData(bytes: &rgbPixels, length: rgbPixels.count * MemoryLayout<BitmapPixels.PixelData>.size))
        
        let renderedImage = CGImage(width: AppleIBitmapDisplay.PIXEL_WIDTH,
                                    height: AppleIBitmapDisplay.PIXEL_HEIGHT,
                                    bitsPerComponent: Int(BitmapPixels.bitsPerComponent),
                                    bitsPerPixel: Int(BitmapPixels.bitsPerPixel),
                                    bytesPerRow: AppleIBitmapDisplay.PIXEL_WIDTH * Int(MemoryLayout<BitmapPixels.PixelData>.size),
                                    space: BitmapPixels.colorSpace,
                                    bitmapInfo: bitmapInfo,
                                    provider: pixelProvider!,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: CGColorRenderingIntent.defaultIntent)
        
        ctx.draw(renderedImage!, in: bounds)
    }
    
}
