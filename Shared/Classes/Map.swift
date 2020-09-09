//
//  Map.swift
//  Denrim
//
//  Created by Markus Moenig on 7/9/20.
//

import MetalKit
import JavaScriptCore

struct MapImage {
    
    var texture2D   : Texture2D
    var options     : [String:Any]
}

struct MapAlias {
    
    enum AliasType {
        case Image
    }
    
    var type        : AliasType
    var pointsTo    : String
    var options     : [String:Any]
}

struct MapLayer {

    var data        : [String] = []
    var options     : [String:Any]
}

struct MapScene {

    var options     : [String:Any]
}

@objc protocol Map_JSExports: JSExport {
}

class Map                   : NSObject, Map_JSExports
{
    var images              : [String:MapImage] = [:]
    var aliases             : [String:MapAlias] = [:]
    var layers              : [String:MapLayer] = [:]
    var scenes              : [String:MapScene] = [:]

    var lines               : [Int32:String] = [:]

    weak var game           : Game? = nil
    weak var texture        : Texture2D? = nil
    
    deinit {
        images = [:]
        aliases = [:]
        layers = [:]
        scenes = [:]
        lines = [:]
        print("release map")
    }
    
    override init()
    {
        super.init()
    }
    
    @discardableResult func drawAlias(_ x: Float,_ y: Float,_ alias: MapAlias, scale: Float = 1) -> (Float, Float)
    {
        var object : [AnyHashable : Any] = [:]
        var rc     : (Float, Float) = (0,0)

        if alias.type == .Image {
            if let image = images[alias.pointsTo] {
                
                var width = image.texture2D.width * scale
                var height = image.texture2D.height * scale

                object["x"] = x
                object["y"] = y
                object["width"] = width
                object["height"] = height
                object["texture"] = image.texture2D
                
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
                    drawLayer(x, y, layer, scale: scale)
                }
            }
        }
    }
}
