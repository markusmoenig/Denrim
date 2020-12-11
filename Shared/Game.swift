//
//  Game.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import Combine
import AVFoundation

public class Game       : ObservableObject
{
    enum State {
        case Idle, Running, Paused
    }
    
    var state           : State = .Idle
    
    var view            : DMTKView!
    var device          : MTLDevice!

    var texture         : Texture2D? = nil
    var metalStates     : MetalStates!
    
    var viewportSize    : vector_uint2
    var scaleFactor     : Float
    
    var assetFolder     : AssetFolder!
    
    var screenWidth     : Float = 0
    var screenHeight    : Float = 0

    var gameCmdQueue    : MTLCommandQueue? = nil
    var gameCmdBuffer   : MTLCommandBuffer? = nil
    var gameScissorRect : MTLScissorRect? = nil
    
    var scriptEditor    : ScriptEditor? = nil
    var file            : File? = nil

    var mapBuilder      : MapBuilder!
    var behaviorBuilder : BehaviorBuilder!
    var shaderCompiler  : ShaderCompiler!

    var textureLoader   : MTKTextureLoader!
        
    var resources       : [AnyObject] = []
    var availableFonts  : [String] = ["OpenSans", "Square", "SourceCodePro"]
    var fonts           : [Font] = []
    
    var _Time           = Float1(0)
    var _Aspect          = Float2(1,1)
    var targetFPS       : Float = 60
    
    var gameAsset       : Asset? = nil
    
    var currentMap      : Asset? = nil
    var currentScene    : MapScene? = nil
    
    var nearestSampler  : MTLSamplerState!
    var linearSampler   : MTLSamplerState!

    // Preview Size, UI only
    var previewFactor   : CGFloat = 4
    var previewOpacity  : Double = 0.5
    
    var contextText     : String = ""
    var contextKey      : String = ""
    let contextTextChanged = PassthroughSubject<String, Never>()
    
    var helpText        : String = ""
    let helpTextChanged = PassthroughSubject<Void, Never>()
    
    var tempText        : String = ""
    let tempTextChanged = PassthroughSubject<Void, Never>()

    var assetError      = CompileError()
    let gameError       = PassthroughSubject<Void, Never>()
    
    var localAudioPlayers: [String:AVAudioPlayer] = [:]
    var globalAudioPlayers: [String:AVAudioPlayer] = [:]
    
    var showingDebugInfo: Bool = false
    
    var frameworkId     : String? = nil

    public init(_ frameworkId: String? = nil)
    {
        self.frameworkId = frameworkId
        
        viewportSize = vector_uint2( 0, 0 )
        
        #if os(OSX)
        scaleFactor = Float(NSScreen.main!.backingScaleFactor)
        #else
        scaleFactor = Float(UIScreen.main.scale)
        #endif
        
        file = File()
        
        assetFolder = AssetFolder()
        assetFolder.setup(self)
        
        mapBuilder = MapBuilder(self)
        behaviorBuilder = BehaviorBuilder(self)
        shaderCompiler = ShaderCompiler(self)
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
        #endif
    }
    
    public func setupView(_ view: DMTKView)
    {
        self.view = view
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            device = metalDevice
            if frameworkId != nil {
                view.device = device
            }
        } else {
            print("Cannot initialize Metal!")
        }
        view.game = self
        
        metalStates = MetalStates(self)
        textureLoader = MTKTextureLoader(device: device)
        
        for fontName in availableFonts {
            let font = Font(name: fontName, game: self)
            fonts.append(font)
        }
        
        var descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .nearest
        descriptor.magFilter = .nearest
        nearestSampler = device.makeSamplerState(descriptor: descriptor)
        
        descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        linearSampler = device.makeSamplerState(descriptor: descriptor)
        
