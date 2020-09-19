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
        BehaviorNodeItem("Sequence", { (_ options: [String:Any]) -> BehaviorNode in return BehaviorNode(options) })
    ]
    
    var leaves          : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("Clear", { (_ options: [String:Any]) -> BehaviorNode in return Clear(options) }),
        BehaviorNodeItem("DrawDisk", { (_ options: [String:Any]) -> BehaviorNode in return DrawDisk(options) })
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
        
        print("compile")
        let ns = asset.value as NSString
        var lineNumber  : Int32 = 0
        
        var currentTree     : BehaviorTree? = nil
        var currentBranch   : BehaviorNode? = nil
        var lastLevel       : Int = -1

        ns.enumerateLines { (str, _) in
            if error.error != nil { return }
            error.line = lineNumber
            
            let level = (str.prefix(while: {$0 == " "}).count) / 4
            //print(str, level)
            
            //
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
                        if arguments.count == 2 {
                            let name = arguments[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)

                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: name)) {
                                if level == 0 {
                                    //print("new tree", name)
                                    currentTree = BehaviorTree(name)
                                    currentBranch = currentTree
                                    asset.behavior!.trees.append(currentTree!)
                                }
                            } else { error.error = "Invalid name for tree '\(name)'" }
                        } else { error.error = "No name given for tree" }
                    } else {
                        var rightValueArray = leftOfComment.split(separator: "<")

                        if rightValueArray.count > 0 {
                            
                            let possbibleCmd = String(rightValueArray[0]).trimmingCharacters(in: .whitespaces)
                            
                            if variableName == nil {
                                
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
                                        //print(options, nodeOptions)
                                        if error.error == nil {
                                            currentBranch?.leaves.append(leave.createNode(nodeOptions))
                                        }
                                    }
                                }
                            } else {
                                // Variable
                                let possibleVariableType = rightValueArray[0].trimmingCharacters(in: .whitespaces)
                                if possibleVariableType == "Float2" {
                                    rightValueArray.removeFirst()
                                    let array = rightValueArray[0].split(separator: ",")
                                    if array.count == 2 {
                                        let left = array[0].lowercased().trimmingCharacters(in: .whitespaces)
                                        let right = array[1].lowercased().dropLast().trimmingCharacters(in: .whitespaces)
                                        if left.isEmpty == false && right.isEmpty == false {
                                            let xValue : Float? = Float(left)
                                            let yValue : Float? = Float(right)
                                            if xValue != nil && yValue != nil {
                                                let value = Float2(Float(left)!, Float(right)!)
                                                asset.behavior!.addVariable(variableName!, value)
                                            } else { createError() }
                                        } else { createError() }
                                    } else { createError() }
                                } else
                                if possibleVariableType == "Float" {
                                    rightValueArray.removeFirst()
                                    let value = rightValueArray[0].lowercased().dropLast().trimmingCharacters(in: .whitespaces)
                                    if let floatValue = Float(value) {
                                        asset.behavior!.addVariable(variableName!, floatValue)
                                    } else { createError() }
                                }
                            }
                        }
                    }
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
        print("Processing Options", options)

        let stringOptions = ["group", "id", "class", "physics", "mode", "object"]
        let floatOptions = ["radius"]
        let integerOptions = ["index"]
        let vec2Options = ["sceneoffset", "range", "gravity", "position", "box"]
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
            if vec2Options.firstIndex(of: name) != nil {
                // vec2
                let array = value.split(separator: ",")
                if array.count == 2 {
                    let width : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { width = v } else { width = 1 }
                    let height : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { height = v } else { height = 1 }
                    res[name] = Float2(width, height)
                } else
                if array.count == 1 {
                    let variableName = String(array[0]).trimmingCharacters(in: .whitespaces)
                    if let v = error.asset!.behavior?.getVariableValue(variableName) as? Float2 {
                        res[name] = v
                    } else { error.error = "Variable '\(variableName)' not found" }
                } else { error.error = "Wrong argument count for Vec2" }
            }
            if name == "rect" {
                let array = value.split(separator: ",")
                if array.count == 4 {
                    let x : Float; if let v = Float(array[0]) { x = v } else { x = 0 }
                    let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                    let width : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { width = v } else { width = 1 }
                    let height : Float; if let v = Float(array[3].trimmingCharacters(in: .whitespaces)) { height = v } else { height = 1 }
                    res[name] = Rect2D(x, y, width, height)
                } else { error.error = "Rect must have 4 arguments" }
            }
        }
        
        return res
    }
}
