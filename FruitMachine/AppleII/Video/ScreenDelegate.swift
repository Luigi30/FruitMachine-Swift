//
//  ScreenDelegate.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {

    enum CharacterAttributes {
        case normal
        case flashing
        case inverse
    }
    
    class ScreenDelegate: NSObject, CALayerDelegate {
        static let PIXEL_WIDTH = 280
        static let PIXEL_HEIGHT = 192
        
        static let CELLS_WIDTH = 40
        static let CELLS_HEIGHT = 24
        static let CELLS_COUNT = CELLS_WIDTH * CELLS_HEIGHT
        
        var flashIsInverse = false
        
        /* Pixel data stuff. */
        let bitmapInfo: CGBitmapInfo = [.byteOrder16Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)]
        
        var scanlineOffsets: [Int]
        var pixels: CVPixelBuffer?
        
        let sourceRowBytes: Int
        let bufferWidth: Int
        let bufferHeight: Int
        
        var renderedImage: CGImage?

        override init() {
            _ = CVPixelBufferCreate(kCFAllocatorDefault, AppleII.ScreenDelegate.PIXEL_WIDTH, AppleII.ScreenDelegate.PIXEL_HEIGHT, OSType(k16BE555PixelFormat), nil, &pixels)
            
            sourceRowBytes = CVPixelBufferGetBytesPerRow(pixels!)
            bufferWidth = CVPixelBufferGetWidth(pixels!)
            bufferHeight = CVPixelBufferGetHeight(pixels!)
            
            renderedImage = nil
            
            scanlineOffsets = [Int]()
            for i in 0..<AppleII.ScreenDelegate.PIXEL_HEIGHT {
                scanlineOffsets.append(i * AppleII.ScreenDelegate.PIXEL_WIDTH)
            }
        }
        
        /* Draw the screen. */
        func draw(_ layer: CALayer, in ctx: CGContext) {
            CVPixelBufferLockBaseAddress(pixels!, CVPixelBufferLockFlags.readOnly)
            let pixelBase = CVPixelBufferGetBaseAddress(pixels!)
            let pixelRef = CGDataProvider(dataInfo: nil, data: pixelBase!, size: sourceRowBytes * bufferHeight, releaseData: releaseMaskImagePixelData)
            
            renderedImage = CGImage(width: AppleII.ScreenDelegate.PIXEL_WIDTH,
                                    height: AppleII.ScreenDelegate.PIXEL_HEIGHT,
                                    bitsPerComponent: Int(BitmapPixelsLE555.bitsPerComponent), //5
                                    bitsPerPixel: Int(BitmapPixelsLE555.bitsPerPixel), //16
                                    bytesPerRow: AppleII.ScreenDelegate.PIXEL_WIDTH * Int(MemoryLayout<BitmapPixelsLE555.PixelData>.size),
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

}
