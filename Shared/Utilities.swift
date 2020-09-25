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

/// Extract a float2 vale
func extractFloat2Value(_ options: [String:Any], context: BehaviorContext, error: inout CompileError, name: String = "float2", isOptional: Bool = false ) -> Float2?
{
    if let value = options[name] as? String {
        let array = value.split(separator: ",")
        if array.count == 2 {
            let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
            let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
            return Float2(x, y)
        } else
        if array.count == 1 {
            if let v = context.getVariableValue(String(array[0])) as? Float2 {
                return v
            }
        } else { if isOptional == false { error.error = "Wrong argument count for Float2" } }
    } else { if isOptional == false { error.error = "Variable '\(name)' not found" } }
    
    return nil
}

func extractPair(_ options: [String:Any], variableName: String, context: BehaviorContext, error: inout CompileError, optionalVariables: [String]) -> (UpTo4Data, UpTo4Data,[UpTo4Data])
{
    var Data         = UpTo4Data()
    var variableData = UpTo4Data()
    var optionals : [UpTo4Data] = []
    
    //print("extractPair", options, variableName)

    if let variableValue = extractVariableValue(options, variableName: variableName, context: context, error: &error) {
        if let f2 = variableValue as? Float2 {
            variableData.data2 = f2
            if let data = extractFloat2Value(options, context: context, error: &error) {
                Data.data2 = data
            }
            for oV in optionalVariables {
                var data = UpTo4Data()
                data.data2 = extractFloat2Value(options, context: context, error: &error, name: oV, isOptional: true)
                optionals.append(data)
            }
        } else
        if let f4 = variableValue as? Float4 {
            variableData.data4 = f4
        }
    }
    
    return (Data, variableData, optionals)
}
