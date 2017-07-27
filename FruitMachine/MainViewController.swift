//
//  MainViewController.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/26/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa
import CoreGraphics

class MainViewController: NSViewController {
    var windowController: NSWindowController?
    var debuggerViewController = DebuggerViewController()
    let emuScreenLayer = CALayer()

    let cg = CharacterGenerator(romPath: "/Users/luigi/apple1/apple1.vid");
    var appleScreenView: AppleScreenView = AppleScreenView(frame: NSMakeRect(0, 0, 400, 384))
    let appleScreenViewDelegate = AppleScreenViewDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.addSubview(appleScreenView)
        
        appleScreenView.wantsLayer = true
        
        emuScreenLayer.delegate = appleScreenViewDelegate
        emuScreenLayer.frame = appleScreenView.bounds
        emuScreenLayer.setNeedsDisplay()
        appleScreenView.layer?.addSublayer(emuScreenLayer)
        
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x00), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 0, charCellY: 0))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x01), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 1, charCellY: 1))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x02), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 2, charCellY: 2))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x03), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 3, charCellY: 3))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x04), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 4, charCellY: 4))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x05), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 5, charCellY: 5))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x06), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 6, charCellY: 6))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x07), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 7, charCellY: 7))
        appleScreenViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: 0x08), pixelPosition: appleScreenViewDelegate.getPixelOffset(charCellX: 8, charCellY: 8))
        
        appleScreenView.display()
    }
}
