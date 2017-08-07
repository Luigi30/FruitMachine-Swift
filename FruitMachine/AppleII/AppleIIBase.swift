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
            CPU.sharedInstance.memoryInterface.pages[page] = MemoryInterface.pageMode.ro    //ROM
        }
    }
    
    func setupPeripherals() {
        let defaults = UserDefaults.standard
        
        /*
        let slot0 = defaults.string(forKey: "a2_Peripherals_Slot0")
        if(slot0 == "Language Card (16K)") {
            backplane[0] = LanguageCard16K(slot: 0, romPath: "/Users/luigi/apple2/341-0020-00.f8")
        }
         */
        
        let slot6 = defaults.string(forKey: "a2_Peripherals_Slot6")
        if(slot6 == "Disk II") {
            backplane[6] = DiskII(slot: 6, romPath: "/Users/luigi/apple2/341-0027-a.p5")
            
            let drive = backplane[6]! as! DiskII
            //drive.attachDiskImage(imagePath: "/Users/luigi/apple2/Apex II - Apple II Diagnostic (v4.7-1986).DSK")
            drive.attachDiskImage(imagePath: "/Users/luigi/apple2/clean332sysmas.do")
        }
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
        emulatorView.setNeedsDisplay(emulatorView.frame)
    }
    
    /* Video */
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
