//
//  Utilities.swift
//  Denrim
//
//  Created by Markus Moenig on 23/9/20.
//

import Foundation

struct UpTo4Data {
    var data2        : Float2? = nil
    var data4        : Float4? = nil
}

func extractVariableValue(_ options: [String:Any], variableName: String, context: BehaviorContext, error: inout CompileError) -> Any?
{
    if let varString = options[variableName] as? String {
        if let value = context.getVariableValue(varString) {
            return value
        } else { error.error = "Cannot find '\(variableName)' variable" }
    } else { error.error = "Missing required '\(variableName)' variable" }
    
    return nil
}

func extractFloat2Value(_ options: [String:Any], variableName: String, context: BehaviorContext, error: inout CompileError) -> Float2?
{
    if let value = options["float2"] as? String {
        let array = value.split(separator: ",")
        if array.count == 2 {
            let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
            let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
            return Float2(x, y)
        } else { error.error = "Wrong argument count for Float2" }
    } else
    if let variableName = options["variable"] as? String {
        if let v = context.getVariableValue(variableName) as? Float2 {
            return v
        } else { error.error = "Variable '\(variableName)' not found" }
    } else { error.error = "Missing required 'Float2' parameter" }
    
    return nil
}

func extractPair(_ options: [String:Any], variableName: String, context: BehaviorContext, error: inout CompileError) -> (UpTo4Data, UpTo4Data)
{
    var Data         = UpTo4Data()
    var variableData = UpTo4Data()
    
    //print("extractPair", options, variableName)

    if let variableValue = extractVariableValue(options, variableName: variableName, context: context, error: &error) {
        if let f2 = variableValue as? Float2 {
            variableData.data2 = f2
            if let data = extractFloat2Value(options, variableName: variableName, context: context, error: &error) {
                Data.data2 = data
            }
        } else
        if let f4 = variableValue as? Float4 {
            variableData.data4 = f4
        }
    }
    
    return (Data, variableData)
}
