//
//  AppleI.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/27/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleI: NSObject {
    var CPU_FREQUENCY: Double
    var FRAMES_PER_SECOND: Double
    var CYCLES_PER_BATCH: Int
    
    static let sharedInstance = AppleI(cpuFrequency: 1000000.0, fps: 60.0)
    
    let cg = A1CharacterGenerator(romPath: "/Users/luigi/apple1/apple1.vid");
    let terminal = Terminal()
    
    let pia: [String:PIA] = [
        "keyboard": PIA(),
        "display": PIA()
    ]
    
    let emulatorViewDelegate = AppleIBitmapDisplay()
    let emulatorView = AppleIScreenView(frame: NSMakeRect(0, 0, 640, 384))
    let emuScreenLayer = CALayer()
    
    required init(cpuFrequency: Double, fps: Double) {
        CPU_FREQUENCY = cpuFrequency
        FRAMES_PER_SECOND = fps
        CYCLES_PER_BATCH = Int(cpuFrequency / fps)
        super.init()
        
        emuScreenLayer.shouldRasterize = true
        emuScreenLayer.delegate = emulatorViewDelegate
        emuScreenLayer.frame = emulatorView.bounds
        
        emulatorView.wantsLayer = true
        
        emuScreenLayer.setNeedsDisplay()
        emulatorView.layer?.addSublayer(emuScreenLayer)
        
        installOverrides()
        
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
        CPU.sharedInstance.cyclesInBatch = AppleI.sharedInstance.CYCLES_PER_BATCH
        CPU.sharedInstance.runCyclesBatch()
        
        //update the video display
        CVPixelBufferLockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelBase = CVPixelBufferGetBaseAddress(emulatorViewDelegate.pixels!)
        let buf = pixelBase?.assumingMemoryBound(to: BitmapPixelsLE555.PixelData.self)
        
        for (cellNum, character) in terminal.characters.enumerated() {
            emulatorViewDelegate.putGlyph(buffer: buf,
                                          glyph: cg.glyphs[Int(cg.asciiToAppleCharIndex(ascii: character))],
                                          pixelPosition: emulatorViewDelegate.getPixelOffset(charCellIndex: cellNum))
        }
        
        CVPixelBufferUnlockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        
        emulatorView.setNeedsDisplay(emulatorView.frame)
        

    }
}
