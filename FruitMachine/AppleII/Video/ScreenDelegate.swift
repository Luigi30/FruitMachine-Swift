//
//  ScreenDelegate.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleII {

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
        
        var pixels: CVPixelBuffer?
        
        let sourceRowBytes: Int
        let bufferWidth: Int
        let bufferHeight: Int
        
        var renderedImage: CGImage?
        
        var scanlineOffsets: [Int]

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
        
        func putGlyph(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, glyph: Glyph, attributes: UInt8, pixelPosition: CGPoint) {
            //You better have locked the buffer before getting here...
            if(pixelPosition.x == -1 && pixelPosition.y == -1) { return }
            
            let ca: CharacterAttributes
            if(attributes == 0x00) {
                ca = .inverse
            } else if(attributes == 0x40) {
                ca = .flashing
            } else {
                ca = .normal
            }
            
            //Calculate the offset to reach the desired position.
            let baseOffset = scanlineOffsets[Int(pixelPosition.y)] + Int(pixelPosition.x)
            
            for charY in 0..<AppleII.A2CharacterGenerator.CHAR_HEIGHT {
                let offset = baseOffset + (AppleII.ScreenDelegate.PIXEL_WIDTH * charY)
                let glyphOffsetY = (charY * 8)
                
                for charX in 0..<7 {
                    switch(ca) {
                    case .normal:
                        buffer![offset + 6 - charX] = glyph.pixels[glyphOffsetY + charX]
                    case .inverse:
                        buffer![offset + 6 - charX] = BitmapPixelsLE555.PixelData(data: ~glyph.pixels[glyphOffsetY + charX].data)
                    case .flashing:
                        if(!flashIsInverse) {
                            buffer![offset + 6 - charX] = glyph.pixels[glyphOffsetY + charX]
                        } else {
                            buffer![offset + 6 - charX] = BitmapPixelsLE555.PixelData(data: ~glyph.pixels[glyphOffsetY + charX].data)
                        }
                    }
                    
                }
            }
        }
        
        func putLoresPixel(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, pixel: UInt8, address: UInt16) {
            let pageOffset = address - 0x400
            let pixelPosition = getPixelOffset(memoryOffset: Int(pageOffset))
            if(pixelPosition.x == -1 && pixelPosition.y == -1) {
                return
            }
            
            let pixelNybbleHi = pixel & 0x0F
            let pixelNybbleLo = (pixel & 0xF0) >> 4
            
            let colorHi = LoresColors.getColor(index: pixelNybbleHi)
            let colorLo = LoresColors.getColor(index: pixelNybbleLo)
            
            //One lores pixel is 7px wide and 4px tall for a resolution of 40x48.
            let baseOffset = scanlineOffsets[Int(pixelPosition.y)] + Int(pixelPosition.x)
            
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
        
        func getPixelOffset(charCellX: Int, charCellY: Int) -> CGPoint {
            return CGPoint(x: charCellX * 7, y: charCellY * 8)
        }
        
        func getPixelOffset(memoryOffset: Int) -> CGPoint {
            //Offset is between 0x000 and 0x3FF.
            //If offset & 0x28, second batch.
            //If offset & 0x50, third batch.
            //Else, first batch.
            
            var rowNumber = memoryOffset / 0x80
            let lowByte = memoryOffset & 0x0FF
            let cellX: Int
            
            if(0x28 ... 0x4F ~= lowByte || 0xA8 ... 0xCF ~= lowByte) {
                //Middle third.
                rowNumber += 8
                cellX = (lowByte & ~(0x80)) - 0x28
            }
            else if(0x50 ... 0x77 ~= lowByte || 0xD0 ... 0xF7 ~= lowByte) {
                //Bottom third.
                rowNumber += 16
                cellX = (lowByte & ~(0x80)) - 0x50
            }
            else if(0x78 ... 0x7F ~= lowByte || 0xF8 ... 0xFF ~= lowByte) {
                //Discard.
                return CGPoint(x: -1, y: -1)
            }
            else {
                //Top third.
                rowNumber += 0
                cellX = (lowByte & ~(0x80))
            }
            
            return getPixelOffset(charCellX: cellX, charCellY: rowNumber)
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
