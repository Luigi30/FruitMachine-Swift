//
//  TextMode.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {

    class TextMode: NSObject {
        static func putGlyph(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>?, glyph: Glyph, attributes: UInt8, pixelPosition: CGPoint) {
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
            let baseOffset = EmulatedSystemInstance!.emulatorViewDelegate.scanlineOffsets[Int(pixelPosition.y)] + Int(pixelPosition.x)
            
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
                        if(!EmulatedSystemInstance!.emulatorViewDelegate.flashIsInverse) {
                            buffer![offset + 6 - charX] = glyph.pixels[glyphOffsetY + charX]
                        } else {
                            buffer![offset + 6 - charX] = BitmapPixelsLE555.PixelData(data: ~glyph.pixels[glyphOffsetY + charX].data)
                        }
                    }
                    
                }
            }
        }
    }

}
