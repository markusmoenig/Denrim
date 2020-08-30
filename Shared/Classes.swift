//
//  Classes.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import Foundation
import JavaScriptCore

@objc protocol Color_JSExports: JSExport {
    var red         : Float { get set }
    var green       : Float { get set }
    var blue        : Float { get set }
    var alpha       : Float { get set }

    static func create(_ r: Float,_ g: Float,_ b: Float,_ a:Float) -> Color
}

class Color             : NSObject, Color_JSExports
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
    
    class func create(_ r: Float,_ g: Float,_ b: Float,_ a:Float) -> Color
    {
        return Color(r,g,b,a)
    }
}
