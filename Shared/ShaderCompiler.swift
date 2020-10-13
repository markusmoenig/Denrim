//
//  ShaderCompiler.swift
//  Denrim
//
//  Created by Markus Moenig on 2/9/20.
//

import MetalKit

class ShaderCompiler
{
    let game            : Game
    
    init(_ game: Game)
    {
        self.game = game
    }
    /*
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
    */
    
    func compile(_ asset: Asset, _ cb: @escaping (Shader?, [CompileError]) -> ())
    {
        var code = getHeaderCode()
        code += asset.value
        
        let params = "RasterizerData in [[stage_in]]"
        
        code = code.replacingOccurrences(of: "AutoParameters", with: params)
                
        let compiledCB : MTLNewLibraryCompletionHandler = { (library, error) in
            if let error = error, library == nil {
                var errors: [CompileError] = []
                
                let ns = self.getHeaderCode() as NSString
                var lineNumbers  : Int32 = 0
                
                ns.enumerateLines { (str, _) in
                    lineNumbers += 1
                }
                
                let str = error.localizedDescription
                let arr = str.components(separatedBy: "program_source:")
                for str in arr {
                    if str.contains("error:") || str.contains("warning:") {
                        let arr = str.split(separator: ":")
                        let errorArr = String(arr[3].trimmingCharacters(in: .whitespaces)).split(separator: "\n")
                        var errorText = ""
                        if errorArr.count > 0 {
                            errorText = String(errorArr[0])
                        }
                        if arr.count == 4 {
                            var er = CompileError()
                            er.asset = asset
                            er.line = Int32(arr[0])! - lineNumbers - 1
                            er.column = Int32(arr[1])
                            er.type = arr[2].trimmingCharacters(in: .whitespaces)
                            er.error = errorText
                            errors.append(er)
                        }
                    }
                }
                
                cb(nil, errors)
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
                } catch {
                    shader.isValid = false
                }

                if shader.isValid == true {
                    cb(shader, [])
                }
            }
        }
        
        game.device.makeLibrary(source: code, options: nil, completionHandler: compiledCB)
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

