//
//  VideoHelpers.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/2/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleII {
    class VideoHelpers: NSObject {
        static func getPixelOffset(charCellX: Int, charCellY: Int) -> CGPoint {
            return CGPoint(x: charCellX * 7, y: charCellY * 8)
        }
        
        static func getPixelOffset(memoryOffset: Int) -> CGPoint {
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
    }
}
