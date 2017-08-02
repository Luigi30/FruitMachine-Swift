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
    
    var frameCounter: Int = 0
    
    let cg = A2CharacterGenerator(romPath: "/Users/luigi/apple2/a2.chr");
    let keyboardController = KeyboardController()
    
    var CPU_FREQUENCY: Double
    var FRAMES_PER_SECOND: Double
    var CYCLES_PER_BATCH: Int
    
    let emulatorViewDelegate = AppleII.ScreenDelegate()
    let emulatorView = AppleII.ScreenView(frame: NSMakeRect(0, 0, 560, 384))
    let emuScreenLayer = CALayer()
    
    required init(cpuFrequency: Double, fps: Double) {
        CPU_FREQUENCY = cpuFrequency
        FRAMES_PER_SECOND = fps
        CYCLES_PER_BATCH = Int(cpuFrequency / fps)
        super.init()
        
        loadROMs()
        setupMemory(ramConfig: .sixteenK)
        
        emuScreenLayer.shouldRasterize = true
        emuScreenLayer.delegate = emulatorViewDelegate
        emuScreenLayer.frame = emulatorView.bounds
        
        emulatorView.wantsLayer = true
        
        emuScreenLayer.setNeedsDisplay()
        emulatorView.layer?.addSublayer(emuScreenLayer)
        
        installOverrides()

        doReset()
    }
    
    func doReset() {
        CPU.sharedInstance.performReset()
    }
    
    func loadROMs() {
        /*
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0001-00.e0", offset: 0xE000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0002-00.e8", offset: 0xE800, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0003-00.f0", offset: 0xF000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0004-00.f8", offset: 0xF800, length: 0x800)
         */
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/6502/test.bin", offset: 0x0000, length: 0x10000)
    }
    
    func installOverrides() {
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.readKeyboard)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.clearKeypressStrobeR)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.clearKeypressStrobeW)
    }
    
    func runFrame() {
        frameCounter = (frameCounter + 1) % 60
        if(frameCounter % 15) == 0 {
            emulatorViewDelegate.flashIsInverse = !emulatorViewDelegate.flashIsInverse
        }
        
        CPU.sharedInstance.cycles = 0
        CPU.sharedInstance.cyclesInBatch = CYCLES_PER_BATCH
        CPU.sharedInstance.runCyclesBatch()
        
        //TODO
        //update the video display
        CVPixelBufferLockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelBase = CVPixelBufferGetBaseAddress(emulatorViewDelegate.pixels!)
        let buf = pixelBase?.assumingMemoryBound(to: BitmapPixelsBE555.PixelData.self)
        
        //Text mode: Get character codes from $0400-$07FF
        for address in 0x0400 ..< 0x07F8 {
            let charCode = CPU.sharedInstance.memoryInterface.readByte(offset: UInt16(address), bypassOverrides: true)
            
            emulatorViewDelegate.putGlyph(buffer: buf,
                                          glyph: cg.glyphs[Int(charCode & 0x3F)],
                                          attributes: charCode & 0xC0, //d6 and d7
                                          pixelPosition: emulatorViewDelegate.getPixelOffset(memoryOffset: address - 0x400))
        }
        
        CVPixelBufferUnlockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        
        emulatorView.setNeedsDisplay(emulatorView.frame)
    }
    
    enum MemoryConfiguration {
        case fourK
        case sixteenK
        case fortyeightK
    }
    
    func setupMemory(ramConfig: MemoryConfiguration) {
        let ramPages: Int
        
        switch ramConfig {
        case .fourK:
            ramPages = 4096 / 256
        case .sixteenK:
            ramPages = 16384 / 256
        case .fortyeightK:
            ramPages = 49152 / 256
        }
        
        for page in 0 ..< ramPages {
            CPU.sharedInstance.memoryInterface.pages[page] = MemoryInterface.pageMode.rw    //RAM
        }
        for page in ramPages ..< 192 {
            CPU.sharedInstance.memoryInterface.pages[page] = MemoryInterface.pageMode.null  //not connected
        }
        for page in 224 ..< 256 {
            CPU.sharedInstance.memoryInterface.pages[page] = MemoryInterface.pageMode.ro  //not connected
        }
    }
    
}
