//
//  AppleScreenView.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleIScreenView: NSView {
    
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
        // Drawing code here.
        
        layer?.sublayers![0].setNeedsDisplay()
        layer?.sublayers![0].display()
    }
    
}
