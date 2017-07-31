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
    let bitmapInfo: CGBitmapInfo = [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
    
    var pixels: CVPixelBuffer?
    
    let sourceRowBytes: Int
    let bufferWidth: Int
    let bufferHeight: Int
    
    override init() {
        _ = CVPixelBufferCreate(kCFAllocatorDefault, AppleIBitmapDisplay.PIXEL_WIDTH, AppleIBitmapDisplay.PIXEL_HEIGHT, OSType(k32ARGBPixelFormat), nil, &pixels)
        
        sourceRowBytes = CVPixelBufferGetBytesPerRow(pixels!)
        bufferWidth = CVPixelBufferGetWidth(pixels!)
        bufferHeight = CVPixelBufferGetHeight(pixels!)
    }
    
    func putCharacterPixels(charPixels: [UInt8], pixelPosition: CGPoint) {
        CVPixelBufferLockBaseAddress(pixels!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelBase = CVPixelBufferGetBaseAddress(pixels!)
        let buf = pixelBase?.assumingMemoryBound(to: BitmapPixelsARGB32.PixelData.self)
        
        //Calculate the offset to reach the desired position.
        let baseOffset = (Int(pixelPosition.y) * AppleIBitmapDisplay.PIXEL_WIDTH) + Int(pixelPosition.x)
        
        for charY in 0..<CharacterGenerator.CHAR_HEIGHT {
            let offsetY = AppleIBitmapDisplay.PIXEL_WIDTH * charY
            
            for charX in 0..<8 {
                buf![baseOffset + offsetY + 7 - charX] = (charPixels[charY] & UInt8(1 << charX)) > 0 ? BitmapPixelsARGB32.ARGBWhite : BitmapPixelsARGB32.ARGBBlack
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixels!, CVPixelBufferLockFlags(rawValue: 0))
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
        
        CVPixelBufferLockBaseAddress(pixels!, CVPixelBufferLockFlags.readOnly)
        let pixelBase = CVPixelBufferGetBaseAddress(pixels!)
        let pixelRef = CGDataProvider(dataInfo: nil, data: pixelBase!, size: sourceRowBytes * bufferHeight, releaseData: releaseMaskImagePixelData)
        
        let renderedImage = CGImage(width: AppleIBitmapDisplay.PIXEL_WIDTH,
                                    height: AppleIBitmapDisplay.PIXEL_HEIGHT,
                                    bitsPerComponent: Int(BitmapPixelsARGB32.bitsPerComponent), //8
                                    bitsPerPixel: Int(BitmapPixelsARGB32.bitsPerPixel), //32
                                    bytesPerRow: AppleIBitmapDisplay.PIXEL_WIDTH * Int(MemoryLayout<BitmapPixelsARGB32.PixelData>.size),
                                    space: BitmapPixelsARGB32.colorSpace, //RGB
                                    bitmapInfo: bitmapInfo, //ARGB32
                                    provider: pixelRef!,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: CGColorRenderingIntent.defaultIntent)
        
        ctx.draw(renderedImage!, in: bounds)
        
        CVPixelBufferUnlockBaseAddress(pixels!, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
        // https://developer.apple.com/reference/coregraphics/cgdataproviderreleasedatacallback
        // N.B. 'CGDataProviderRelease' is unavailable: Core Foundation objects are automatically memory managed
        return
    }
    
}
