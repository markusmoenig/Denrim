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

struct MapAudio {
    var resourceName    : String
    var options         : [String:Any]
    
    var isLocal         : Bool = true
    var loops           : Int = 0
}

class MapSequenceData2D {
    var animIndex       : Int = 0
    var lastTime        : Double = 0
}

struct MapSequence {
    
    var resourceNames   : [String] = []
    var options         : [String:Any]
    
    var data            : MapSequenceData2D? = nil
    var interval        : Double = 0.1
}

struct MapAliasData2D {

    enum Scale {
        case Original, Full
    }
    
    var scale           : Scale = .Original
    
    var position        : Float2
    var width           = Float1(0)
    var height          = Float1(0)
    
    var offset          = Float2(0,0)

    var rect            : Float4? = nil
    var texture         : Texture2D? = nil
    
    var repeatX         : Bool = false
    var repeatY         : Bool = false
    
    var physicsId       : String? = nil
    
    var isEmpty         : Bool = false

    init(_ position: Float2)
    {
        self.position = position
    }
    
    init(_ options: [String:Any])
    {
        if let position = options["position"] as? Float2 {
            self.position = position
        } else {
            self.position = Float2(0,0)
        }
        
        if let offset = options["offset"] as? Float2 {
            self.offset = offset
        }
        
        if let rect = options["rect"] as? Float4 {
            self.rect = rect
        } else
        if let size = options["size"] as? Float2 {
            self.rect = Float4(0, 0, size.x, size.y)
            isEmpty = true
        } else {
            self.rect = nil
        }
        
        if let scale = options["scale"] as? String {
            if scale.lowercased() == "full" {
                self.scale = .Full
            }
        }
        
        if let repeatX = options["repeatx"] as? Bool1 {
            self.repeatX = repeatX.x
        }
        
        if let repeatY = options["repeaty"] as? Bool1 {
            self.repeatY = repeatY.x
        }
        
        if let physicsId = options["physicsid"] as? String {
            self.physicsId = physicsId
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
    
    var body            : b2Body? = nil
    var physicsWorld    : MapPhysics2D? = nil
}

struct MapLayerData2D {
    
    enum Filter {
        case Linear, Nearest
    }
    
    var filter          : Filter = .Linear
    
    var offset          : Float2
    var scroll          : Float2
    
    var clipToCanvas    : Bool = false

    var accumScroll     = Float2(0,0)
    
    var lineHeight      = Float1(16)

    init(_ options: [String:Any])
    {
        if let offset = options["offset"] as? Float2 {
            self.offset = offset
        } else {
            self.offset = Float2(0,0)
        }
        
        if let scroll = options["scroll"] as? Float2 {
            self.scroll = scroll
        } else {
            self.scroll = Float2(0,0)
        }
        
        if let lineHeight = options["lineheight"] as? Float1 {
            self.lineHeight = lineHeight
        }
        
        if let cliptocanvas = options["cliptocanvas"] as? Bool1 {
            self.clipToCanvas = cliptocanvas.x
        }
        
        if let sampler = options["filter"] as? String {
            if sampler.lowercased() == "nearest" {
                filter = .Nearest
            }
        }
    }
}

struct AliasLine {
    var line            : [MapAlias] = []
        
    init(_ line : [MapAlias] = []) {
        self.line = line
    }
}

struct MapLayer {

    var data            : [AliasLine] = []
    
    var originalOptions : [String:Any]
    var options         : MapLayerData2D

    var endLine         : Int32 = 0
}

struct MapBehavior {
    var behaviorAsset   : Asset
    
    var name            : String = ""
    var options         : [String:Any]
    
    var instances       : MapInstance2D? = nil
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
    
    var flipX           : Bool1
    var flipY           : Bool1

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
            self.size = Float2(0,0)
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
        
        flipX = Bool1(false)
        flipY = Bool1(false)
    }
}

struct MapShape2D {
    
    enum Shapes {
        case Disk, Box, Text
    }
    
    var shapeName       : String
    var shape           : Shapes
    var options         : MapShapeData2D
    var originalOptions : [String:Any]

    var body            : b2Body? = nil
    var categoryBits    : UInt16 = 0

    var instances       : MapInstance2D? = nil
    var contactList     : [String] = []
    
    var texture         : Any? = nil
    var physicsCmd      : MapCommand? = nil
    var physicsWorld    : MapPhysics2D? = nil
}

struct MapPhysics2D {

    var ppm             : Float = 100
    var world           : b2World? = nil
    var options         : [String:Any]
}

struct MapScene {
    var options         : [String:Any]
    var backColor       : Float4? = nil
    var name            : String = ""
}

struct MapCommand {

    var command         : String
    var options         : [String:Any]
}

struct MapShader {
    var shader          : Shader? = nil    
    var canvasArea      : Bool = false
    var options         : [String:Any]
}

class MapInstance2D
{
    var shapeName       : String
    var behaviorName    : String

    var variableName    : String

    var pairs           : [(MapShape2D, MapBehavior)] = []
    
    init(shapeName: String, behaviorName: String, variableName: String)
    {
        self.shapeName = shapeName
        self.behaviorName = behaviorName
        self.variableName = variableName
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

class MapOnDemandInstance2D : MapInstance2D
{
    var delay           : Double = 0
    var lastInvocation  : Double = 0
}
