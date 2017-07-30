//
//  AppleIMetalView.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/30/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa
import Metal
import MetalKit

class AppleIMetalView: MTKView {
    var commandQueue: MTLCommandQueue?
    var renderPipelineState: MTLRenderPipelineState?
    var depthStencilState: MTLDepthStencilState?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        // Device
        device = MTLCreateSystemDefaultDevice()
    }
}
