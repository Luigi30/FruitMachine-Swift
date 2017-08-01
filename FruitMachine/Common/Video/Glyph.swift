//
//  Glyph.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

struct Glyph {
    var pixels: [BitmapPixelsBE555.PixelData] = [BitmapPixelsBE555.PixelData]()
    
    init(inPixels: [BitmapPixelsBE555.PixelData]) {
        pixels = inPixels
    }
}
