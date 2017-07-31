//
//  AppleI.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleI: NSObject {
    static let sharedInstance = AppleI()
    
    let cg = CharacterGenerator(romPath: "/Users/luigi/apple1/apple1.vid");
    let terminal = Terminal()
    
    let pia: [String:PIA] = [
        "keyboard": PIA(),
        "display": PIA()
    ]
    
    let emulatorViewDelegate = AppleIBitmapDisplay()
    let emulatorView = AppleScreenView(frame: NSMakeRect(0, 0, 640, 384))
    let emuScreenLayer = CALayer()
    
    static let CPU_FREQUENCY = 1000000
    static let FRAMES_PER_SECOND = 60
    static let CYCLES_PER_BATCH = CPU_FREQUENCY / FRAMES_PER_SECOND
    
    override init() {
        super.init()
        
        emuScreenLayer.shouldRasterize = true
        emuScreenLayer.delegate = emulatorViewDelegate
        emuScreenLayer.frame = emulatorView.bounds
        
        emulatorView.wantsLayer = true

        emuScreenLayer.setNeedsDisplay()
        emulatorView.layer?.addSublayer(emuScreenLayer)
        
        installOverrides()
        
        for (cellNum, character) in terminal.characters.enumerated() {
            emulatorViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: character), pixelPosition: emulatorViewDelegate.getPixelOffset(charCellIndex: cellNum))
        }
        
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple1/apple1.rom", offset: 0xFF00, length: 0x100)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple1/basic.bin", offset: 0xE000, length: 0x1000)
        CPU.sharedInstance.performReset()
        
    }
    
    func installOverrides() {
        CPU.sharedInstance.memoryInterface.write_overrides.append(PIAOverrides.writeDSP)
        CPU.sharedInstance.memoryInterface.read_overrides.append(PIAOverrides.readDSP)
        
        CPU.sharedInstance.memoryInterface.write_overrides.append(PIAOverrides.writeDSPCR)
        
        CPU.sharedInstance.memoryInterface.read_overrides.append(PIAOverrides.readKBD)
        CPU.sharedInstance.memoryInterface.read_overrides.append(PIAOverrides.readKBDCR)
        
    }
    
    func runFrame() {
        CPU.sharedInstance.cycles = 0
        CPU.sharedInstance.cyclesInBatch = AppleI.CYCLES_PER_BATCH
        CPU.sharedInstance.runCyclesBatch()
        
        //update the video display
        for (cellNum, character) in terminal.characters.enumerated() {
            emulatorViewDelegate.putCharacterPixels(charPixels: cg.getCharacterPixels(charIndex: character),
                                                    pixelPosition: emulatorViewDelegate.getPixelOffset(charCellIndex: cellNum))
        }
        
        emulatorView.setNeedsDisplay(emulatorView.frame)
        emulatorView.display()
        
        //emuGLView.setNeedsDisplay(emuGLView.frame)
        //emuGLView.display()
    }
}
