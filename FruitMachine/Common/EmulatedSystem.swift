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
    
    init(cpuFrequency: Double, fps: Double)
    func installOverrides()
}
