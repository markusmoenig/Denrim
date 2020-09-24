//
//  Shader.swift
//  Metal-Z
//
//  Created by Markus Moenig on 1/9/20.
//

import MetalKit

class Shader                : NSObject
{
    var isValid             : Bool = false
    var pipelineStateDesc   : MTLRenderPipelineDescriptor!
    var pipelineState       : MTLRenderPipelineState!
    
    deinit {
        print("release shader")
        pipelineStateDesc = nil
        pipelineState = nil
    }
    
    override init()
    {
        super.init()
    }
}
