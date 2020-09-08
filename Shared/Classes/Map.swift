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

@objc protocol Map_JSExports: JSExport {
}

class Map                   : NSObject, Map_JSExports
{
    var images              : [String:MapImage] = [:]
    var aliases             : [String:MapAlias] = [:]
    var layers              : [String:MapLayer] = [:]

    var lines               : [Int32:String] = [:]

    weak var game           : Game? = nil
    weak var texture        : Texture2D? = nil
    
    deinit {
        images = [:]
        lines = [:]
        print("release map")
    }
    
    override init()
    {
        super.init()
    }
    
    func drawAlias(_ x: Float,_ y: Float,_ alias: MapAlias)
    {
        var object : [AnyHashable : Any] = [:]

        if alias.type == .Image {
            if let image = images[alias.pointsTo] {
                object["x"] = x
                object["y"] = y
                object["texture"] = image.texture2D
                
                game?.texture?.drawTexture(object)
            
                if let v = alias.options["repeatx"] as? Bool {
                    if v == true {
                        var posX : Float = x + image.texture2D.width
                        while posX < game!.texture!.width {
                            object["x"] = posX
                            game?.texture?.drawTexture(object)
                            posX += image.texture2D.width
                        }
                    }
                }
            }
        }
    }
    
    func drawLayer(_ x: Float,_ y: Float,_ layer: MapLayer)
    {
        for line in layer.data {
            
            var index : Int = 0
            
            while index < line.count - 1 {
                
                let a = String(line[line.index(line.startIndex, offsetBy: index)]) + String(line[line.index(line.startIndex, offsetBy: index+1)])
                if let alias = aliases[a] {
                    drawAlias(0, 0, alias)
                }
                index += 2
            }
        }
    }
}
