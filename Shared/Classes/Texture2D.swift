//
//  Texture2D.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import JavaScriptCore

// Protocol must be declared with `@objc`
@objc protocol Texture2D_JSExports: JSExport {
    var width: Float { get }
    var height: Float { get }

    static func main() -> Texture2D
    static func createFromImage(_ object: [AnyHashable:Any]) -> Texture2D

    func clear(_ color: Any)
    func drawDisks(_ array: NSArray)
    func drawBoxes(_ array: NSArray)
    func drawTextures(_ array: NSArray)

    // Imported as `Person.createWithFirstNameLastName(_:_:)`
    //static func createWith(firstName: String, lastName: String) -> Person
}

class Texture2D                 : NSObject, Texture2D_JSExports
{
    var texture                 : MTLTexture!
    
    var width                   : Float = 0
    var height                  : Float = 0
    
    var game                    : Game!

    ///
    init(_ game: Game)
    {
        self.game = game
        
        super.init()
        allocateTexture(width: Int(game.view.frame.width), height: Int(game.view.frame.height))
    }
    
    init(_ game: Game, width: Int, height: Int)
    {
        self.game = game
        
        super.init()
        allocateTexture(width: width, height: height)
    }
    
    init(_ game: Game, texture: MTLTexture)
    {
        self.game = game
        self.texture = texture
        
        width = Float(texture.width)
        height = Float(texture.height)
                        
        super.init()
    }
    
    deinit
    {
        if texture != nil {
            texture!.setPurgeableState(.empty)
            texture = nil
        }
    }
    
    func allocateTexture(width: Int, height: Int)
    {
        if texture != nil {
            texture!.setPurgeableState(.empty)
            texture = nil
        }
            
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        
        self.width = Float(width)
        self.height = Float(height)
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        
        texture = game.device.makeTexture(descriptor: textureDescriptor)
    }
    
    class func main() -> Texture2D
    {
        let context = JSContext.current()
        let main = context?.objectForKeyedSubscript("__mainTexture")?.toObject() as! Texture2D
        
        return main
    }
    
    class func createFromImage(_ object: [AnyHashable:Any]) -> Texture2D
    {
        let context = JSContext.current()
        
        let main = context?.objectForKeyedSubscript("__mainTexture")?.toObject() as! Texture2D
        var texture : Texture2D? = nil
        let game = main.game!
        
        if let imageName = object["image"] as? String {
         
            if let asset = game.assetFolder.getAsset(imageName, .Image) {
                let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : false]

                if let mtlTexture = try? game.textureLoader.newTexture(data: asset.data[0], options: options) {
                    texture = Texture2D(game, texture: mtlTexture)
                }
            }
        }
        
        if texture == nil {
            texture = Texture2D(main.game, width: 10, height: 10)
        }
        
