//
//  Map.swift
//  Denrim
//
//  Created by Markus Moenig on 7/9/20.
//

import MetalKit
import JavaScriptCore

@objc protocol Map_JSExports: JSExport {
    var isValid: Bool { get }
}

class Map                   : NSObject, Map_JSExports
{
    var isValid             : Bool = false
    
    var images              : [String:Texture2D] = [:]
    var lines               : [Int32:String] = [:]
    
    deinit {
        images = [:]
        lines = [:]
        print("release map")
    }
    
    override init()
    {
        super.init()
    }
}
