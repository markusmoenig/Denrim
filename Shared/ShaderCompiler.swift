//
//  ShaderCompiler.swift
//  Denrim
//
//  Created by Markus Moenig on 2/9/20.
//

import MetalKit

class Shader                : NSObject
{
    var isValid             : Bool = false
    var pipelineStateDesc   : MTLRenderPipelineDescriptor!
    var pipelineState       : MTLRenderPipelineState!
    
    var hasBindings         : Bool = false
    
    var intVar              : [String: (Int, Any)] = [:]
    var floatVar            : [String: (Int, Any)] = [:]
    var float2Var           : [String: (Int, Any)] = [:]
    var float3Var           : [String: (Int, Any)] = [:]
    var float4Var           : [String: (Int, Any)] = [:]

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

class ShaderCompiler
{
    let game            : Game
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func compile(asset: Asset, behavior: BehaviorContext? = nil, cb: @escaping (Shader?, [CompileError]) -> ())
    {
        var code = getHeaderCode()
        code += asset.value
        
        var ns = self.getHeaderCode() as NSString
        var lineNumbers  : Int32 = 0
        
        ns.enumerateLines { (str, _) in
            lineNumbers += 1
        }
        /*
        let p1 = " in [[stage_in]])"
        code = code.replacingOccurrences(of: " in)", with: p1)
            
        let p2 = "constant BehaviorData"
        code = code.replacingOccurrences(of: "BehaviorData", with: p2)

        let p3 = "*behavior [[ buffer(0) ]]"
        code = code.replacingOccurrences(of: "*behavior", with: p3)
        */
                
        var parseErrors: [CompileError] = []
        let shader = Shader()

        func createError(_ errorText: String = "Syntax Error", line: Int32) {
            var error = CompileError()
            error.asset = asset
            error.line = line - lineNumbers
            error.column = 0
            error.error = errorText
            error.type = "error"
            parseErrors.append(error)
        }
        
        var parsedCode = ""
        ns = code as NSString
        var lineNr : Int32 = 0
        
        ns.enumerateLines { (str, _) in
            if str.contains("behavior.") {
                let array = str.split(separator: " ")
                if array.count == 6 && array[2] == "=>" {
                    var out = array[0] + " " + array[1] + " = "
                    
                    if let behavior = behavior {
                        shader.hasBindings = true
                        let nameArray = String(array[3]).split(separator: ".")
                        if nameArray.count == 2 {
                            let varName = String(nameArray[1])
                            if let value = behavior.getVariableValue(varName) {
                                // Bind the value of the referenced varName
                                let varType = String(array[0])
                                
                                if varType == "float" && value as? Float1 != nil {
                                    let index : Int = shader.floatVar.count
                                    shader.floatVar[varName] = (index, value)
                                    out += "behavior.floatData[\(index)];"
                                }
                                
                                else {
                                    createError("Variable type '\(varType)' does not much type of variable in behavior", line: lineNr)
                                    parsedCode += str + "\n"
                                }
                            } else {
                                createError("Could not find variable '\(varName)' in behavior", line: lineNr)
                                parsedCode += str + "\n"
                            }
                        } else {
                            createError(line: lineNr)
                            parsedCode += str + "\n"
                        }
                    } else {
                        // No behavior, just use default value
                        out += array[5]
                    }
                    
                    print(out)

                    parsedCode += out + "\n"
                } else {
                    createError(line: lineNr)
                    parsedCode += str + "\n"
                }
            } else {
                parsedCode += str + "\n"
            }
            
            lineNr += 1
        }
        
        if parseErrors.count > 0 {            
            //DispatchQueue.main.async(execute: {
                cb(nil, parseErrors)
            //} )
            return
        }
                
        let compiledCB : MTLNewLibraryCompletionHandler = { (library, error) in
            if let error = error, library == nil {
                var errors: [CompileError] = []
                
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
        
        game.device.makeLibrary(source: parsedCode, options: nil, completionHandler: compiledCB)
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
            //vector_bool       boolData[10];
            int             intData[10];
            float           floatData[10];
            simd_float2     float2Data[10];
            simd_float3     float3Data[10];
            simd_float4     float4Data[10];
        } BehaviorData;

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

