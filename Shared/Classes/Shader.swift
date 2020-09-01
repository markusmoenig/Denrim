//
//  Shader.swift
//  Metal-Z
//
//  Created by Markus Moenig on 1/9/20.
//

import Foundation
import JavaScriptCore

@objc protocol Shader_JSExports: JSExport {

    static func compile()
}

class Shader            : NSObject, Shader_JSExports
{
    init(_ game: Game)
    {
        super.init()
    }
    
    class func compile()
    {
    }
}
