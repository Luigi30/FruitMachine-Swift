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
    
    func putCharacterPixels(buffer: UnsafeMutablePointer<BitmapPixelsBE555.PixelData>?, charPixels: [UInt8], pixelPosition: CGPoint) {
        //You better have locked the buffer before getting here...
        
        //Calculate the offset to reach the desired position.
        let baseOffset = scanlineOffsets[Int(pixelPosition.y)] + Int(pixelPosition.x)
        
        for charY in 0..<CharacterGenerator.CHAR_HEIGHT {
            let offsetY = AppleIBitmapDisplay.PIXEL_WIDTH * charY
            
            for charX in 0..<8 {
                buffer![baseOffset + offsetY + 7 - charX] = (charPixels[charY] & UInt8(1 << charX)) > 0 ? BitmapPixelsBE555.ARGBWhite : BitmapPixelsBE555.ARGBBlack
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
        CVPixelBufferLockBaseAddress(pixels!, CVPixelBufferLockFlags.readOnly)
        let pixelBase = CVPixelBufferGetBaseAddress(pixels!)
        let pixelRef = CGDataProvider(dataInfo: nil, data: pixelBase!, size: sourceRowBytes * bufferHeight, releaseData: releaseMaskImagePixelData)
        
        renderedImage = CGImage(width: AppleIBitmapDisplay.PIXEL_WIDTH,
                                    height: AppleIBitmapDisplay.PIXEL_HEIGHT,
                                    bitsPerComponent: Int(BitmapPixelsBE555.bitsPerComponent), //5
                                    bitsPerPixel: Int(BitmapPixelsBE555.bitsPerPixel), //16
                                    bytesPerRow: AppleIBitmapDisplay.PIXEL_WIDTH * Int(MemoryLayout<BitmapPixelsBE555.PixelData>.size),
                                    space: BitmapPixelsBE555.colorSpace, //RGB
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
