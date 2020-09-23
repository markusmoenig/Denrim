//
//  Game.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import Combine

class Game              : ObservableObject
{
    enum State {
        case Idle, Running, Paused
    }
    
    var state           : State = .Idle
    
    var view            : DMTKView!
    var device          : MTLDevice!
    var commandQueue    : MTLCommandQueue!
    var commandBuffer   : MTLCommandBuffer!

    var texture         : Texture2D? = nil
    var metalStates     : MetalStates!
    
    var viewportSize    : vector_uint2
    var scaleFactor     : Float
    
    var assetFolder     : AssetFolder!
    
    var screenWidth     : Float = 0
    var screenHeight    : Float = 0

    var gameCmdQueue    : MTLCommandQueue? = nil
    var gameCmdBuffer   : MTLCommandBuffer? = nil
    
    var scriptEditor    : ScriptEditor? = nil
    var file            : File? = nil

    var mapBuilder      : MapBuilder!
    var behaviorBuilder : BehaviorBuilder!

    var textureLoader   : MTKTextureLoader!
        
    var resources       : [AnyObject] = []
    var availableFonts  : [String] = ["OpenSans", "Square", "SourceCodePro"]
    
    var gameContext     : BehaviorContext? = nil
    var currentMap      : Asset? = nil
    var currentScene    : MapScene? = nil

    // Preview Size, UI only
    var previewFactor   : CGFloat = 4
    var previewOpacity  : Double = 0.5

    init()
    {
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif
        
        file = File()
        //jsBridge = JSBridge(self)
        
        assetFolder = AssetFolder()
        assetFolder.setup(self)
        
        mapBuilder = MapBuilder(self)
        behaviorBuilder = BehaviorBuilder(self)
    }
    
    func setupView(_ view: DMTKView)
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
    
    func start()
    {
        state = .Running

        var hasError: Bool = false
        for asset in assetFolder.assets {
            if asset.type == .Behavior {
             
                let error = behaviorBuilder.compile(asset)
                if error.error != nil {
                    hasError = true
                    break
                } else {
                    if asset.name == "Game" {
                        gameContext = asset.behavior
                        
                        if let context = gameContext {
                            context.execute(name: "init")
                        }
                    }
                }
            }
        }

        if !hasError {
            state = .Running
            view.enableSetNeedsDisplay = false
            view.isPaused = false
        } else {
            stop()
        }
    }
    
    func stop()
    {
        gameContext = nil        
        currentScene = nil
        currentMap = nil
        
        state = .Idle
        view.isPaused = true
    }
    
    func checkTexture() -> Bool
    {
        if texture == nil {
            texture = Texture2D(self)
    
            viewportSize.x = UInt32(texture!.width)
            viewportSize.y = UInt32(texture!.height)
            
            screenWidth = Float(texture!.width)
            screenHeight = Float(texture!.height)
            return true
        } else
        if texture!.texture.width != Int(view.frame.width) || texture!.texture.height != Int(view.frame.height) {
            texture?.allocateTexture(width: Int(view.frame.width), height: Int(view.frame.height))
            
            viewportSize.x = UInt32(texture!.width)
            viewportSize.y = UInt32(texture!.height)
            
            screenWidth = Float(texture!.width)
            screenHeight = Float(texture!.height)
            return true
        }
        return false
    }
    
    func draw()
    {
        if checkTexture() && state == .Idle{
            // We need to update the screen
            if assetFolder.current?.type == .Map && assetFolder.current?.map != nil {
                if let mapBuilder = mapBuilder {
                    mapBuilder.createPreview(assetFolder.current!.map!)
                }
            } else {
                startDrawing()
                texture?.clear()
                stopDrawing()
            }
        }
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        gameCmdBuffer?.addCompletedHandler { cb in
            //print("GPU Time:", (cb.gpuEndTime - cb.gpuStartTime) * 1000)
        }
        
        commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        renderPassDescriptor?.colorAttachments[0].loadAction = .clear
        renderPassDescriptor?.colorAttachments[0].storeAction = .store
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        
        //drawDisc(renderEncoder: re!, x: 50, y: 0, radius: 100, borderSize: 0, fillColor: SIMD4<Float>(1,1,1,1))
        drawTexture(renderEncoder: renderEncoder!)
        
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        commandBuffer = nil

        if state == .Running {
            //DispatchQueue.main.async {
                
                self.startDrawing()

                //#if DEBUG
                //let startTime = Double(Date().timeIntervalSince1970)
                //#endif

                self.texture?.clear()

                if let context = self.gameContext {
                    context.execute(name: "update")
                }            
                
                if let mapAsset = self.currentMap {
                    if let map = mapAsset.map {
                        //map.drawScene
                        if let scene = self.currentScene {
                            map.drawScene(0, 0, scene)
                        }
                    }
                }

                //#if DEBUG
                //print("JS Time: ", (Double(Date().timeIntervalSince1970) - startTime) * 1000)
                //#endif
                
                stopDrawing(deleteQueue: true)
            }
        //}
    }
    
    func startDrawing()
    {
        if gameCmdQueue == nil {
            gameCmdQueue = view.device!.makeCommandQueue()
        }
        gameCmdBuffer = gameCmdQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(deleteQueue: Bool = true)
    {
        gameCmdBuffer?.commit()

        if deleteQueue {
            self.gameCmdQueue = nil
        }
        self.gameCmdBuffer = nil
    }
    
    func createPreview(_ asset: Asset)
    {
        if state == .Idle && asset.type == .Shader {
            let compiler = ShaderCompiler(asset, self)

            compiler.compile({ (shader) in
                
                DispatchQueue.main.async {
                    self.startDrawing()
                    
                    let rect = MMRect( 0, 0, self.texture!.width, self.texture!.height, scale: self.scaleFactor )
                    self.texture?.drawShader(shader, rect)
                    
                    self.stopDrawing()
                    self.updateOnce()
                }
            })
        }
    }
    
    /// Updates the display once
    func updateOnce()
    {
        
        self.view.enableSetNeedsDisplay = true
        #if os(OSX)
        let nsrect : NSRect = NSRect(x:0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.setNeedsDisplay(nsrect)
        #else
        self.view.setNeedsDisplay()
        #endif
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
