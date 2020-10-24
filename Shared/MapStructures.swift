//
//  MapStructures.swift
//  Denrim
//
//  Created by Markus Moenig on 22/9/20.
//

import Foundation

struct MapImage {
    
    var resourceName    : String
    var options         : [String:Any]
}

struct MapSequence {
    
    var resourceNames   : [String] = []
    var options         : [String:Any]
}

struct MapAliasData2D {

    var position        : Float2
    var width           = Float1(0)
    var height          = Float1(0)

    var rect            : Rect2D? = nil
    var texture         : Texture2D? = nil

    init(_ options: [String:Any])
    {
        if let position = options["position"] as? Float2 {
            self.position = position
        } else {
            self.position = Float2(0,0)
        }
        
        if let rect = options["rect"] as? Rect2D {
            self.rect = rect
        } else {
            self.rect = nil
        }
    }
}

struct MapAlias {
    
    enum AliasType {
        case Image
    }
    
    var type            : AliasType
    var pointsTo        : String
    var originalOptions : [String:Any]
    
    var options         : MapAliasData2D
}

struct MapLayer {

    var data            : [String] = []
    var options         : [String:Any]
    var endLine         : Int32 = 0
}

struct MapBehavior {
    var behaviorAsset   : Asset
    
    var name            : String = ""
    var options         : [String:Any]
    
    var instances       : MapInstance2D? = nil
}

struct MapFixture2D {
    var options         : [String:Any]
}

struct MapShapeData2D {

    var position        : Float2
    var size            : Float2

    var rotation        : Float1
    var round           : Float1

    var border          : Float1
    var radius          : Float1
    var onion           : Float1
    
    var visible         : Bool1
    
    var color           : Float4
    var borderColor     : Float4
    
    var text            : TextRef
    
    init(_ options: [String:Any])
    {
        if let position = options["position"] as? Float2 {
            self.position = position
        } else {
            self.position = Float2(0,0)
        }
        
        if let size = options["size"] as? Float2 {
            self.size = size
        } else {
            self.size = Float2(1,1)
        }
        
        if let visible = options["visible"] as? Bool1 {
            self.visible = visible
        } else {
            self.visible = Bool1(true)
        }
        
        if let rotation = options["rotation"] as? Float1 {
            self.rotation = rotation
        } else {
            self.rotation = Float1(0)
        }
        
        if let round = options["round"] as? Float1 {
            self.round = round
        } else {
            self.round = Float1(0)
        }
        
        if let border = options["border"] as? Float1 {
            self.border = border
        } else {
            self.border = Float1(0)
        }
        
        if let radius = options["radius"] as? Float1 {
            self.radius = radius
            self.size.x = radius.x * 2.0
            self.size.y = radius.x * 2.0
        } else {
            self.radius = Float1(1)
        }
        
        if let onion = options["onion"] as? Float1 {
            self.onion = onion
        } else {
            self.onion = Float1(0)
        }
        
        if let color = options["color"] as? Float4 {
            self.color = color
        } else {
            self.color = Float4(1,1,1,1)
        }
        
        if let borderColor = options["bordercolor"] as? Float4 {
            self.borderColor = borderColor
        } else {
            self.borderColor = Float4(1,1,1,1)
        }
        
        if let textRef = options["text"] as? TextRef {
            self.text = textRef
        } else {
            self.text = TextRef("")
        }
    }
}

struct MapShape2D {
    
    enum Shapes {
        case Disk, Box, Text
    }
    
    var shape           : Shapes
    var options         : MapShapeData2D
    var originalOptions : [String:Any]

    var body            : b2Body? = nil

    var instances       : MapInstance2D? = nil
    var contactList     : [String] = []
    
    var texture         : Any? = nil
}

struct MapPhysics2D {

    var ppm             : Float = 100
    var world           : b2World? = nil
    var options         : [String:Any]
}

struct MapScene {
    var options         : [String:Any]
    var backColor       : Float4? = nil
}

struct MapCommand {

    var command         : String
    var options         : [String:Any]
}

struct MapShader {
    var shader          : Shader? = nil
    var options         : [String:Any]
}

class MapInstance2D
{
    var shapeName       : String
    var behaviorName    : String
    
    var pairs           : [(MapShape2D, MapBehavior)] = []
    
    init(shapeName: String, behaviorName: String)
    {
        self.shapeName = shapeName
        self.behaviorName = behaviorName
    }
    
    func addPair(shape: inout MapShape2D, behavior: inout MapBehavior)
    {
        pairs.append((shape, behavior))
    }
}

class MapGridInstance2D : MapInstance2D
{
    var columns         : Int = 1
    var rows            : Int = 2
    
    var offsetX         : Float = 15
    var offsetY         : Float = 5
}
