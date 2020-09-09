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
    static func createFromImage(_ object: [AnyHashable:Any]) -> JSPromise

    func clear(_ color: Any)
    
    func drawDisk(_ object: [AnyHashable : Any])
    func drawDisks(_ array: NSArray)
    
    func drawBox(_ object: [AnyHashable : Any])
    func drawBoxes(_ array: NSArray)
    
    func drawTexture(_ object: [AnyHashable : Any])
    func drawTextures(_ array: NSArray)
    
    func drawShader(_ object: [AnyHashable:Any])
    func drawText(_ object: [AnyHashable:Any])// -> TextBuffer


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
        print("release texture")
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
        let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
        
        return main
    }
    
    class func createFromImage(_ object: [AnyHashable:Any]) -> JSPromise
    {
        let context = JSContext.current()
        let promise = JSPromise()

        DispatchQueue.main.async {
            let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
            var texture : Texture2D? = nil
            let game = main.game!
            
            if let imageName = object["name"] as? String {
             
                if let asset = game.assetFolder.getAsset(imageName, .Image) {
                    let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : false]

                    if let mtlTexture = try? game.textureLoader.newTexture(data: asset.data[0], options: options) {
                        texture = Texture2D(game, texture: mtlTexture)
                        promise.success(value: texture)
                    } else {
                        promise.fail(error: "Image cannot be decoded")
                    }
                } else {
                    promise.fail(error: "Image not found")
                }
            } else {
                promise.fail(error: "Image name not specified")
            }
            
            if texture == nil {
                texture = Texture2D(main.game, width: 10, height: 10)
            }
        }
        
        return promise
    }
    
    func clear(_ color: Any)
    {
        let color : SIMD4<Float> = color as? Vec4 == nil ? SIMD4<Float>(0,0,0,1) : (color as! Vec4).toSIMD()

        let renderPassDescriptor = MTLRenderPassDescriptor()

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(Double(color.x), Double(color.y), Double(color.z), Double(color.w))
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.endEncoding()
    }
    
    func drawChecker()
    {
        var x : Float = 0
        var y : Float = 0
        let width : Float = self.width * game.scaleFactor
        let height : Float = self.height * game.scaleFactor
        let round : Float = 0
        let border : Float = 0
        let rotation : Float = 0
        let onion : Float = 0
        let fillColor : SIMD4<Float> = SIMD4<Float>(0.306, 0.310, 0.314, 1.000)
        let borderColor : SIMD4<Float> = SIMD4<Float>(0.216, 0.220, 0.224, 1.000)

        x /= game.scaleFactor
        y /= game.scaleFactor

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(width / game.scaleFactor, height / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        data.pos.x = x
        data.pos.y = y
        data.rotation = rotation.degreesToRadians
        data.screenSize = float2(self.width / game.scaleFactor, self.height / game.scaleFactor)

        let rect = MMRect(0, 0, self.width / game.scaleFactor, self.height / game.scaleFactor, scale: game.scaleFactor)
        let vertexData = game.createVertexData(texture: self, rect: rect)
                                
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBackPattern))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        
        renderEncoder.endEncoding()
    }
    
    func drawDisk(_ object: [AnyHashable : Any])
    {
        var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
        var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
        let radius : Float; if let v = object["radius"] as? Float { radius = v } else { radius = 100 }
        let border : Float; if let v = object["border"] as? Float { border = v } else { border = 0 }
        let onion : Float;  if let v = object["onion"] as? Float { onion = v } else { onion = 0 }
        let fillColor : SIMD4<Float>; if let v = object["color"] as? Vec4 { fillColor = v.toSIMD() } else { fillColor = SIMD4<Float>(1,1,1,1) }
        let borderColor : SIMD4<Float>; if let v = object["borderColor"] as? Vec4 { borderColor = v.toSIMD() } else { borderColor = SIMD4<Float>(0,0,0,0) }
        
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
    
    func drawDisks(_ array: NSArray)
    {
        for jsvalue in array {
            
            if let object = jsvalue as? [AnyHashable : Any] {
                drawDisk(object)
            }
        }
    }
    
    func drawBox(_ object: [AnyHashable : Any])
    {
        var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
        var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
        let width : Float; if let v = object["width"] as? Float { width = v } else { width = 1 }
        let height : Float; if let v = object["height"] as? Float { height = v } else { height = 1 }
        let round : Float; if let v = object["round"] as? Float { round = v } else { round = 0 }
        let border : Float; if let v = object["border"] as? Float { border = v } else { border = 0 }
        let rotation : Float; if let v = object["rotation"] as? Float { rotation = v } else { rotation = 0 }
        let onion : Float;  if let v = object["onion"] as? Float { onion = v } else { onion = 0 }
        let fillColor : SIMD4<Float>; if let v = object["color"] as? Vec4 { fillColor = v.toSIMD() } else { fillColor = SIMD4<Float>(1,1,1,1) }
        let borderColor : SIMD4<Float>; if let v = object["borderColor"] as? Vec4 { borderColor = v.toSIMD() } else { borderColor = SIMD4<Float>(0,0,0,0) }

        x /= game.scaleFactor
        y /= game.scaleFactor

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(width / game.scaleFactor, height / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

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
        renderEncoder.endEncoding()
    }
    
    func drawBoxes(_ array: NSArray)
    {
        for jsvalue in array {
            
            if let object = jsvalue as? [AnyHashable : Any] {
                drawBox(object)
            }
        }
    }
    
    func drawTexture(_ object: [AnyHashable : Any])
    {
        if let sourceTexture = object["texture"] as? Texture2D {
            
            var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
            var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
            var width : Float; if let v = object["width"] as? Float { width = v } else { width = Float(sourceTexture.width) }
            var height : Float; if let v = object["height"] as? Float { height = v } else { height = Float(sourceTexture.height) }
            let alpha : Float; if let v = object["alpha"] as? Float { alpha = v } else { alpha = 1.0 }
            
            let subRect : Rect2D?; if let v = object["rect"] as? Rect2D { subRect = v } else { subRect = nil }

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
    
    func drawTextures(_ array: NSArray)
    {
        for jsvalue in array {
            
            if let object = jsvalue as? [AnyHashable : Any] {
                drawTexture(object)
            }
        }
    }
    
    func drawShader(_ shader: Shader, _ rect: MMRect)
    {
        let vertexData = game.createVertexData(texture: self, rect: rect)
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        renderEncoder.setRenderPipelineState(shader.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
    }
    
    func drawShader(_ object: [AnyHashable:Any])
    {
        if let shader = object["shader"] as? Shader, shader.isValid {
            
            let subRect : Rect2D?; if let v = object["subRect"] as? Rect2D { subRect = v } else { subRect = nil }
            
            let rect : MMRect

            if let subRect = subRect {
                rect = MMRect(subRect.x, subRect.y, subRect.width, subRect.height, scale: 1)
            } else {
                rect = MMRect( 0, 0, self.width, self.height, scale: game.scaleFactor )
            }
            
            drawShader(shader, rect)
        }
    }
    
    /// Draws the given text
    func drawText(_ object: [AnyHashable:Any])
    {
        var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
        var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
        let size : Float; if let v = object["size"] as? Float { size = v } else { size = 30 }
        let text : String; if let v = object["text"] as? String { text = v } else { text = "" }
        let font : Font?; if let v = object["font"] as? Font { font = v } else { font = nil }
        let color : SIMD4<Float>; if let v = object["color"] as? Vec4 { color = v.toSIMD() } else { color = SIMD4<Float>(1,1,1,1) }

        let scaleFactor : Float = game.scaleFactor
        
        func drawChar(char: BMChar, x: Float, y: Float, adjScale: Float)
        {
            var data = TextUniform()
            
            data.atlasSize.x = Float(font!.atlas!.width) * scaleFactor
            data.atlasSize.y = Float(font!.atlas!.height) * scaleFactor
            data.fontPos.x = char.x * scaleFactor
            data.fontPos.y = char.y * scaleFactor
            data.fontSize.x = char.width * scaleFactor
            data.fontSize.y = char.height * scaleFactor
            data.color = color

            let rect = MMRect(x, y, char.width * adjScale, char.height * adjScale, scale: scaleFactor)
            let vertexData = game.createVertexData(texture: self, rect: rect)
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .load
            
            let renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(font!.atlas, index: 1)

            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawTextChar))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder.endEncoding()
        }
        
        if let font = font {
         
            let scale : Float = (1.0 / font.bmFont!.common.lineHeight) * size
            let adjScale : Float = scale// / 2
            
            var posX = x / game.scaleFactor
            let posY = y / game.scaleFactor

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    drawChar(char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: posY + bmChar!.yoffset * adjScale, adjScale: adjScale)
                    posX += bmChar!.xadvance * adjScale;
                }
            }
        }
    }
}
