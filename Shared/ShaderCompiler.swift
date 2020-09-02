//
//  ShaderCompiler.swift
//  Denrim
//
//  Created by Markus Moenig on 2/9/20.
//

import MetalKit
import JavaScriptCore

class ShaderCompiler
{
    let asset           : Asset
    let game            : Game
    
    init(_ asset: Asset,_ game: Game)
    {
        self.asset = asset
        self.game = game
    }
    
    
    func compile(_ object: [AnyHashable:Any],_ promise: JSPromise)
    {
        var code = getHeaderCode()
        code += asset.value
        
        let params = "RasterizerData in [[stage_in]]"
        
        code = code.replacingOccurrences(of: "AutoParameters", with: params)
                
        let compiledCB : MTLNewLibraryCompletionHandler = { (library, error) in
            if let error = error, library == nil {
                promise.fail(error: error.localizedDescription)
            } else
            if let library = library {
                
                let shader = Shader()
                
                shader.pipelineStateDesc = MTLRenderPipelineDescriptor()
                shader.pipelineStateDesc.vertexFunction = library.makeFunction(name: "procVertex")
                shader.pipelineStateDesc.fragmentFunction = library.makeFunction(name: "shaderMain")
                shader.pipelineStateDesc.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
                
                shader.pipelineStateDesc.colorAttachments[0].isBlendingEnabled = true
                shader.pipelineStateDesc.colorAttachments[0].rgbBlendOperation = .add
                shader.pipelineStateDesc.colorAttachments[0].alphaBlendOperation = .add
                shader.pipelineStateDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                shader.pipelineStateDesc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                shader.pipelineStateDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                shader.pipelineStateDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                
                do {
                    shader.pipelineState = try self.game.device.makeRenderPipelineState(descriptor: shader.pipelineStateDesc)
                    shader.isValid = true
                    
                    promise.success(value: shader)

                    /*
                    let testBlock : @convention(block) (JSValue?) -> Void = { calledBackValue in
                        print("calledBackValue:", calledBackValue)
                    }*/

                } catch {
                    shader.isValid = false
                }
            }
        }
        
        game.device.makeLibrary( source: code, options: nil, completionHandler: compiledCB)
    }
    
    func getHeaderCode() -> String
    {
        return """
        
        #include <metal_stdlib>
        #include <simd/simd.h>
        using namespace metal;

        typedef struct
        {
            float4 clipSpacePosition [[position]];
            float2 textureCoordinate;
            float2 viewportSize;
        } RasterizerData;

        typedef struct
        {
            vector_float2 position;
            vector_float2 textureCoordinate;
        } VertexData;

        // Quad Vertex Function
        vertex RasterizerData
        procVertex(uint vertexID [[ vertex_id ]],
                     constant VertexData *vertexArray [[ buffer(0) ]],
                     constant vector_uint2 *viewportSizePointer  [[ buffer(1) ]])

        {
            RasterizerData out;
            
            float2 pixelSpacePosition = vertexArray[vertexID].position.xy;
            float2 viewportSize = float2(*viewportSizePointer);
            
            out.clipSpacePosition.xy = pixelSpacePosition / (viewportSize / 2.0);
            out.clipSpacePosition.z = 0.0;
            out.clipSpacePosition.w = 1.0;
            
            out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
            out.viewportSize = viewportSize;

            return out;
        }
        
        """
    }
}

