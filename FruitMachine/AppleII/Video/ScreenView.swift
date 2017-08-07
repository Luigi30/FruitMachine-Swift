//
//  ScreenView.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

extension AppleIIBase {

    class ScreenView: NSView {

        override var acceptsFirstResponder: Bool {
            return true
        }
        
        override func becomeFirstResponder() -> Bool {
            return true
        }
        
        override func resignFirstResponder() -> Bool {
            return true
        }
        
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            layer?.sublayers![0].setNeedsDisplay()
        }
        
    }

}
