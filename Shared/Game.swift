//
//  Game.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit

class Game              : ObservableObject
{
    var view            : MTKView!
    var device          : MTLDevice!
    var commandQueue    : MTLCommandQueue!
    var commandBuffer   : MTLCommandBuffer!

    var texture         : Texture2D? = nil
    var metalStates     : MetalStates!
    
    var viewportSize    : vector_uint2
    var scaleFactor     : Float
    
    var assetFolder     : AssetFolder!
    var jsBridge        : JSBridge!
    
    var screenWidth     : Float = 0
    var screenHeight    : Float = 0

    var gameCmdQueue    : MTLCommandQueue? = nil
    var gameCmdBuffer   : MTLCommandBuffer? = nil
    
    var scriptEditor    : ScriptEditor? = nil
    
    var textureLoader   : MTKTextureLoader!
    
    @Published var currentName = ""

    init()
    {
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif

        jsBridge = JSBridge(self)
        assetFolder = AssetFolder()
        assetFolder.setup(self)
    }
    
    func setupView(_ view: MTKView)
    {
        self.view = view
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            device = metalDevice
        } else {
            print("Cannot initialize Metal!")
        }
        
        commandQueue = device.makeCommandQueue()!

        metalStates = MetalStates(self)
        textureLoader = MTKTextureLoader(device: device)
    }
    
    func build()
    {
        jsBridge.compile(assetFolder)
    }

    func checkTexture()
    {
        if texture == nil {
            texture = Texture2D(self)
            
            viewportSize.x = UInt32(view.frame.width)
            viewportSize.y = UInt32(view.frame.height)
            
            screenWidth = Float(view.frame.width)
            screenHeight = Float(view.frame.height)
        } else
        if texture!.texture.width != Int(view.frame.width) || texture!.texture.height != Int(view.frame.height) {
            texture = nil            
            texture = Texture2D(self)
            
            viewportSize.x = UInt32(view.frame.width)
            viewportSize.y = UInt32(view.frame.height)
            
            screenWidth = Float(view.frame.width)
            screenHeight = Float(view.frame.height)
        }
    }
    
    func draw()
    {
        checkTexture()
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        gameCmdQueue = view.device!.makeCommandQueue()
        gameCmdBuffer = gameCmdQueue!.makeCommandBuffer()
        
        jsBridge.run()

        gameCmdBuffer?.commit()
        
        gameCmdBuffer?.addCompletedHandler { cb in
            //print("Rendering Time:", (cb.gpuEndTime - cb.gpuStartTime) * 1000)
        }
        
        commandBuffer = nil
        commandBuffer = commandQueue.makeCommandBuffer()
        let rpd = view.currentRenderPassDescriptor
        rpd?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        rpd?.colorAttachments[0].loadAction = .clear
        rpd?.colorAttachments[0].storeAction = .store
        let re = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd!)
        
        //drawDisc(renderEncoder: re!, x: 50, y: 0, radius: 100, borderSize: 0, fillColor: SIMD4<Float>(1,1,1,1))
        drawTexture(renderEncoder: re!)
        
        re?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    func drawDisc(renderEncoder: MTLRenderCommandEncoder, x: Float, y: Float, radius: Float, borderSize: Float, fillColor: SIMD4<Float>, borderColor: SIMD4<Float> = SIMD4<Float>(0,0,0,0))
    {
        let settings: [Float] = [
            fillColor.x, fillColor.y, fillColor.z, fillColor.w,
            borderColor.x, borderColor.y, borderColor.z, borderColor.w,
            radius / scaleFactor, borderSize / scaleFactor,
            0, 0
        ];
                
        let rect = MMRect( x - borderSize / 2, y - borderSize / 2, radius / scaleFactor * 2 + borderSize, radius / scaleFactor * 2 + borderSize, scale: scaleFactor )
        let vertexData = createVertexData(texture: texture!, rect: rect)
        
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(settings, length: settings.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setRenderPipelineState(metalStates.getState(state: .DrawDisc))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func drawTexture(renderEncoder: MTLRenderCommandEncoder)
    {
        let width : Float = Float(texture!.width)
        let height: Float = Float(texture!.height)

        var settings = TextureUniform()
        settings.screenSize.x = screenWidth
        settings.screenSize.y = screenHeight
        settings.pos.x = 0
        settings.pos.y = 0
        settings.size.x = width * scaleFactor
        settings.size.y = height * scaleFactor
        settings.globalAlpha = 1
                
        let rect = MMRect( 0, 0, width, height, scale: scaleFactor )
        let vertexData = createVertexData(texture: texture!, rect: rect)
        
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&settings, length: MemoryLayout<TextureUniform>.stride, index: 0)
        renderEncoder.setFragmentTexture(texture?.texture, index: 1)

        renderEncoder.setRenderPipelineState(metalStates.getState(state: .CopyTexture))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /// Creates vertex data for the given rectangle
    func createVertexData(texture: Texture2D, rect: MMRect) -> [Float]
    {
        let left = -texture.width / 2 + rect.x
        let right = left + rect.width//self.width / 2 - x
        
        let top = texture.height / 2 - rect.y
        let bottom = top - rect.height

        let quadVertices: [Float] = [
            right, bottom, 1.0, 0.0,
            left, bottom, 0.0, 0.0,
            left, top, 0.0, 1.0,
            
            right, bottom, 1.0, 0.0,
            left, top, 0.0, 1.0,
            right, top, 1.0, 1.0,
        ]
        
        return quadVertices
    }
    
}
