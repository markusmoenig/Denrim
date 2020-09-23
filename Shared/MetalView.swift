//
//  MetalView.swift
//  Denrim
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI
import MetalKit

public class DMTKView       : MTKView
{
    var game                : Game!

    #if os(OSX)
    
    var keysDown            : [Float] = []
    
    override public var acceptsFirstResponder: Bool { return true }
    
    func createMouseEvent(type: String,_ event: NSEvent)
    {
        var location = event.locationInWindow
        location.y = CGFloat(frame.height) - location.y
        location = convert(location, from: nil)
        
        /*
        game.jsBridge.execute(
        """
        game.touch({
            type: \(type),
            x: \(location.x),
            y: \(location.y)
        })
        """)
        */
    }
    
    override public func keyDown(with event: NSEvent)
    {
        keysDown.append(Float(event.keyCode))

        /*
        keysDown.append(Float(event.keyCode))
        if focusWidget != nil {
            let keyEvent = MMKeyEvent(event.characters, event.keyCode)
            focusWidget!.keyDown(keyEvent)
        }*/
        //super.keyDown(with: event)
    }
    
    override public func keyUp(with event: NSEvent)
    {
        keysDown.removeAll{$0 == Float(event.keyCode)}
        /*
        if focusWidget != nil {
            let keyEvent = MMKeyEvent(event.characters, event.keyCode)
            focusWidget!.keyUp(keyEvent)
        }
        //super.keyUp(with: event)*/
    }
        
    override public func mouseDown(with event: NSEvent) {
        if game.state == .Running {
            createMouseEvent(type: "TouchType.DOWN", event)
        }
    }
    
    override public func mouseDragged(with event: NSEvent) {
        if game.state == .Running {
            createMouseEvent(type: "TouchType.MOVE", event)
        }
    }
    
    override public func mouseUp(with event: NSEvent) {
        if game.state == .Running {
            createMouseEvent(type: "TouchType.UP", event)
        }
    }
    #endif
}

#if os(OSX)
struct MetalView: NSViewRepresentable {
    var game                : Game!
    var trackingArea        : NSTrackingArea?

    init(_ game: Game)
    {
        self.game = game
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = DMTKView()
        mtkView.game = game
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
                
        game.setupView(mtkView)
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            parent.game.draw()
        }
    }
}
#else
struct MetalView: UIViewRepresentable {
    typealias UIViewType = MTKView
    var game             : Game!

    init(_ game: Game)
    {
        self.game = game
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MetalView>) -> MTKView {
        let mtkView = DMTKView()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        }
        mtkView.framebufferOnly = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = true
        
        //MetalView.game = Game(mtkView)
        
        game.setupView(mtkView)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: UIViewRepresentableContext<MetalView>) {
    }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: MetalView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
        
        func draw(in view: MTKView) {
            parent.game.draw()
        }
    }
}
#endif
