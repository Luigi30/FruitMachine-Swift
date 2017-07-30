//
//  AppleGLDisplay.swift
//  FruitMachine
//
//  Created by Christopher Rohl on 7/30/17.
//  Copyright © 2017 Christopher Rohl. All rights reserved.
//

import Cocoa
import OpenGL
import GLKit

class AppleGLDisplay: NSOpenGLView {
    
    var displayLink: CVDisplayLink?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        renderFrame()
        
    }
    
    func doSetup() {
        let attr = [
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
            NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
            NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFADepthSize), 32,
            0
        ]
        
        self.pixelFormat = NSOpenGLPixelFormat(attributes: attr)
        self.openGLContext = NSOpenGLContext(format: pixelFormat!, share: nil)
    }
    
    override func prepareOpenGL() {
        
        func displayLinkOutputCallback(displayLink: CVDisplayLink, _ now: UnsafePointer<CVTimeStamp>, _ outputTime: UnsafePointer<CVTimeStamp>, _ flagsIn: CVOptionFlags, _ flagsOut: UnsafeMutablePointer<CVOptionFlags>, _ displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn {
            unsafeBitCast(displayLinkContext, to: AppleGLDisplay.self).renderFrame()
            return kCVReturnSuccess
        }
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)
    }
    
    func renderFrame() {
        CGLLockContext((self.openGLContext?.cglContextObj!)!)
        CGLSetCurrentContext((self.openGLContext?.cglContextObj!)!)
        
        // Draw something...
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT));
 
        let vertices = [GLfloat]([-1, -1, 0,
                                  -1,  1, 0,
                                   1,  1, 0,
                                   1, -1, 0])
        
        let indices = [GLubyte]([0, 1, 2,
                                 0, 2, 3])

        glEnableVertexAttribArray(0)
        
        let ptr = UnsafePointer<GLfloat>(vertices)
        glVertexAttribPointer(0, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size), ptr)

        glDrawElements(GLenum(GL_TRIANGLES), 6, GLenum(GL_UNSIGNED_BYTE), indices)
        
        CGLFlushDrawable((self.openGLContext?.cglContextObj!)!)
        CGLUnlockContext((self.openGLContext?.cglContextObj!)!)
    }
    
    deinit {
        CVDisplayLinkStop(displayLink!)
    }

}
