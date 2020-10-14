//
//  Leaves.swift
//  Denrim
//
//  Created by Markus Moenig on 19/9/20.
//

import Foundation
import simd

// Sets the current scene and initializes it
class SetScene: BehaviorNode
{
    var mapName: String? = nil
    var sceneName: String? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetScene"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["scene"] as? String {
            sceneName = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetScene requires a 'Scene' parameter"
        }
        
        if let value = options["map"] as? String {
            mapName = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetScene requires a 'Map' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let mapName = mapName {
            if let asset = game.assetFolder.getAsset(mapName, .Map) {
                if asset.map != nil {
                    asset.map?.clear()
                }
                let error = game.mapBuilder.compile(asset)
                if error.error == nil {
                    if let map = asset.map {
                        if let sceneName = sceneName {
                            if let scene = map.scenes[sceneName] {
                                game.currentMap = asset
                                game.currentScene = scene
                                map.setup(game: game)
                                // Add Game Behavior
                                let gameBehavior = MapBehavior(behaviorAsset: game.gameAsset!, name: "game", options: [:])
                                map.behavior["game"] = gameBehavior
                                return .Success
                            }
                        }
                    }
                }
            }
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Calls a given tree
class Call: BehaviorNode
{
    var callContext         : [BehaviorContext] = []
    var callTree            : BehaviorTree? = nil
    var treeName            : String? = nil
    
    var firstCall           : Bool = true
    
    var parameters          : [BehaviorVariable] = []

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Call"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if options["tree"] as? String == nil {
            error.error = "Call requires a 'Tree' parameter"
        }
        
        if let value = options["variables"] as? String {
            let array = value.split(separator: ",")

            for v in array {
                let val = String(v.trimmingCharacters(in: .whitespaces))
                var foundVar : BehaviorVariable? = nil
                for variable in context.variables {
                    if variable.name == val {
                        foundVar = variable
                        break
                    }
                }
                if foundVar != nil {
                    parameters.append(foundVar!)
                } else {
                    error.error = "Variable '\(val)' not found"
                }
            }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if firstCall == true {
            firstCall = false
            if let treeName = options["tree"] as? String {
                let treeArray = treeName.split(separator: ".")
                if treeArray.count == 1 {
                    // No ., tree has to be in the same context
                    callContext.append(context)
                    self.treeName = treeName
                } else
                if treeArray.count == 2 {
                    //var asset = game.assetFolder.getAsset(String(treeArray[0]).lowercased(), .Behavior)
                    if treeArray[0] == "game" {
                        let asset = game.gameAsset
                        if let context = asset?.behavior {
                            callContext.append(context)
                            self.treeName = String(treeArray[1])
                        }
                    } else {
                        if let map = game.currentMap?.map {
                            if let behavior = map.behavior[String(treeArray[0])] {
                                let asset = behavior.behaviorAsset
                                
                                self.treeName = String(treeArray[1])
                                if let context = asset.behavior {
                                    if let grid = behavior.grid {
                                        for inst in grid.instances {
                                            callContext.append(inst.1.behaviorAsset.behavior!)
                                        }
                                    } else {
                                        callContext.append(context)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
                        
        if treeName != nil {
            for context in callContext {
                if let tree = context.getTree(treeName!) {
                    // Now replace the values in the tree parameters with the variable values which we pass to the tree
                    for (index, variable) in parameters.enumerated() {
                        if index < tree.parameters.count {
                            let param = tree.parameters[index]
                            if let dest = param.value as? Int1 {
                                if let source = variable.value as? Int1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param.value as? Bool1 {
                                if let source = variable.value as? Bool1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param.value as? Float1 {
                                if let source = variable.value as? Float1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param.value as? Float2 {
                                if let source = variable.value as? Float2 {
                                    dest.x = source.x
                                    dest.y = source.y
                                }
                            } else
                            if let dest = param.value as? Float3 {
                                if let source = variable.value as? Float3 {
                                    dest.x = source.x
                                    dest.y = source.y
                                    dest.z = source.z
                                }
                            } else
                            if let dest = param.value as? Float4 {
                                if let source = variable.value as? Float4 {
                                    dest.x = source.x
                                    dest.y = source.y
                                    dest.z = source.z
                                    dest.w = source.w
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        if treeName != nil {
            for context in callContext {
                context.execute(name: treeName!)
            }
            return .Success
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class SetNode: BehaviorNode
{
    var variable: Any? = nil
    var value: Any? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Set"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let variable = extractVariableValue(options, variableName: "variable", context: context, error: &error) {
            
            if variable as? Bool1 != nil {
                if let value = extractBool1Value(options, context: context, tree: tree, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Bool' parameter" }
            } else
            if variable as? Int1 != nil {
                if let value = extractInt1Value(options, context: context, tree: tree, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Int' parameter" }
            } else
            if variable as? Float1 != nil {
                if let value = extractFloat1Value(options, context: context, tree: tree, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float' parameter" }
            } else
            if variable as? Float2 != nil {
                if let value = extractFloat2Value(options, context: context, tree: tree, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float2' parameter" }
            } else
            if variable as? Float3 != nil {
                if let value = extractFloat3Value(options, context: context, tree: tree, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float3' parameter" }
            } else
            if variable as? Float4 != nil {
                if let value = extractFloat4Value(options, context: context, tree: tree, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float4' parameter" }
            }
        } else { error.error = "Missing 'Variable' parameter" }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let boolVar = variable as? Bool1 {
            if let boolValue = value as? Bool1 {
                boolVar.x = boolValue.x
                return .Success
            }
        } else
        if let intVar = variable as? Int1 {
            if let intValue = value as? Int1 {
                intVar.x = intValue.x
                return .Success
            }
        } else
        if let floatVar = variable as? Float1 {
            if let floatValue = value as? Float1 {
                floatVar.x = floatValue.x
                return .Success
            }
        } else
        if let float2Var = variable as? Float2 {
            if let float2Value = value as? Float2 {
                float2Var.x = float2Value.x
                float2Var.y = float2Value.y
                return .Success
            }
        } else
        if let float3Var = variable as? Float3 {
            if let float3Value = value as? Float3 {
                float3Var.x = float3Value.x
                float3Var.y = float3Value.y
                float3Var.z = float3Value.z
                return .Success
            }
        } else
        if let float4Var = variable as? Float4 {
            if let float4Value = value as? Float4 {
                float4Var.x = float4Value.x
                float4Var.y = float4Value.y
                float4Var.z = float4Value.z
                float4Var.w = float4Value.w
                return .Success
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class DistanceToShape: BehaviorNode
{
    var position2: Float2? = nil
    var radius1: Float1? = nil
    var shapeName: String? = nil
    var dest: Float1? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "DistanceToShape"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        position2 = extractFloat2Value(options, context: context, tree: tree, error: &error, name: "position")
        radius1 = extractFloat1Value(options, context: context, tree: tree, error: &error, name: "radius", isOptional: true)
        dest = extractFloat1Value(options, context: context, tree: tree, error: &error, name: "variable")

        if let shapeN = options["shape"] as? String {
            shapeName = shapeN
        } else {
            error.error = "Missing 'Shape' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let position = position2 {
            if let map = game.currentMap?.map {
                if let shape = map.shapes2D[shapeName!] {
                    
                    if let grid = shape.grid {
                        
                        for inst in grid.instances {
                            if inst.1.behaviorAsset.behavior === context {
                                let distance = distanceToRect(position: position, shape: inst.0, map: map)
                                if let dest = dest {
                                    dest.x = distance
                                    return .Success
                                } else {
                                    break
                                }
                            }
                        }
                        
                        return .Success
                    } else {
                        let distance = distanceToRect(position: position, shape: shape, map: map)
                        if let dest = dest {
                            dest.x = distance
                            return .Success
                        }
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
    
    func distanceToRect(position: Float2, shape: MapShape2D, map: Map) -> Float
    {
        let aspect = map.aspect!

        var radius : Float = 1
        if let radius1 = radius1 {
            radius = radius1.x
        }
        
        var uv : float2 = float2(position.x, position.y) + float2(radius, radius) - float2(shape.options.position.x, shape.options.position.y) - float2(shape.options.size.x, shape.options.size.y) / 2.0
        uv.x *= aspect.x
        uv.y *= aspect.y

        let d : float2 = simd_abs(uv) - float2(shape.options.size.x * aspect.x, shape.options.size.y * aspect.y) / 2.0
        let distToBox : Float = simd_length(max(d,float2(0,0))) + min(max(d.x,d.y),0.0);
        
        return distToBox - radius * aspect.z
    }
}


class RandomColorNode: BehaviorNode
{
    var a: Float3 = Float3(0.5, 0.5, 0.5)
    var b: Float3 = Float3(0.5, 0.5, 0.5)
    var c: Float3 = Float3(1.0, 1.0, 1.0)
    var d: Float3 = Float3(0.0, 0.33, 0.67)

    var dest: Float4? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "RandomColor"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let a = extractFloat3Value(options, context: context, tree: tree, error: &error, name: "a", isOptional: true) {
            self.a = a
        }
        if let b = extractFloat3Value(options, context: context, tree: tree, error: &error, name: "b", isOptional: true) {
            self.b = b
        }
        if let c = extractFloat3Value(options, context: context, tree: tree, error: &error, name: "c", isOptional: true) {
            self.c = c
        }
        if let d = extractFloat3Value(options, context: context, tree: tree, error: &error, name: "d", isOptional: true) {
            self.d = d
        }
        dest = extractFloat4Value(options, context: context, tree: tree, error: &error, name: "variable")
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let dest = dest {
            let t = Float.random(in: 0...1)
            var res = a.toSIMD()
            res.x = a.x + b.x * cos( 6.28318 * (c.x * t + d.x) )
            res.y = a.y + b.y * cos( 6.28318 * (c.y * t + d.y) )
            res.z = a.z + b.z * cos( 6.28318 * (c.z * t + d.z) )
            
            dest.x = res.x
            dest.y = res.y
            dest.z = res.z
            
            return .Success
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class GetTouchPos: BehaviorNode
{
    var data2: Float2? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "GetTouchPos"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        data2 = extractFloat2Value(options, context: context, tree: tree, error: &error, name: "variable")
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if game.view.mouseIsDown {
            if let data2 = data2 {
                data2.x = game.view.mousePos.x / game.currentMap!.map!.aspect.x
                data2.y = game.view.mousePos.y / game.currentMap!.map!.aspect.y
                return .Success
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class IsKeyDown: BehaviorNode
{
    var key: String? = nil
    
    var keyCodes    : [Float:String] = [
        53: "Escape",

        50: "Back Quote",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        23: "5",
        22: "6",
        26: "7",
        28: "8",
        25: "9",
        29: "0",
        27: "-",
        24: "=",
        51: "Delete",

        48: "Tab",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        17: "T",
        16: "Y",
        32: "U",
        34: "I",
        31: "O",
        35: "P",
        33: "[",
        30: "]",
        42: "\\",
        
//        57: "Caps Lock",
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        5: "G",
        4: "H",
        38: "J",
        40: "K",
        37: "L",
        41: ";",
        39: ",",
        36: "Return",
        
        57: "Shift",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        45: "N",
        46: "M",
        43: "Comma",
        47: "Period",
        44: "/",
        60: "Shift",
        
        63: "fn",
        59: "Control",
        58: "Option",
        55: "Command",
        49: "Space",
//        55: "R. Command",
        61: "R. Option",
        
        123: "ArrowLeft",
        126: "ArrowUp",
        124: "ArrowRight",
        125: "ArrowDown",
    ]
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsKeyDown"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["key"] as? String {
            key = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "IsKeyDown requires a 'Key' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let key = key {
            for k in game.view.keysDown {
                for (code, char) in keyCodes {
                    if code == k && char == key {
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class Subtract: BehaviorNode
{
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Subtract"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        pair = extractPair(options, variableName: "from", context: context, tree: tree, error: &error, optionalVariables: ["minimum"])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let pair = pair {
            if pair.0.int1 != nil {
                // Int
                pair.1.int1!.x -= pair.0.int1!.x
                if let min = pair.2[0].int1 {
                    pair.1.int1!.x = max(pair.1.int1!.x, min.x)
                }
                return .Success
            } else
            if pair.0.data1 != nil {
                // Float
                pair.1.data1!.x -= pair.0.data1!.x
                if let min = pair.2[0].data1 {
                    pair.1.data1!.x = max(pair.1.data1!.x, min.x)
                }
                return .Success
            } else
            if pair.0.data2 != nil {
                // Float2
                pair.1.data2!.x -= pair.0.data2!.x
                pair.1.data2!.y -= pair.0.data2!.y
                if let min = pair.2[0].data2 {
                    pair.1.data2!.x = max(pair.1.data2!.x, min.x)
                    pair.1.data2!.y = max(pair.1.data2!.y, min.y)
                }
                return .Success
            } else
            if pair.0.data3 != nil {
                // Float3
                pair.1.data3!.x -= pair.0.data3!.x
                pair.1.data3!.y -= pair.0.data3!.y
                pair.1.data3!.z -= pair.0.data3!.z
                if let min = pair.2[0].data3 {
                    pair.1.data3!.x = max(pair.1.data3!.x, min.x)
                    pair.1.data3!.y = max(pair.1.data3!.y, min.y)
                    pair.1.data3!.z = max(pair.1.data3!.z, min.z)
                }
                return .Success
            } else
            if pair.0.data4 != nil {
                // Float4
                pair.1.data4!.x -= pair.0.data4!.x
                pair.1.data4!.y -= pair.0.data4!.y
                pair.1.data4!.z -= pair.0.data4!.z
                pair.1.data4!.w -= pair.0.data4!.w
                if let min = pair.2[0].data4 {
                    pair.1.data4!.x = max(pair.1.data4!.x, min.x)
                    pair.1.data4!.y = max(pair.1.data4!.y, min.y)
                    pair.1.data4!.z = max(pair.1.data4!.z, min.z)
                    pair.1.data4!.w = max(pair.1.data4!.w, min.w)
                }
                return .Success
            }
        }
        return .Failure
    }
}

class Add: BehaviorNode
{
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Add"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        pair = extractPair(options, variableName: "to", context: context, tree: tree, error: &error, optionalVariables: ["maximum"])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let pair = pair {
            // Int
            if pair.0.int1 != nil {
                pair.1.int1!.x += pair.0.int1!.x
                if let max = pair.2[0].int1 {
                    pair.1.int1!.x = min(pair.1.int1!.x, max.x)
                }
                return .Success
            } else
            // Float
            if pair.0.data1 != nil {
                pair.1.data1!.x += pair.0.data1!.x
                if let max = pair.2[0].data1 {
                    pair.1.data1!.x = min(pair.1.data1!.x, max.x)
                }
                return .Success
            } else
            // Float2
            if pair.0.data2 != nil {
                pair.1.data2!.x += pair.0.data2!.x
                pair.1.data2!.y += pair.0.data2!.y
                if let max = pair.2[0].data2 {
                    pair.1.data2!.x = min(pair.1.data2!.x, max.x)
                    pair.1.data2!.y = min(pair.1.data2!.y, max.y)
                }
                return .Success
            } else
            // Float3
            if pair.0.data3 != nil {
                pair.1.data3!.x += pair.0.data3!.x
                pair.1.data3!.y += pair.0.data3!.y
                pair.1.data3!.z += pair.0.data3!.z
                if let max = pair.2[0].data3 {
                    pair.1.data3!.x = min(pair.1.data3!.x, max.x)
                    pair.1.data3!.y = min(pair.1.data3!.y, max.y)
                    pair.1.data3!.z = min(pair.1.data3!.z, max.z)
                }
                return .Success
            } else
            // Float4
            if pair.0.data4 != nil {
                pair.1.data4!.x += pair.0.data4!.x
                pair.1.data4!.y += pair.0.data4!.y
                pair.1.data4!.z += pair.0.data4!.z
                pair.1.data4!.w += pair.0.data4!.w
                if let max = pair.2[0].data4 {
                    pair.1.data4!.x = min(pair.1.data4!.x, max.x)
                    pair.1.data4!.y = min(pair.1.data4!.y, max.y)
                    pair.1.data4!.z = min(pair.1.data4!.z, max.z)
                    pair.1.data4!.w = min(pair.1.data4!.w, max.w)
                }
                return .Success
            }
        }
        return .Failure
    }
}

class Multiply: BehaviorNode
{
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Multiply"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        pair = extractPair(options, variableName: "with", context: context, tree: tree, error: &error, optionalVariables: [])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let pair = pair {
            // Int
            if pair.0.int1 != nil {
                pair.1.int1!.x *= pair.0.int1!.x
                return .Success
            } else
            // Float
            if pair.0.data1 != nil {
                pair.1.data1!.x *= pair.0.data1!.x
                return .Success
            } else
            // Float2
            if pair.0.data2 != nil {
                pair.1.data2!.x *= pair.0.data2!.x
                pair.1.data2!.y *= pair.0.data2!.y
                return .Success
            } else
            // Float3
            if pair.0.data3 != nil {
                pair.1.data3!.x *= pair.0.data3!.x
                pair.1.data3!.y *= pair.0.data3!.y
                pair.1.data3!.z *= pair.0.data3!.z
                return .Success
            } else
            // Float4
            if pair.0.data4 != nil {
                pair.1.data4!.x *= pair.0.data4!.x
                pair.1.data4!.y *= pair.0.data4!.y
                pair.1.data4!.z *= pair.0.data4!.z
                pair.1.data4!.w *= pair.0.data4!.w
                return .Success
            }
        }
        return .Failure
    }
}

class IsVariable: BehaviorNode
{
    enum Mode {
        case GreaterThan, LessThan, Equal
    }
    
    var mode    : Mode = .Equal
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsVariable"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        pair = extractPair(options, variableName: "variable", context: context, tree: tree, error: &error, optionalVariables: [])
        if error.error == nil {
            if var m = options["mode"] as? String {
                m = m.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                if m == "GreaterThan" {
                    mode = .GreaterThan
                } else
                if m == "LessThan" {
                    mode = .LessThan
                } else
                if m == "Equal" {
                    mode = .Equal
                } else { error.error = "'Mode' needs to be 'Equal', 'GreatherThan' or 'LessThan'" }
            } else { error.error = "Missing 'Mode' statement" }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let pair = pair {
            // Int
            if pair.0.int1 != nil {
                if mode == .Equal {
                    if pair.1.int1!.x == pair.0.int1!.x {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.int1!.x > pair.0.int1!.x {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.int1!.x < pair.0.int1!.x {
                        return .Success
                    }
                }
            } else
            // Float
            if pair.0.data1 != nil {
                if mode == .Equal {
                    if pair.1.data1!.x == pair.0.data1!.x {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.data1!.x > pair.0.data1!.x {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.data1!.x < pair.0.data1!.x {
                        return .Success
                    }
                }
            } else
            // Float2
            if pair.0.data2 != nil {
                if mode == .Equal {
                    if pair.1.data2!.x == pair.0.data2!.x && pair.1.data2!.y == pair.0.data2!.y {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.data2!.x > pair.0.data2!.x && pair.1.data2!.y > pair.0.data2!.y {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.data2!.x < pair.0.data2!.x && pair.1.data2!.y < pair.0.data2!.y {
                        return .Success
                    }
                }
            } else
            // Float3
            if pair.0.data3 != nil {
                if mode == .Equal {
                    if pair.1.data3!.x == pair.0.data3!.x && pair.1.data3!.y == pair.0.data3!.y && pair.1.data3!.z == pair.0.data3!.z {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.data3!.x > pair.0.data3!.x && pair.1.data3!.y > pair.0.data3!.y && pair.1.data3!.z > pair.0.data3!.z {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.data3!.x < pair.0.data3!.x && pair.1.data3!.y < pair.0.data3!.y && pair.1.data3!.z < pair.0.data3!.z {
                        return .Success
                    }
                }
            } else
            // Float4
            if pair.0.data4 != nil {
                if mode == .Equal {
                    if pair.1.data4!.x == pair.0.data4!.x && pair.1.data4!.y == pair.0.data4!.y && pair.1.data4!.z == pair.0.data4!.z && pair.1.data4!.w == pair.0.data4!.w {
                        return .Success
                    }
                } else
                if mode == .GreaterThan {
                    if pair.1.data4!.x > pair.0.data4!.x && pair.1.data4!.y > pair.0.data4!.y && pair.1.data4!.z > pair.0.data4!.z && pair.1.data4!.w > pair.0.data4!.w {
                        return .Success
                    }
                } else
                if mode == .LessThan {
                    if pair.1.data4!.x < pair.0.data4!.x && pair.1.data4!.y < pair.0.data4!.y && pair.1.data4!.z < pair.0.data4!.z && pair.1.data4!.w < pair.0.data4!.w {
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}


