//
//  CharacterGenerator.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

//The character generator ROM contains 64 8x5 glyphs.

class CharacterGenerator: NSObject {
    static let CHAR_WIDTH = 5
    static let CHAR_HEIGHT = 8
    
    var ROM: [UInt8]
    
    init(romPath: String) {
        ROM = [UInt8](repeating: 0xCC, count: 512)
        
        super.init()
        loadROM(path: romPath)
    }
    
    func loadROM(path: String) {
        do {
            let fileContent: NSData = try NSData(contentsOfFile: path)
            fileContent.getBytes(&ROM, range: NSRange(location: 0, length: 512))
        } catch {
            print(error)
        }
    }

    func getCharacterPixels(charIndex: UInt8) -> [UInt8] {
        var pixelArray = [UInt8](repeating: 0x00, count: CharacterGenerator.CHAR_HEIGHT)
        
        for scanlineIndex in 0..<CharacterGenerator.CHAR_HEIGHT {
            pixelArray[scanlineIndex] = ROM[scanlineIndex + (Int(charIndex) * CharacterGenerator.CHAR_HEIGHT)]
        }
        
        return pixelArray
    }
    
}
