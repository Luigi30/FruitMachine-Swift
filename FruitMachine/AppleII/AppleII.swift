//
//  AppleII.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

final class AppleII: NSObject, EmulatedSystem {
    static let sharedInstance = AppleII(cpuFrequency: (14.31818 / 7 / 2) * 1000000, fps: 60.0)
    
    var frameCounter: Int = 0
    
    let cg = A2CharacterGenerator(romPath: "/Users/luigi/apple2/a2.chr");
    let keyboardController = KeyboardController()
    var videoSoftswitches = VideoSoftswitches()
    var videoMode: VideoMode
    
    //Peripherals
    var backplane = [Int: Peripheral?]()
    
    var CPU_FREQUENCY: Double
    var FRAMES_PER_SECOND: Double
    var CYCLES_PER_BATCH: Int
    
    let emulatorViewDelegate = AppleII.ScreenDelegate()
    let emulatorView = AppleII.ScreenView(frame: NSMakeRect(0, 16, 560, 384))
    let emuScreenLayer = CALayer()
    
    required init(cpuFrequency: Double, fps: Double) {
        CPU_FREQUENCY = cpuFrequency
        FRAMES_PER_SECOND = fps
        CYCLES_PER_BATCH = Int(cpuFrequency / fps)
        
        videoMode = .Text
        
        for i in 1...7 {
            backplane[i] = nil
        }
        backplane[6] = DiskII(slot: 6, romPath: "/Users/luigi/apple2/341-0027-a.p5")
        
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
        videoSoftswitches.reset()
        videoMode = .Text
        CPU.sharedInstance.performReset()
    }
    
    func loadROMs() {
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0001-00.e0", offset: 0xE000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0002-00.e8", offset: 0xE800, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0003-00.f0", offset: 0xF000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/341-0004-00.f8", offset: 0xF800, length: 0x800)
    }
    
    func installOverrides() {
        for (slotNum, peripheral) in backplane {
            if(peripheral != nil) {
                peripheral!.installOverrides()
            }
        }
        
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.readKeyboard)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.clearKeypressStrobeR)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.clearKeypressStrobeW)
        
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC050R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC051R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC052R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC053R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC054R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC055R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC056R)
        CPU.sharedInstance.memoryInterface.read_overrides.append(SoftswitchOverrides.switchC057R)
        
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC050W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC051W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC052W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC053W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC054W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC055W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC056W)
        CPU.sharedInstance.memoryInterface.write_overrides.append(SoftswitchOverrides.switchC057W)
    }
    
    func runFrame() {
        frameCounter = (frameCounter + 1) % 60
        if(frameCounter % 15) == 0 {
            emulatorViewDelegate.flashIsInverse = !emulatorViewDelegate.flashIsInverse
        }
        
        CPU.sharedInstance.cycles = 0
        CPU.sharedInstance.cyclesInBatch = CYCLES_PER_BATCH
        CPU.sharedInstance.runCyclesBatch()
        
        //update the video display
        CVPixelBufferLockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelBase = CVPixelBufferGetBaseAddress(emulatorViewDelegate.pixels!)
        let buf = pixelBase?.assumingMemoryBound(to: BitmapPixelsLE555.PixelData.self)
        
        videoMode = getCurrentVideoMode(switches: videoSoftswitches)
        
        if(videoMode == .Text)
        {
            //Text mode: Get character codes from $0400-$07FF
            putGlyphs(buffer: buf!, start: 0x400, end: 0x7F8)
        }
        else if(videoMode == .Lores)
        {
            putLoresPixels(buffer: buf!, start: 0x400, end: 0x7F8)
        }
        else if(videoMode == .MixedLores) {
            //Draw the lores pixel rows.
            putLoresPixels(buffer: buf!, start: 0x400, end: 0x650)
            putLoresPixels(buffer: buf!, start: 0x680, end: 0x6A8)
            putLoresPixels(buffer: buf!, start: 0x700, end: 0x728)
            putLoresPixels(buffer: buf!, start: 0x780, end: 0x7A8)
            putLoresPixels(buffer: buf!, start: 0x6A8, end: 0x6D0)
            putLoresPixels(buffer: buf!, start: 0x728, end: 0x750)
            putLoresPixels(buffer: buf!, start: 0x7A8, end: 0x7D0)
            
            //Draw the bottom 4 text rows.
            putGlyphs(buffer: buf!, start: 0x650, end: 0x678)
            putGlyphs(buffer: buf!, start: 0x6D0, end: 0x6F8)
            putGlyphs(buffer: buf!, start: 0x750, end: 0x778)
            putGlyphs(buffer: buf!, start: 0x7D0, end: 0x7F8)
        } else {
            print("Unimplemented video mode!")
        }
        
        
        CVPixelBufferUnlockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        emulatorView.display()
    }
    
    func putLoresPixels(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>, start: UInt16, end: UInt16) {
        for address in start ..< end {
            let pixelData = CPU.sharedInstance.memoryInterface.readByte(offset: UInt16(address), bypassOverrides: true)
            
            LoresMode.putLoresPixel(buffer: buffer,
                                               pixel: pixelData,
                                               address: UInt16(address))
        }
    }
    
    func putGlyphs(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>, start: UInt16, end: UInt16) {
        for address in start ... end {
            let charCode = CPU.sharedInstance.memoryInterface.readByte(offset: UInt16(address), bypassOverrides: true)
            
            TextMode.putGlyph(buffer: buffer,
                              glyph: cg.glyphs[Int(charCode & 0x3F)],
                              attributes: charCode & 0xC0, //d6 and d7
                              pixelPosition: VideoHelpers.getPixelOffset(memoryOffset: Int(address - 0x400)))
        }
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
            CPU.sharedInstance.memoryInterface.pages[page] = MemoryInterface.pageMode.ro    //ROM
        }
    }
    
}
