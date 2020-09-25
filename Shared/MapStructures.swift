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

struct MapBehavior {

    var body            : b2Body? = nil
    
    var behavior        : Asset
    
    var name            : String = ""
    var options         : [String:Any]
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
    
    var color           : float4
    var borderColor     : float4
    
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
        } else {
            self.radius = Float1(1)
        }
        
        if let onion = options["onion"] as? Float1 {
            self.onion = onion
        } else {
            self.onion = Float1(0)
        }
        
        if let color = options["color"] as? Float4 {
            self.color = color.toSIMD()
        } else {
            self.color = float4(1,1,1,1)
        }
        
        if let borderColor = options["bordercolor"] as? Float4 {
            self.borderColor = borderColor.toSIMD()
        } else {
            self.borderColor = float4(0,0,0,0)
        }
    }
}

struct MapShape2D {
    enum Shapes {
        case Disk, Box
    }
    var shape           : Shapes
    var options         : MapShapeData2D
}

struct MapPhysics2D {

    var ppm             : Float = 100
    var world           : b2World? = nil
    var options         : [String:Any]
}

struct MapScene {

    var options         : [String:Any]
}

struct MapCommand {

    var command         : String
    var options         : [String:Any]
}

struct MapShader {
    var shader          : Shader? = nil
    var options         : [String:Any]
}

struct MapText {
    var font            : Font
    var size            : Float1
    var options         : [String:Any]
}
