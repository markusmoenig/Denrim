//
//  System.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import MetalKit
import JavaScriptCore

// Protocol must be declared with `@objc`
@objc protocol System_JSExports: JSExport {
    var width: Float { get }
    var height: Float { get }

    static func log(_ string: String)

    // Imported as `Person.createWithFirstNameLastName(_:_:)`
    //static func createWith(firstName: String, lastName: String) -> Person
}

class System            : NSObject, System_JSExports
{
    var width           : Float = 0
    var height          : Float = 0

    ///
    override init()
    {
        
        super.init()
    }

    class func log(_ string: String) {
        print(string)
    }
}
