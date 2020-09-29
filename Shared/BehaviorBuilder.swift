//
//  BehaviorBuilder.swift
//  Denrim
//
//  Created by Markus Moenig on 18/9/20.
//

import Foundation

struct CompileError
{
    var asset           : Asset? = nil
    var line            : Int32? = nil
    var column          : Int32? = 0
    var error           : String? = nil
}

class BehaviorNodeItem
{
    var name         : String
    var createNode   : (_ options: [String:Any]) -> BehaviorNode
    
    init(_ name: String, _ createNode: @escaping (_ options: [String:Any]) -> BehaviorNode)
    {
        self.name = name
        self.createNode = createNode
    }
}

class BehaviorBuilder
{
    let game            : Game
    
    var branches        : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("sequence", { (_ options: [String:Any]) -> BehaviorNode in return SequenceBranch(options) })
    ]
    
    var leaves          : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("SetScene", { (_ options: [String:Any]) -> BehaviorNode in return SetScene(options) }),
        BehaviorNodeItem("Call", { (_ options: [String:Any]) -> BehaviorNode in return Call(options) }),
        BehaviorNodeItem("IsKeyDown", { (_ options: [String:Any]) -> BehaviorNode in return IsKeyDown(options) }),
        
        BehaviorNodeItem("IsVariable", { (_ options: [String:Any]) -> BehaviorNode in return IsVariable(options) }),

        BehaviorNodeItem("Multiply", { (_ options: [String:Any]) -> BehaviorNode in return Multiply(options) }),
        BehaviorNodeItem("Subtract", { (_ options: [String:Any]) -> BehaviorNode in return Subtract(options) }),
        BehaviorNodeItem("Add", { (_ options: [String:Any]) -> BehaviorNode in return Add(options) })
    ]
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    @discardableResult func compile(_ asset: Asset) -> CompileError
    {
        var error = CompileError()
        error.asset = asset
        
        func createError(_ errorText: String = "Syntax Error") {
            error.error = errorText
        }
        
        if asset.behavior == nil {
            asset.behavior = BehaviorContext(game)
        } else {
            asset.behavior!.clear()
        }
        
        let ns = asset.value as NSString
        var lineNumber  : Int32 = 0
        
        var currentTree     : BehaviorTree? = nil
        var currentBranch   : [BehaviorNode] = []
        var lastLevel       : Int = -1

        ns.enumerateLines { (str, _) in
            if error.error != nil { return }
            error.line = lineNumber
            
            let level = (str.prefix(while: {$0 == " "}).count) / 4
            if level < lastLevel {
                // Drop the last branch when indention decreases
                currentBranch = currentBranch.dropLast()
            }
    
            //
            
            var processed = false
            var leftOfComment : String

            if str.firstIndex(of: "#") != nil {
                let split = str.split(separator: "#")
                if split.count == 2 {
                    leftOfComment = String(str.split(separator: "#")[0])
                } else {
                    leftOfComment = ""
                }
            } else {
                leftOfComment = str
            }
            
            leftOfComment = leftOfComment.trimmingCharacters(in: .whitespaces)
            
            var variableName : String? = nil
            // --- Check for variable assignment
            let values = leftOfComment.split(separator: "=")
            if values.count == 2 {
                variableName = String(values[0]).trimmingCharacters(in: .whitespaces)
                leftOfComment = String(values[1])
            }

            if leftOfComment.count > 0 {
                let arguments = leftOfComment.split(separator: " ", omittingEmptySubsequences: true)
                if arguments.count > 0 {
                    //print(level, arguments)
                    
                    let cmd = arguments[0].trimmingCharacters(in: .whitespaces)
                    if cmd == "tree" {
                        if arguments.count >= 2 {
                            let name = arguments[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)

                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: name)) {
                                if level == 0 {
                                    currentTree = BehaviorTree(name)
                                    asset.behavior!.trees.append(currentTree!)
                                    currentBranch = []
                                    processed = true
                                    
                                    // Rest of the parameters are incoming variables
                                    
                                    if arguments.count > 2 {
                                        var variablesString = ""
                                        
                                        for index in 2..<arguments.count {
                                            variablesString += arguments[index].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                                        }
                                        
                                        var rightValueArray = variablesString.split(separator: "<")
                                        while rightValueArray.count > 1 {
                                            let possibleVar = rightValueArray[0].lowercased()
                                            let varName = String(rightValueArray[1].dropLast())
                                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: varName)) {
                                                if possibleVar == "int" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Int1(0)))
                                                } else
                                                if possibleVar == "float" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float1(0)))
                                                } else
                                                if possibleVar == "float2" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float2(0,0)))
                                                } else
                                                if possibleVar == "float3" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float3(0,0,0)))
                                                } else
                                                if possibleVar == "float4" {
                                                    currentTree?.parameters.append(BehaviorVariable(varName, Float4(0,0,0,0)))
                                                }
                                            } else { error.error = "Invalid variable '\(varName)'" }
                                            
                                            rightValueArray = Array(rightValueArray.dropFirst(2))
                                        }
                                    }
                                }
                            } else { error.error = "Invalid name for tree '\(name)'" }
                        } else { error.error = "No name given for tree" }
                    } else {
                        var rightValueArray = leftOfComment.split(separator: "<")

                        if rightValueArray.count > 0 {
                            
                            let possbibleCmd = String(rightValueArray[0]).trimmingCharacters(in: .whitespaces)
                            
                            if variableName == nil {
                                
                                // Looking for branch
                                for branch in self.branches {
                                    if branch.name == possbibleCmd {

                                        let newBranch = branch.createNode([:])
                                        if currentBranch.count == 0 {
                                            currentTree?.leaves.append(newBranch)
                                            currentBranch.append(newBranch)
                                        } else {
                                            if let branch = currentBranch.last {
                                                branch.leaves.append(newBranch)
                                            }
                                        }
                                        processed = true
                                    }
                                }
                                
                                if processed == false {
                                    // Looking for leave
                                    for leave in self.leaves {
                                        if leave.name == possbibleCmd {
                                            
                                            var options : [String: String] = [:]
                                            
                                            // Fill in options
                                            rightValueArray.removeFirst()
                                            if rightValueArray.count == 1 && rightValueArray[0] == ">" {
                                                // Empty Arguments
                                            } else {
                                                while rightValueArray.count > 0 {
                                                    let array = rightValueArray[0].split(separator: ":")
                                                    //print("2", array)
                                                    rightValueArray.removeFirst()
                                                    if array.count == 2 {
                                                        let optionName = array[0].lowercased().trimmingCharacters(in: .whitespaces)
                                                        var values = array[1].trimmingCharacters(in: .whitespaces)
                                                        //print("option", optionName, "value", values)
                                                                                            
                                                        if values.count > 0 && values.last! != ">" {
                                                            createError("No closing '>' for option '\(optionName)'")
                                                        } else {
                                                            values = String(values.dropLast())
                                                        }
                                                        options[optionName] = String(values)
                                                    } else { createError(); rightValueArray = [] }
                                                }
                                            }
                                            
                                            let nodeOptions = self.parser_processOptions(options, &error)
                                            if error.error == nil {
                                                if let branch = currentBranch.last {
                                                    let behaviorNode = leave.createNode(nodeOptions)
                                                    behaviorNode.verifyOptions(context: asset.behavior!, tree: currentTree!, error: &error)
                                                    if error.error == nil {
                                                        behaviorNode.lineNr = error.line!
                                                        branch.leaves.append(behaviorNode)
                                                        processed = true
                                                    }
                                                } else { createError("Leaf node without active branch") }
                                            }
                                        }
                                    }
                                }
                            } else
                            if rightValueArray.count > 1 {
                                // Variable
                                let possibleVariableType = rightValueArray[0].trimmingCharacters(in: .whitespaces)
                                if possibleVariableType == "Float4" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 4 {
                                        
                                        let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
                                        let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                                        let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 0 }
                                        let w : Float; if let v = Float(array[3].dropLast().trimmingCharacters(in: .whitespaces)) { w = v } else { w = 0 }

                                        let value = Float4(x, y, z, w)
                                        asset.behavior!.addVariable(variableName!, value)
                                        processed = true
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float3" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 3 {
                                        
                                        let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
                                        let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                                        let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 0 }

                                        let value = Float3(x, y, z)
                                        asset.behavior!.addVariable(variableName!, value)
                                        processed = true
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float2" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 2 {
                                        
                                        let x : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { x = v } else { x = 0 }
                                        let y : Float; if let v = Float(array[1].dropLast().trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }

                                        let value = Float2(x, y)
                                        asset.behavior!.addVariable(variableName!, value)
                                        processed = true
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float" {
                                    rightValueArray.removeFirst()
                                    let value : Float; if let v = Float(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces)) { value = v } else { value = 0 }
                                    asset.behavior!.addVariable(variableName!, Float1(value))
                                    processed = true
                                } else
                                if possibleVariableType == "Int" {
                                    rightValueArray.removeFirst()
                                    let value : Int; if let v = Int(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces)) { value = v } else { value = 0 }
                                    asset.behavior!.addVariable(variableName!, Int1(value))
                                    processed = true
                                } else
                                if possibleVariableType == "Text" {
                                    rightValueArray.removeFirst()
                                    let v = String(rightValueArray[0].dropLast().trimmingCharacters(in: .whitespaces))
                                    asset.behavior!.addVariable(variableName!, TextRef(v))
                                    processed = true
                                } else { error.error = "Unrecognized Variable type '\(possbibleCmd)'" }
                            }
                        }
                    }
                }
                if str.trimmingCharacters(in: .whitespaces).count > 0 && processed == false && error.error == nil {
                    error.error = "Unrecognized statement"
                }
            }
            
            lastLevel = level
            lineNumber += 1
        }
        
        if game.state == .Idle {
            if error.error != nil {
                error.line = error.line! + 1
                game.scriptEditor?.setError(error)
            } else {
                game.scriptEditor?.clearAnnotations()
            }
        }

        return error
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout CompileError) -> [String:Any]
    {
        //print("Processing Options", options)

        let stringOptions = ["text", "font", "map", "scene", "key"]
        let floatOptions = ["radius", "width", "height", "size", "border", "rotation"]
        let integerOptions = ["index"]
        let float2Options = ["position"]
        let float4Options = ["rect", "color", "bordercolor"]
        let boolOptions = ["repeatx"]
        let stringArrayOptions = ["layers"]

        var res: [String:Any] = [:]
        
        for(name, value) in options {
            if stringOptions.firstIndex(of: name) != nil {
                // String
                res[name] = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
            } else
            if integerOptions.firstIndex(of: name) != nil {
                // Integer
                if let v = Int(value) {
                    res[name] = v
                } else { error.error = "The \(name) option expects an integer argument" }
            } else
            if floatOptions.firstIndex(of: name) != nil {
                // Integer
                if let v = Float(value) {
                    res[name] = v
                } else {
                    let variableName = value.trimmingCharacters(in: .whitespaces)
                    if let v = error.asset!.behavior?.getVariableValue(variableName) as? Float {
                        res[name] = v
                    } else { error.error = "Variable '\(variableName)' not found" }
                }
                //{ error.error = "The \(name) option expects an float argument" }
            } else
            if boolOptions.firstIndex(of: name) != nil {
                // Boolean
                if let v = Bool(value) {
                    res[name] = v
                } else { error.error = "The \(name) option expects an boolean argument" }
            } else
            if stringArrayOptions.firstIndex(of: name) != nil {
                // StringArray
                let array = value.split(separator: ",")
                
                var layers : [String] = []
                for l in array {
                    layers.append(l.trimmingCharacters(in: .whitespaces))
                }
                res[name] = layers
            } else
            if float2Options.firstIndex(of: name) != nil {
                // Float2
                let array = value.split(separator: ",")
                if array.count == 2 {
                    let width : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { width = v } else { width = 1 }
                    let height : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { height = v } else { height = 1 }
                    res[name] = Float2(width, height)
                } else
                if array.count == 1 {
                    let variableName = String(array[0]).trimmingCharacters(in: .whitespaces)
                    if let v = error.asset!.behavior?.getVariableValue(variableName) as? Float2 {
                        print("get", v)
                        res[name] = v
                    } else { error.error = "Variable '\(variableName)' not found" }
                } else { error.error = "Wrong argument count for Float2" }
            } else
            if float4Options.firstIndex(of: name) != nil {
                // Float4
                let array = value.split(separator: ",")
                if array.count == 4 {
                    let x : Float; if let v = Float(array[0]) { x = v } else { x = 0 }
                    let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                    let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 1 }
                    let w : Float; if let v = Float(array[3].trimmingCharacters(in: .whitespaces)) { w = v } else { w = 1 }
                    res[name] = Float4(x, y, z, w)
                } else
                if array.count == 1 {
                    let variableName = String(array[0]).trimmingCharacters(in: .whitespaces)
                    if let v = error.asset!.behavior?.getVariableValue(variableName) as? Float4 {
                        res[name] = v
                    } else { error.error = "Variable '\(variableName)' not found" }
                } else { error.error = "Wrong argument count for Float4" }
            } else {
                res[name] = value
            }//else { error.error = "Unknown option '\(name)'" }
        }
        
        return res
    }
}
