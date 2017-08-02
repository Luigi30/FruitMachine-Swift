//
//  Glyph.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

struct Glyph {
    var pixels: [BitmapPixelsLE555.PixelData] = [BitmapPixelsLE555.PixelData]()
    
    init(inPixels: [BitmapPixelsLE555.PixelData]) {
        pixels = inPixels
    }
}
