//
//  AppleII.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleII: NSObject, EmulatedSystem {
    static let sharedInstance = AppleII(cpuFrequency: (14.31818 / 7 / 2) * 1000000, fps: 60.0)
    
    var CPU_FREQUENCY: Double
    var FRAMES_PER_SECOND: Double
    var CYCLES_PER_BATCH: Int
    
    let emulatorViewDelegate = AppleII.ScreenDelegate()
    let emulatorView = AppleII.ScreenView(frame: NSMakeRect(0, 0, 640, 384))
    let emuScreenLayer = CALayer()
    
    required init(cpuFrequency: Double, fps: Double) {
        CPU_FREQUENCY = cpuFrequency
        FRAMES_PER_SECOND = fps
        CYCLES_PER_BATCH = Int(cpuFrequency / fps)
        super.init()
        
        loadROMs()
        
        /*
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
         */
    }
    
    func loadROMs() {
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0001-00.e0", offset: 0xE000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0002-00.e8", offset: 0xE800, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0003-00.f0", offset: 0xF000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0004-00.f8", offset: 0xF800, length: 0x800)
    }
    
    func installOverrides() {
        //TODO
    }
    
    func runFrame() {
        CPU.sharedInstance.cycles = 0
        CPU.sharedInstance.cyclesInBatch = CYCLES_PER_BATCH
        CPU.sharedInstance.runCyclesBatch()
        
        //TODO
    }
    
}
