//
//  AppleIIPlus.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 8/7/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa

class AppleIIPlus: AppleIIBase {
    static let sharedInstance = AppleIIPlus(cpuFrequency: 1000000, fps: 60.0)
    
    required init(cpuFrequency: Double, fps: Double) {
        super.init(cpuFrequency: cpuFrequency,
                   fps: fps,
                   delegate: ScreenDelegate(),
                   view: ScreenView(frame: NSMakeRect(0, 16, 560, 384)))
        
        loadROMs()
        doReset()
    }
    
    required init(cpuFrequency: Double, fps: Double, delegate: ScreenDelegate, view: ScreenView) {
        fatalError("init(cpuFrequency:fps:delegate:view:) has not been implemented")
    }
    
    override func loadROMs() {
        //Applesoft BASIC
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2p/341-0011.d0", offset: 0xD000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2p/341-0012.d8", offset: 0xD800, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2p/341-0013.e0", offset: 0xE000, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2p/341-0014.e8", offset: 0xE800, length: 0x800)
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2p/341-0015.f0", offset: 0xF000, length: 0x800)
        
        //Monitor
        CPU.sharedInstance.memoryInterface.loadBinary(path: "/Users/luigi/apple2p/341-0020-00.f8", offset: 0xF800, length: 0x800)
    }
    
    override func installOverrides() {
        for (_, peripheral) in backplane {
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
}
