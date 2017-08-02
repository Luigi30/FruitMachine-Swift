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
    let bitmapInfo: CGBitmapInfo = [.byteOrder16Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
    
    var pixels: CVPixelBuffer?
    
    let sourceRowBytes: Int
    let bufferWidth: Int
    let bufferHeight: Int
    
    var renderedImage: CGImage?
    
    var scanlineOffsets: [Int]
    
    override init() {
        _ = CVPixelBufferCreate(kCFAllocatorDefault, AppleIBitmapDisplay.PIXEL_WIDTH, AppleIBitmapDisplay.PIXEL_HEIGHT, OSType(k16BE555PixelFormat), nil, &pixels)
        
        sourceRowBytes = CVPixelBufferGetBytesPerRow(pixels!)
        bufferWidth = CVPixelBufferGetWidth(pixels!)
        bufferHeight = CVPixelBufferGetHeight(pixels!)
        
        renderedImage = nil
        
        scanlineOffsets = [Int]()
        for i in 0..<AppleIBitmapDisplay.PIXEL_HEIGHT {
            scanlineOffsets.append(i * AppleIBitmapDisplay.PIXEL_WIDTH)
        }
    }
    
    func putGlyph(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, glyph: Glyph, pixelPosition: CGPoint) {
        //You better have locked the buffer before getting here...
        
        //Calculate the offset to reach the desired position.
        let baseOffset = scanlineOffsets[Int(pixelPosition.y)] + Int(pixelPosition.x)
        
        for charY in 0..<AppleI.A1CharacterGenerator.CHAR_HEIGHT {
            let offset = baseOffset + AppleIBitmapDisplay.PIXEL_WIDTH * charY
            let glyphOffsetY = (charY * 8)
            
            for charX in 0..<8 {
                buffer![offset + 7 - charX] = glyph.pixels[glyphOffsetY + charX]
            }
        }
    }
    
    func getPixelOffset(charCellX: Int, charCellY: Int) -> CGPoint {
        return CGPoint(x: charCellX * 8, y: charCellY * 8)
    }
    
    func getPixelOffset(charCellIndex: Int) -> CGPoint {
        return getPixelOffset(charCellX: charCellIndex % AppleI.Terminal.CELLS_WIDTH, charCellY: charCellIndex / AppleI.Terminal.CELLS_WIDTH)
    }

    /* Draw the screen. */
    func draw(_ layer: CALayer, in ctx: CGContext) {
        CVPixelBufferLockBaseAddress(pixels!, CVPixelBufferLockFlags.readOnly)
        let pixelBase = CVPixelBufferGetBaseAddress(pixels!)
        let pixelRef = CGDataProvider(dataInfo: nil, data: pixelBase!, size: sourceRowBytes * bufferHeight, releaseData: releaseMaskImagePixelData)
        
        renderedImage = CGImage(width: AppleIBitmapDisplay.PIXEL_WIDTH,
                                    height: AppleIBitmapDisplay.PIXEL_HEIGHT,
                                    bitsPerComponent: Int(BitmapPixelsLE555.bitsPerComponent), //5
                                    bitsPerPixel: Int(BitmapPixelsLE555.bitsPerPixel), //16
                                    bytesPerRow: AppleIBitmapDisplay.PIXEL_WIDTH * Int(MemoryLayout<BitmapPixelsLE555.PixelData>.size),
                                    space: BitmapPixelsLE555.colorSpace, //RGB
                                    bitmapInfo: bitmapInfo, //BE555
                                    provider: pixelRef!,
                                    decode: nil,
                                    shouldInterpolate: false,
                                    intent: CGColorRenderingIntent.defaultIntent)
        
        ctx.draw(renderedImage!, in: layer.bounds)
        
        CVPixelBufferUnlockBaseAddress(pixels!, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
        // https://developer.apple.com/reference/coregraphics/cgdataproviderreleasedatacallback
        // N.B. 'CGDataProviderRelease' is unavailable: Core Foundation objects are automatically memory managed
        return
    }
    
}
