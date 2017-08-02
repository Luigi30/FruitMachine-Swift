//
//  CharacterGenerator.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleII {
    
    //The Apple II character generator is a clone of the Signetics 2513 from the Apple I.
    
    class A2CharacterGenerator: NSObject {
        static let CHAR_WIDTH = 5
        static let CHAR_HEIGHT = 8
        
        var ROM: [UInt8]
        var glyphs: [Glyph]
        
        init(romPath: String) {
            ROM = [UInt8](repeating: 0xCC, count: 0x800)
            glyphs = [Glyph](repeating: Glyph(inPixels: [BitmapPixelsLE555.PixelData]()), count: 64)
            
            super.init()
            loadROM(path: romPath)
            
            for index in 0..<64 {
                glyphs[index] = Glyph(inPixels: getCharacterPixels(charIndex: UInt8(index)))
            }
        }
        
        private func getCharacterPixels(charIndex: UInt8) -> [BitmapPixelsLE555.PixelData] {
            var pixelArray = [UInt8](repeating: 0x00, count: A2CharacterGenerator.CHAR_HEIGHT)
            
            /* Instead of ignoring ASCII bit b6, we ignore bit b5. At the same time ASCII bit b6 must be inverted before it is fed to the character ROM. This way the entire character range from $40 to $7F will end up in the range $00 to $1F (twice of course). Now lower case characters are automatically translated into their corresponding upper case bit maps.
             */
            
            //Don't convert the character indexes if we're populating the glyphs array.
            for scanlineIndex in 0..<A2CharacterGenerator.CHAR_HEIGHT {
                pixelArray[scanlineIndex] = ROM[scanlineIndex + (Int(charIndex) * A2CharacterGenerator.CHAR_HEIGHT)]
            }
            
            var glyphPixels = [BitmapPixelsLE555.PixelData]()
            
            for charY in 0..<A2CharacterGenerator.CHAR_HEIGHT {
                for charX in 0..<8 {
                    glyphPixels.append(pixelArray[Int(charY)] & (1 << charX) > 0 ? BitmapPixelsLE555.White : BitmapPixelsLE555.Black)
                }
            }
            
            return glyphPixels
        }
        
        func asciiToAppleCharIndex(ascii: UInt8) -> UInt8 {
            return (ascii & 0x1f) | (((ascii ^ 0x40) & 0x40) >> 1)
        }
        
        private func loadROM(path: String) {
            do {
                let fileContent: NSData = try NSData(contentsOfFile: path)
                fileContent.getBytes(&ROM, range: NSRange(location: 0, length: 0x800))
            } catch {
                print(error)
            }
        }
    }

}
