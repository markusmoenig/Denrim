//
//  Physics2D.swift
//  Denrim
//
//  Created by Markus Moenig on 11/9/20.
//

import Foundation
import JavaScriptCore

@objc protocol Physics2D_JSExports: JSExport {
    var isValid: Bool { get }
}

class Physics2D             : NSObject, Physics2D_JSExports
{
    var isValid             : Bool = false

    deinit {
        print("release physics2d")
    }
    
    override init()
    {
        super.init()
    }
}