        return texture!
    }
    
    func clear(_ color: Any)
    {
        let color : SIMD4<Float> = color as? Color == nil ? SIMD4<Float>(0,0,0,0) : (color as! Color).toSIMD()

        let renderPassDescriptor = MTLRenderPassDescriptor()

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.x), Double(color.y), Double(color.z), Double(color.w))
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
    
    func drawDisks(_ array: NSArray)
    {
        for jsvalue in array {
            
            if let object = jsvalue as? [AnyHashable : Any] {
                
                var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
                var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
                let radius : Float; if let v = object["radius"] as? Float { radius = v } else { radius = 0 }
                let border : Float; if let v = object["border"] as? Float { border = v } else { border = 0 }
                let onion : Float;  if let v = object["onion"] as? Float { onion = v } else { onion = 0 }
                let fillColor : SIMD4<Float>; if let v = object["color"] as? Color { fillColor = v.toSIMD() } else { fillColor = SIMD4<Float>(1,1,1,1) }
                let borderColor : SIMD4<Float>; if let v = object["borderColor"] as? Color { borderColor = v.toSIMD() } else { borderColor = SIMD4<Float>(0,0,0,0) }

                x /= game.scaleFactor
                y /= game.scaleFactor
                
                var data = DiscUniform()
                data.borderSize = border / game.scaleFactor
                data.radius = radius / game.scaleFactor
                data.fillColor = fillColor
                data.borderColor = borderColor
                data.onion = onion / game.scaleFactor

                let rect = MMRect(x - data.borderSize / 2, y - data.borderSize / 2, data.radius * 2 + data.borderSize * 2, data.radius * 2 + data.borderSize * 2, scale: game.scaleFactor )
                let vertexData = game.createVertexData(texture: self, rect: rect)
                
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = texture
                renderPassDescriptor.colorAttachments[0].loadAction = .load
                
                let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                        
                renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
                renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
                
                renderEncoder.setFragmentBytes(&data, length: MemoryLayout<DiscUniform>.stride, index: 0)
                renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawDisc))
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                renderEncoder.endEncoding()
            }
        }
    }
    
    func drawBoxes(_ array: NSArray)
    {
        for jsvalue in array {
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .load
            
            let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            
            if let object = jsvalue as? [AnyHashable : Any] {
                                
                var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
                var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
                let width : Float; if let v = object["width"] as? Float { width = v } else { width = 1 }
                let height : Float; if let v = object["height"] as? Float { height = v } else { height = 1 }
                let round : Float; if let v = object["round"] as? Float { round = v } else { round = 0 }
                let border : Float; if let v = object["border"] as? Float { border = v } else { border = 0 }
                let rotation : Float; if let v = object["rotation"] as? Float { rotation = v } else { rotation = 0 }
                let onion : Float;  if let v = object["onion"] as? Float { onion = v } else { onion = 0 }
                let fillColor : SIMD4<Float>; if let v = object["color"] as? Color { fillColor = v.toSIMD() } else { fillColor = SIMD4<Float>(1,1,1,1) }
                let borderColor : SIMD4<Float>; if let v = object["borderColor"] as? Color { borderColor = v.toSIMD() } else { borderColor = SIMD4<Float>(0,0,0,0) }
                
                x /= game.scaleFactor
                y /= game.scaleFactor

                var data = BoxUniform()
                data.onion = onion / game.scaleFactor
                data.size = float2(width / game.scaleFactor, height / game.scaleFactor)
                data.round = round / game.scaleFactor
                data.borderSize = border / game.scaleFactor
                data.fillColor = fillColor
                data.borderColor = borderColor
                
                if rotation == 0 {
                    let rect = MMRect(x, y, data.size.x, data.size.y, scale: game.scaleFactor)
                    let vertexData = game.createVertexData(texture: self, rect: rect)
                                                
                    renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
                    renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
                    
                    renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
                    renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBox))
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                } else {
                    data.pos.x = x
                    data.pos.y = y
                    data.rotation = rotation.degreesToRadians
                    data.screenSize = float2(self.width / game.scaleFactor, self.height / game.scaleFactor)

                    let rect = MMRect(0, 0, self.width / game.scaleFactor, self.height / game.scaleFactor, scale: game.scaleFactor)
                    let vertexData = game.createVertexData(texture: self, rect: rect)
                                                
                    renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
                    renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
                    
                    renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
                    renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBoxExt))
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                }
            }
            renderEncoder.endEncoding()
        }
    }
    
    func drawTextures(_ array: NSArray)
    {
        for jsvalue in array {
            
            if let object = jsvalue as? [AnyHashable : Any] {
                        
                if let sourceTexture = object["texture"] as? Texture2D {
                    
                    var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
                    var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
                    var width : Float; if let v = object["width"] as? Float { width = v } else { width = Float(sourceTexture.width) }
                    var height : Float; if let v = object["height"] as? Float { height = v } else { height = Float(sourceTexture.height) }
                    let alpha : Float; if let v = object["alpha"] as? Float { alpha = v } else { alpha = 1.0 }
                    
                    let subRect : Rect2D?; if let v = object["subRect"] as? Rect2D { subRect = v } else { subRect = nil }

                    x /= game.scaleFactor
                    y /= game.scaleFactor
                    
                    width /= game.scaleFactor
                    height /= game.scaleFactor
                    
                    var data = TextureUniform()
                    data.globalAlpha = alpha
                    
                    if let subRect = subRect {
                        data.pos.x = subRect.x / sourceTexture.width
                        data.pos.y = subRect.y / sourceTexture.height
                        data.size.x = subRect.width / sourceTexture.width// / game.scaleFactor
                        data.size.y = subRect.height / sourceTexture.height// / game.scaleFactor
                    } else {
                        data.pos.x = 0
                        data.pos.y = 0
                        data.size.x = 1
                        data.size.y = 1
                    }
                            
                    let rect = MMRect( x, y, width, height, scale: game.scaleFactor )
                    let vertexData = game.createVertexData(texture: self, rect: rect)
                    
                    let renderPassDescriptor = MTLRenderPassDescriptor()
                    renderPassDescriptor.colorAttachments[0].texture = texture
                    renderPassDescriptor.colorAttachments[0].loadAction = .load
                    
                    let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

                    renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
                    renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
                    
                    renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextureUniform>.stride, index: 0)
                    renderEncoder.setFragmentTexture(sourceTexture.texture, index: 1)

                    renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawTexture))
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                    renderEncoder.endEncoding()
                }
            }
        }
    }
}
