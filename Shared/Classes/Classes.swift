//
//  Classes.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import Foundation

class Float4
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1
    var w           : Float = 1

    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1,_ w: Float = 1)
    {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    func toSIMD() -> SIMD4<Float>
    {
        return SIMD4<Float>(x, y, z, w)
    }
}

class Float2
{
    var x           : Float = 0
    var y           : Float = 0

    init(_ x: Float = 0,_ y: Float = 0)
    {
        self.x = x
        self.y = y
    }
    
    func toSIMD() -> SIMD2<Float>
    {
        return SIMD2<Float>(x, y)
    }
}

class Rect2D
{
    var x               : Float = 0
    var y               : Float = 0
    var width           : Float = 0
    var height          : Float = 0

    init(_ x: Float = 0,_ y: Float = 0,_ width: Float = 0,_ height:Float = 0)
    {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
