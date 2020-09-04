//
//  Classes.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import Foundation
import JavaScriptCore

@objc protocol Vec4_JSExports: JSExport {
    var red         : Float { get set }
    var green       : Float { get set }
    var blue        : Float { get set }
    var alpha       : Float { get set }

    static func create(_ r: Float,_ g: Float,_ b: Float,_ a:Float) -> Vec4
}

class Vec4              : NSObject, Vec4_JSExports
{
    var red             : Float = 1
    var green           : Float = 1
    var blue            : Float = 1
    var alpha           : Float = 1

    init(_ r: Float = 1,_ g: Float = 1,_ b: Float = 1,_ a:Float = 1)
    {
        red = r
        green = g
        blue = b
        alpha = a
        super.init()
    }
    
    func toSIMD() -> SIMD4<Float>
    {
        return SIMD4<Float>(red, green, blue, alpha)
    }
    
    class func create(_ r: Float,_ g: Float,_ b: Float,_ a:Float) -> Vec4
    {
        return Vec4(r,g,b,a)
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
