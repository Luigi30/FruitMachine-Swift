//
//  EmulatedSystem.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

protocol EmulatedSystem {
    var CPU_FREQUENCY: Double { get }
    var FRAMES_PER_SECOND: Double { get }
    var CYCLES_PER_BATCH: Int { get }
    
    init(cpuFrequency: Double, fps: Double, delegate: AppleIIBase.ScreenDelegate, view: AppleIIBase.ScreenView)
    func installOverrides()
    func loadROMs()
}

var EmulatedSystemInstance: AppleIIBase?

class AppleIIBase: NSObject, EmulatedSystem {
    //Peripherals
    var backplane = [Int: Peripheral?]()
    var frameCounter: Int = 0
    
    var CPU_FREQUENCY: Double
    var FRAMES_PER_SECOND: Double
    var CYCLES_PER_BATCH: Int
    
    var videoSoftswitches = VideoSoftswitches()
    var videoMode: VideoMode = .Text
    
    let cg = A2CharacterGenerator(romPath: "/Users/luigi/apple2/a2.chr");
    let keyboardController = KeyboardController()
    
    var emulatorViewDelegate: ScreenDelegate
    var emulatorView: ScreenView
    var emuScreenLayer = CALayer()
    
    required init(cpuFrequency: Double, fps: Double, delegate: ScreenDelegate, view: ScreenView) {
        CPU_FREQUENCY = cpuFrequency
        FRAMES_PER_SECOND = fps
        CYCLES_PER_BATCH = Int(CPU_FREQUENCY / FRAMES_PER_SECOND)
        
        emulatorViewDelegate = delegate
        emulatorView = view
        
        super.init()
        
        for i in 0...7 {
            backplane[i] = nil
        }
        
        setupMemory(ramConfig: .fortyeightK)
        setupPeripherals()

        emuScreenLayer.shouldRasterize = true
        emuScreenLayer.delegate = emulatorViewDelegate
        emuScreenLayer.frame = emulatorView.bounds
        
        emulatorView.wantsLayer = true
        emulatorView.layer?.addSublayer(emuScreenLayer)
        
        installOverrides()
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
        for page in 208 ..< 256 {
            CPU.sharedInstance.memoryInterface.pages[page] = MemoryInterface.pageMode.rw    //Bankswitching area
        }
    }
    
    func setupPeripherals() {
        let defaults = UserDefaults.standard
        
        let slot0 = defaults.string(forKey: "a2_Peripherals_Slot0")
        if(slot0 == "Language Card (16K)") {
            backplane[0] = LanguageCard16K(slot: 0, romPath: "/Users/luigi/apple2/341-0020-00.f8")
        }
        
        let slot6 = defaults.string(forKey: "a2_Peripherals_Slot6")
        if(slot6 == "Disk II") {
            backplane[6] = DiskII(slot: 6, romPath: "/Users/luigi/apple2/341-0027-a.p5")
        }
        
        //(backplane[6] as! DiskII).attachDiskImage(imagePath: "/Users/luigi/apple2/Prodos_2_4_1.po")
        (backplane[6] as! DiskII).attachDiskImage(imagePath: "/Users/luigi/apple2/clean332sysmas.do")
    }
    
    func doColdReset() {
        CPU.sharedInstance.coldReset()
        doReset()
    }
    
    func doReset() {
        videoSoftswitches.reset()
        videoMode = .Text
        CPU.sharedInstance.performReset()
    }
    
    func runFrame() {
        frameCounter = (frameCounter + 1) % 60
        if(frameCounter % 15) == 0 {
            emulatorViewDelegate.flashIsInverse = !emulatorViewDelegate.flashIsInverse
        }
        
        CPU.sharedInstance.cycles = 0
        CPU.sharedInstance.cyclesInBatch = CYCLES_PER_BATCH
        CPU.sharedInstance.runCyclesBatch()

        updateScreen()
    }
    
    func updateScreen() {
        CVPixelBufferLockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelBase = CVPixelBufferGetBaseAddress(emulatorViewDelegate.pixels!)
        let buf = pixelBase?.assumingMemoryBound(to: BitmapPixelsLE555.PixelData.self)
        
        videoMode = getCurrentVideoMode(switches: videoSoftswitches)
        
        let videoMemoryStart: Address
        if(videoSoftswitches.PAGE_2) {
            videoMemoryStart = 0x800
        } else {
            videoMemoryStart = 0x400
        }
        
        if(videoMode == .Text)
        {
            //Text mode: Get character codes from $0400-$07FF
            putGlyphs(buffer: buf!, start: videoMemoryStart, end: videoMemoryStart + 0x3F8)
        }
        else if(videoMode == .Lores)
        {
            putLoresPixels(buffer: buf!, start: videoMemoryStart, end: videoMemoryStart + 0x3F8)
        }
        else if(videoMode == .MixedLores) {
            //Draw the lores pixel rows.
            putLoresPixels(buffer: buf!, start: videoMemoryStart, end: videoMemoryStart + 0x250)
            putLoresPixels(buffer: buf!, start: videoMemoryStart + 0x280, end: videoMemoryStart + 0x2A8)
            putLoresPixels(buffer: buf!, start: videoMemoryStart + 0x300, end: videoMemoryStart + 0x328)
            putLoresPixels(buffer: buf!, start: videoMemoryStart + 0x380, end: videoMemoryStart + 0x3A8)
            putLoresPixels(buffer: buf!, start: videoMemoryStart + 0x2A8, end: videoMemoryStart + 0x2D0)
            putLoresPixels(buffer: buf!, start: videoMemoryStart + 0x328, end: videoMemoryStart + 0x350)
            putLoresPixels(buffer: buf!, start: videoMemoryStart + 0x3A8, end: videoMemoryStart + 0x3D0)
            
            //Draw the bottom 4 text rows.
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x250, end: videoMemoryStart + 0x278)
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x2D0, end: videoMemoryStart + 0x2F8)
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x350, end: videoMemoryStart + 0x378)
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x3D0, end: videoMemoryStart + 0x3F8)
        } else if(videoMode == .Hires) {

        } else if(videoMode == .MixedHires) {
            putHiresPixels(buffer: buf!, start: 0x2000, end: 0x3fff)
            
            //Draw the bottom 4 text rows.
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x250, end: videoMemoryStart + 0x278)
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x2D0, end: videoMemoryStart + 0x2F8)
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x350, end: videoMemoryStart + 0x378)
            putGlyphs(buffer: buf!, start: videoMemoryStart + 0x3D0, end: videoMemoryStart + 0x3F8)
        }
        
        CVPixelBufferUnlockBaseAddress(emulatorViewDelegate.pixels!, CVPixelBufferLockFlags(rawValue: 0))
        emulatorView.setNeedsDisplay(emulatorView.frame)
        
    }
    
    /* Video */
    func putHiresPixels(buffer: UnsafeMutablePointer<BitmapPixelsLE555.PixelData>, start: UInt16, end: UInt16) {
        for address in start ..< end {
            let pixelData = CPU.sharedInstance.memoryInterface.readByte(offset: UInt16(address), bypassOverrides: true)
            
            HiresMode.putHiresByte(buffer: buffer,
                                    pixel: pixelData,
                                    address: UInt16(address))
        }
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
    
    func installOverrides() { }
    func loadROMs() { }
    
}
