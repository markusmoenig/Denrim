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
    func drawDisk(_ object: [AnyHashable:Any])
    func drawBox(_ object: [AnyHashable:Any])
    func drawTexture(_ object: [AnyHashable:Any])

    // Imported as `Person.createWithFirstNameLastName(_:_:)`
    //static func createWith(firstName: String, lastName: String) -> Person
}

class Texture2D         : NSObject, Texture2D_JSExports
{
    var texture         : MTLTexture!
    
    var width           : Float = 0
    var height          : Float = 0
    
    var game            : Game!

    ///
    init(_ game: Game)
    {
        self.game = game
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = Int(game.view.frame.width)
        textureDescriptor.height = Int(game.view.frame.height)
        
        width = Float(textureDescriptor.width)
        height = Float(textureDescriptor.height)
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        
        texture = game.device.makeTexture(descriptor: textureDescriptor)
        
        super.init()
    }
    
    init(_ game: Game, width: Int, height: Int)
    {
        self.game = game
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.width = width
        textureDescriptor.height = height
        
        self.width = Float(width)
        self.height = Float(height)
        
        textureDescriptor.usage = MTLTextureUsage.unknown
        
        texture = game.device.makeTexture(descriptor: textureDescriptor)
        
        super.init()
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
            print("dealloc", width, height)
        }
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
    
    func drawDisk(_ object: [AnyHashable:Any])
    {
        var x : Float = object["x"] == nil || object["x"] as? Float == nil ? 0 : object["x"] as! Float
        var y : Float = object["y"] == nil || object["y"] as? Float == nil ? 0 : object["y"] as! Float
        let radius : Float = object["radius"] == nil || object["radius"] as? Float == nil ? 0 : object["radius"] as! Float
        let border : Float = object["border"] == nil || object["border"] as? Float == nil ? 0 : object["border"] as! Float
        let fillColor : SIMD4<Float> = object["color"] == nil || object["color"] as? Color == nil ? SIMD4<Float>(1,1,1,1) : (object["color"] as! Color).toSIMD()
        let borderColor : SIMD4<Float> = object["borderColor"] == nil || object["borderColor"] as? Color == nil ? SIMD4<Float>(0,0,0,0) : (object["borderColor"] as! Color).toSIMD()
        
        x /= game.scaleFactor
        y /= game.scaleFactor
        
        var data = DiscUniform()
        data.borderSize = border / game.scaleFactor
        data.radius = radius / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor

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
    
    func drawBox(_ object: [AnyHashable:Any])
    {
        var x : Float = object["x"] == nil || object["x"] as? Float == nil ? 0 : object["x"] as! Float
        var y : Float = object["y"] == nil || object["y"] as? Float == nil ? 0 : object["y"] as! Float
        let width : Float = object["width"] == nil || object["width"] as? Float == nil ? 1 : object["width"] as! Float
        let height : Float = object["height"] == nil || object["height"] as? Float == nil ? 1 : object["height"] as! Float
        let round : Float = object["round"] == nil || object["round"] as? Float == nil ? 0 : object["round"] as! Float
        let border : Float = object["border"] == nil || object["border"] as? Float == nil ? 0 : object["border"] as! Float
        let rotation : Float = object["rotation"] == nil || object["rotation"] as? Float == nil ? 0 : object["rotation"] as! Float
        let fillColor : SIMD4<Float> = object["color"] == nil || object["color"] as? Color == nil ? SIMD4<Float>(1,1,1,1) : (object["color"] as! Color).toSIMD()
        let borderColor : SIMD4<Float> = object["borderColor"] == nil || object["borderColor"] as? Color == nil ? SIMD4<Float>(0,0,0,0) : (object["borderColor"] as! Color).toSIMD()
        
        x /= game.scaleFactor
        y /= game.scaleFactor

        var data = BoxUniform()
        data.size = float2(width / game.scaleFactor, height / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        if rotation == 0 {
            data.rotation = rotation.degreesToRadians

            let rect = MMRect(x - data.borderSize / 2, y - data.borderSize, data.size.x + data.borderSize, data.size.y + data.borderSize, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: self, rect: rect)
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .load
            
            let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                    
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            
            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBox))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
        }
    }
    
    func drawTexture(_ object: [AnyHashable:Any])
    {
        if let sourceTexture = object["texture"] as? Texture2D {
            
            var x : Float = object["x"] == nil || object["x"] as? Float == nil ? 0 : object["x"] as! Float
            var y : Float = object["y"] == nil || object["y"] as? Float == nil ? 0 : object["y"] as! Float
            var width : Float = object["width"] == nil || object["width"] as? Float == nil ? Float(sourceTexture.width) : object["width"] as! Float
            var height : Float = object["height"] == nil || object["height"] as? Float == nil ? Float(sourceTexture.height) : object["height"] as! Float
            let alpha : Float = object["alpha"] == nil || object["alpha"] as? Float == nil ? 1.0 : object["alpha"] as! Float

            x /= game.scaleFactor
            y /= game.scaleFactor
            
            width /= game.scaleFactor
            height /= game.scaleFactor
            
            var data = TextureUniform()
            data.globalAlpha = alpha
                    
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
