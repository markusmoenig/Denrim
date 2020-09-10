//
//  Classes.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import Foundation
import JavaScriptCore

@objc protocol Vec4_JSExports: JSExport {
    var x           : Float { get set }
    var y           : Float { get set }
    var z           : Float { get set }
    var w           : Float { get set }

    static func create(_ x: Float,_ y: Float,_ z: Float,_ w:Float) -> Vec4
}

class Vec4              : NSObject, Vec4_JSExports
{
    var x           : Float = 1
    var y           : Float = 1
    var z           : Float = 1
    var w           : Float = 1

    init(_ x: Float = 1,_ y: Float = 1,_ z: Float = 1,_ w:Float = 1)
    {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        super.init()
    }
    
    func toSIMD() -> SIMD4<Float>
    {
        return SIMD4<Float>(x, y, z, w)
    }
    
    class func create(_ x: Float,_ y: Float,_ z: Float,_ w:Float) -> Vec4
    {
        return Vec4(x,y,z,w)
    }
}

@objc protocol Vec2_JSExports: JSExport {
    var x           : Float { get set }
    var y           : Float { get set }

    static func create(_ x: Float,_ y: Float) -> Vec2
}

class Vec2              : NSObject, Vec2_JSExports
{
    var x           : Float = 0
    var y           : Float = 0

    init(_ x: Float = 0,_ y: Float = 0)
    {
        self.x = x
        self.y = y
        super.init()
    }
    
    func toSIMD() -> SIMD2<Float>
    {
        return SIMD2<Float>(x, y)
    }
    
    class func create(_ x: Float,_ y: Float) -> Vec2
    {
        return Vec2(x,y)
    }
}

@objc protocol Rect2D_JSExports: JSExport {
    var x           : Float { get set }
    var y           : Float { get set }
    var width       : Float { get set }
    var height      : Float { get set }

    static func create(_ x: Float,_ y: Float,_ width: Float,_ height:Float) -> Rect2D
}

class Rect2D            : NSObject, Rect2D_JSExports
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
        super.init()
    }
    
    class func create(_ x: Float,_ y: Float,_ width: Float,_ height:Float) -> Rect2D
    {
        return Rect2D(x,y,width,height)
    }
}
