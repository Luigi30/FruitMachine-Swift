//
//  AppleII.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/1/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleII: AppleIIBase {
    static let sharedInstance = AppleII(cpuFrequency: 1000000, fps: 60.0)
    
    required init(cpuFrequency: Double, fps: Double) {
        super.init(cpuFrequency: cpuFrequency,
                   fps: fps,
                   delegate: ScreenDelegate(),
                   view: ScreenView(frame: NSMakeRect(0, 16, 560, 384)),
                   chargen: A2CharacterGenerator(romPath: "/Users/luigi/apple2/apple2/a2.chr"))
        
        loadROMs()
        doReset()
    }
    
    required init(cpuFrequency: Double, fps: Double, delegate: ScreenDelegate, view: ScreenView, chargen: A2CharacterGenerator) {
        fatalError("init(cpuFrequency:fps:delegate:view:) has not been implemented")
    }
    
    override func loadROMs() {
        
        /* Integer BASIC */
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/apple2/341-0001-00.e0", offset: 0xE000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/apple2/341-0002-00.e8", offset: 0xE800, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/apple2/341-0003-00.f0", offset: 0xF000, length: 0x800)
        
        /* Monitor */
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2/apple2/341-0004-00.f8", offset: 0xF800, length: 0x800)
    }
    
    override func installOverrides() {
        for peripheral in backplane {
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
    
    @objc func debuggerBreak() {
       
    }
    
}
