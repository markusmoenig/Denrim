//
//  Shader.swift
//  Metal-Z
//
//  Created by Markus Moenig on 1/9/20.
//

import MetalKit
import JavaScriptCore

@objc protocol Shader_JSExports: JSExport {
    var isValid: Bool { get }
}

class Shader                : NSObject, Shader_JSExports
{
    var isValid             : Bool = false
    var pipelineStateDesc   : MTLRenderPipelineDescriptor!
    var pipelineState       : MTLRenderPipelineState!
    
    override init()
    {
        super.init()
    }
}