        view.platformInit()
        checkTexture()
    }
    
    public func load(_ data: Data)
    {
        if let folder = try? JSONDecoder().decode(AssetFolder.self, from: data) {
            assetFolder = folder
        }
    }
    
    public func start()
    {
        if let scriptEditor = scriptEditor {
            scriptEditor.setReadOnly(true)
            
            contextText = ""
            contextTextChanged.send(contextText)
        }
        
        clearLocalAudio()
        clearGlobalAudio()
        
        view.reset()
        
        assetError.error = nil
        state = .Running
        
        _Aspect.x = 1
        _Aspect.y = 1

        var hasError: Bool = false
        for asset in assetFolder.assets {
            if asset.type == .Behavior {
             
                if asset.name == "Game" {
                    
                    gameAsset = asset

                    // Compile and "init" the game behavior (and only the game behavior)
                    let error = behaviorBuilder.compile(asset)
                    if error.error != nil {
                        hasError = true
                        break
                    } else {
                        
                        if let context = gameAsset?.behavior {
                            context.execute(name: "init")
                        }
                    }
                }
            }
        }

        if !hasError && assetError.error == nil {
            state = .Running
            view.enableSetNeedsDisplay = false
            view.isPaused = false
            
            _Time.x = 0
            targetFPS = 60
            view.preferredFramesPerSecond = Int(targetFPS)
        } else {
            stop()
        }
    }
    
    func stop()
    {
        clearLocalAudio()
        clearGlobalAudio()
        
        if let map = currentMap?.map {
            map.clear()
        }
        
        if let scriptEditor = scriptEditor {
            scriptEditor.setReadOnly(false)
            scriptEditor.setDebugText(text: "The game engine will display debug information during runtime here.")
        }
        
        gameAsset = nil
        currentScene = nil
        currentMap = nil
        
        state = .Idle
        view.isPaused = true
        
        if let scriptEditor = scriptEditor, assetError.error == nil {
            scriptEditor.clearAnnotations()
            if assetFolder.current != nil {
                assetFolder.select(assetFolder.current!.id)
            }
        }
    }
    
    @discardableResult func checkTexture() -> Bool
    {
        if texture == nil || texture!.texture.width != Int(view.frame.width) || texture!.texture.height != Int(view.frame.height) {
            
            if texture == nil {
                texture = Texture2D(self)
            } else {
                texture?.allocateTexture(width: Int(view.frame.width), height: Int(view.frame.height))
            }
            
            viewportSize.x = UInt32(texture!.width)
            viewportSize.y = UInt32(texture!.height)
            
            screenWidth = Float(texture!.width)
            screenHeight = Float(texture!.height)
            
            gameScissorRect = MTLScissorRect(x: 0, y: 0, width: texture!.texture.width, height: texture!.texture.height)
                        
            if let map = currentMap?.map {
                map.setup(game: self)
            }
            return true
        }
        return false
    }
    
    public func draw()
    {
        _Time.x += 1.0 / targetFPS

        if checkTexture() && state == .Idle {
            // We need to update the screen
            if assetFolder.current?.type == .Map && assetFolder.current?.map != nil {
                if let mapBuilder = mapBuilder {
                    mapBuilder.createPreview(assetFolder.current!.map!)
                }
            } else {
                startDrawing()
                texture?.clear()
                stopDrawing()
                if let asset = assetFolder.current {
                    createPreview(asset)
                }
            }
        }
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        startDrawing()

        // Game Loop
        if state == .Running {
            
            gameCmdBuffer?.addCompletedHandler { cb in
//                print("GPU Time:", (cb.gpuEndTime - cb.gpuStartTime) * 1000)
            }
            
//            #if DEBUG
//            let startTime = Double(Date().timeIntervalSince1970)
//            #endif

            //texture?.clear()

            if let context = gameAsset?.behavior {
                context.execute(name: "update")
            }
            
            if let mapAsset = self.currentMap {
                if let map = mapAsset.map {
                    for (_, b) in map.behavior {
                        if let instances = b.instances {
                            for inst in instances.pairs {
                                if let context = inst.1.behaviorAsset.behavior {
                                    context.execute(name: "update")
                                }
                            }
                        } else {
                            if let context = b.behaviorAsset.behavior {
                                context.execute(name: "update")
                            }
                        }
                    }
                    if let scene = self.currentScene {
                        map.drawScene(0, 0, scene)
                    }
                }
            }
        
            // Display failures when have editor
            if let asset = assetFolder.current, scriptEditor != nil {
                var error = CompileError()
                error.error = ""
                error.column = 0
                if let context = asset.behavior {
                    scriptEditor?.clearAnnotations()
                    scriptEditor?.setFailures(context.failedAt)
                }
            }

//            #if DEBUG
//            print("Behavior Time: ", (Double(Date().timeIntervalSince1970) - startTime) * 1000)
//            #endif
        }
                
        let renderPassDescriptor = view.currentRenderPassDescriptor
        renderPassDescriptor?.colorAttachments[0].loadAction = .load
        let renderEncoder = gameCmdBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        
        drawTexture(renderEncoder: renderEncoder!)
        renderEncoder?.endEncoding()
        
        gameCmdBuffer?.present(drawable)
        stopDrawing()
        
        // Debug ?
        if showingDebugInfo && state == .Running {
            var debugText = ""
            
            if let map = currentMap?.map {
            
                debugText += "Current Map: \(currentMap!.name)\n"
                
                if let scene = currentScene {
                    debugText += "Current Scene: \(scene.name)\n\n"
                }

                for (physicsName, physics2D) in map.physics2D {
                    debugText += physicsName + "\n"
                    if let world = physics2D.world {
                        debugText += "  Bodies in world: \(world.bodyCount)\n"
                        debugText += "  Current contacts: \(world.contactCount)\n"
                    }
                }
            }
            
            scriptEditor!.setDebugText(text: debugText)
        }
    }
    
    func startDrawing()
    {
        if gameCmdQueue == nil {
            gameCmdQueue = view.device!.makeCommandQueue()
        }
        gameCmdBuffer = gameCmdQueue!.makeCommandBuffer()
    }
    
    func stopDrawing(deleteQueue: Bool = false)
    {
        gameCmdBuffer?.commit()

        if deleteQueue {
            self.gameCmdQueue = nil
        }
        self.gameCmdBuffer = nil
    }
    
    /// Create a preview for the current asset
    func createPreview(_ asset: Asset)
    {
        if state == .Idle {
            clearLocalAudio()
            if asset.type == .Shader {
                if let shader = asset.shader {
                    startDrawing()
                    
                    let rect = MMRect( 0, 0, self.texture!.width, self.texture!.height, scale: 1 )
                    texture?.clear()
                    texture?.drawShader(shader, rect)
                    
                    stopDrawing()
                    updateOnce()
                }
            } else
            if asset.type == .Audio {
                
                do {
                    let player = try AVAudioPlayer(data: asset.data[0])
                    localAudioPlayers[asset.name] = player
                    player.play()
                } catch let error {
                    print(error.localizedDescription)
                }
            } else if asset.type == .Image {
                if asset.dataIndex < asset.data.count {
                
                    let data = asset.data[asset.dataIndex]
                    
                    let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                    if let texture  = try? textureLoader.newTexture(data: data, options: texOptions) {
                        let texture2D = Texture2D(self, texture: texture)
                        
                        self.startDrawing()
                        var options : [String:Any] = [:]
                        options["texture"] = texture2D
                        
                        let width : Float = texture2D.width * Float(asset.dataScale)
                        let height : Float = texture2D.height * Float(asset.dataScale)

                        options["width"] = width
                        options["height"] = height

                        self.texture?.clear()
                        self.texture?.drawTexture(options)
                        self.stopDrawing()
                        self.updateOnce()
                                                                        
                        if let scriptEditor = self.scriptEditor {
                            let text = """

                            Displaying image group \(asset.name) index \(asset.dataIndex) of \(asset.data.count)
                            
                            Image resolution \(Int(texture2D.width))x\(Int(texture2D.height))

                            Preview resolution \(Int(width))x\(Int(height))

                            Scale \(String(format: "%.02f", asset.dataScale))

                            """
                            scriptEditor.setAssetValue(asset, value: text)
                        }
                    }
                }
            }
        }
    }
    
    /// Clears all local audio
    func clearLocalAudio()
    {
        for (_, a) in localAudioPlayers {
            a.stop()
        }
        localAudioPlayers = [:]
    }
    
    /// Clears all global audio
    func clearGlobalAudio()
    {
        for (_, a) in globalAudioPlayers {
            a.stop()
        }
        globalAudioPlayers = [:]
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
        let left: Float  = -texture.width / 2.0 + rect.x
        let right: Float = left + rect.width//self.width / 2 - x
        
        let top: Float = texture.height / 2.0 - rect.y
        let bottom: Float = top - rect.height

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
