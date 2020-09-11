//
//  Map.swift
//  Denrim
//
//  Created by Markus Moenig on 7/9/20.
//

import MetalKit
import JavaScriptCore

struct MapImage {
    
    var resourceName    : String
    var options         : [String:Any]
}

struct MapSequence {
    
    var resourceNames   : [String] = []
    var options         : [String:Any]
}

struct MapAlias {
    
    enum AliasType {
        case Image
    }
    
    var type            : AliasType
    var pointsTo        : String
    var options         : [String:Any]
}

struct MapLayer {

    var data            : [String] = []
    var options         : [String:Any]
    var endLine         : Int32 = 0
}

struct MapScene {

    var options         : [String:Any]
}

@objc protocol Map_JSExports: JSExport {
    
    static func compile(_ object: [AnyHashable:Any]) -> JSPromise

    func draw(_ object: [AnyHashable:Any])
}

class Map                   : NSObject, Map_JSExports
{
    var images              : [String:MapImage] = [:]
    var aliases             : [String:MapAlias] = [:]
    var sequences           : [String:MapSequence] = [:]
    var layers              : [String:MapLayer] = [:]
    var scenes              : [String:MapScene] = [:]

    var lines               : [Int32:String] = [:]
    
    var resources           : [String:Any] = [:]

    weak var game           : Game? = nil
    weak var texture        : Texture2D? = nil
    
    deinit {
        print("release map")
        clear()
        resources = [:]
    }
    
    override init()
    {
        super.init()
    }
    
    func clear()
    {
        images = [:]
        aliases = [:]
        layers = [:]
        scenes = [:]
        lines = [:]
    }
    
    class func compile(_ object: [AnyHashable:Any]) -> JSPromise
    {
        let context = JSContext.current()
        let promise = JSPromise()

        DispatchQueue.main.async {
            let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
            let game = main.game!
            
            if let mapName = object["name"] as? String {
             
                if let asset = game.assetFolder.getAsset(mapName, .Map) {
                    let error = game.mapBuilder.compile(asset)
                                        
                    if error.error == nil {
                        promise.success(value: asset.map!)
                    } else {
                        promise.fail(error: error.error!)
                    }
                } else {
                    promise.fail(error: "Map not found")
                }
            } else {
                promise.fail(error: "Map name not specified")
            }
        }
        
        return promise
    }
    
    func draw(_ object: [AnyHashable:Any])
    {
        let context = JSContext.current()
        let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
        game = main.game!
        
        if let sceneName = object["scene"] as? String {
            if let scene = scenes[sceneName] {
                drawScene(0, 0, scene)
            }
        }
    }
    
    func getImageResource(_ name: String) -> Texture2D?
    {
        if let texture = resources[name] as? Texture2D {
            return texture
        } else {
            let array = name.split(separator: ":")
            if array.count == 2 {
                if let asset = game?.assetFolder.getAssetById(UUID(uuidString: String(array[0]))!, .Image) {
                    if let index = Int(array[1]) {
                    
                        let data = asset.data[index]
                        
                        let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                        if let texture  = try? game!.textureLoader.newTexture(data: data, options: texOptions) {
                            let texture2D = Texture2D(game!, texture: texture)
                            resources[name] = texture2D
                            return texture2D
                        }
                    }
                }
            }
        }
        return nil
    }

    @discardableResult func drawAlias(_ x: Float,_ y: Float,_ alias: MapAlias, scale: Float = 1) -> (Float, Float)
    {
        var object : [AnyHashable : Any] = [:]
        var rc     : (Float, Float) = (0,0)

        if alias.type == .Image {
            if let image = images[alias.pointsTo] {
                
                if let texture2D = getImageResource(image.resourceName) {
                    var width = texture2D.width * scale
                    var height = texture2D.height * scale

                    object["x"] = x
                    object["y"] = y
                    object["width"] = width
                    object["height"] = height
                    object["texture"] = texture2D
                    
                    if let v = alias.options["rect"] as? Rect2D {
                        object["rect"] = v
                        width = v.width * scale
                        height = v.height * scale
                        
                        object["width"] = width
                        object["height"] = height
                    }
                
                    game?.texture?.drawTexture(object)

                    if let v = alias.options["repeatx"] as? Bool {
                        if v == true {
                            var posX : Float = x + width
                            while posX < game!.texture!.width {
                                object["x"] = posX
                                game?.texture?.drawTexture(object)
                                posX += width
                            }
                        }
                    }
                    
                    rc.0 = width
                    rc.1 = height
                }
            }
        }
        
        return rc
    }
    
    func drawLayer(_ x: Float,_ y: Float,_ layer: MapLayer, scale: Float = 1)
    {
        var xPos = x
        var yPos = y
        
        for line in layer.data {
            
            var index     : Int = 0
            var maxHeight : Float = 0
            
            while index < line.count - 1 {
                
                let a = String(line[line.index(line.startIndex, offsetBy: index)]) + String(line[line.index(line.startIndex, offsetBy: index+1)])
                if let alias = aliases[a] {
                    let advance = drawAlias(xPos, yPos, alias, scale: scale)
                    xPos += advance.0
                    if advance.1 > maxHeight {
                        maxHeight = advance.1
                    }
                }
                index += 2
            }
            
            yPos += maxHeight
            xPos = x
        }
    }
    
    func drawScene(_ x: Float,_ y: Float,_ scene: MapScene, scale: Float = 1)
    {
        if let sceneLayers = scene.options["layers"] as? [String] {
            for l in sceneLayers {
                if let layer = layers[l] {
                    
                    var layerOffX : Float = 0
                    var layerOffY : Float = 0
                    
                    if let sOff = layer.options["sceneoffset"] as? Vec2 {
                        layerOffX = sOff.x
                        layerOffY = sOff.y
                    }
                    drawLayer(x + layerOffX, y + layerOffY, layer, scale: scale)
                }
            }
        }
    }
}
