//
//  BehaviorBuilder.swift
//  Denrim
//
//  Created by Markus Moenig on 18/9/20.
//

import Foundation

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
    var cursorTimer     : Timer? = nil
    let game            : Game
    
    var branches        : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("repeat", { (_ options: [String:Any]) -> BehaviorNode in return RepeatBranch(options) }),
        BehaviorNodeItem("sequence", { (_ options: [String:Any]) -> BehaviorNode in return SequenceBranch(options) }),
        BehaviorNodeItem("selector", { (_ options: [String:Any]) -> BehaviorNode in return SelectorBranch(options) }),
        BehaviorNodeItem("while", { (_ options: [String:Any]) -> BehaviorNode in return WhileBranch(options) }),
    ]
    
    var leaves          : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("SetScene", { (_ options: [String:Any]) -> BehaviorNode in return SetScene(options) }),
        BehaviorNodeItem("Call", { (_ options: [String:Any]) -> BehaviorNode in return Call(options) }),
        BehaviorNodeItem("LuaFunction", { (_ options: [String:Any]) -> BehaviorNode in return LuaFunctionNode(options) }),
        BehaviorNodeItem("StartTimer", { (_ options: [String:Any]) -> BehaviorNode in return StartTimer(options) }),
        BehaviorNodeItem("IsKeyDown", { (_ options: [String:Any]) -> BehaviorNode in return IsKeyDown(options) }),
        BehaviorNodeItem("IsButtonDown", { (_ options: [String:Any]) -> BehaviorNode in return IsButtonDown(options) }),
        BehaviorNodeItem("Swiped", { (_ options: [String:Any]) -> BehaviorNode in return Swiped(options) }),
        BehaviorNodeItem("GetTouchPos", { (_ options: [String:Any]) -> BehaviorNode in return GetTouchPos(options) }),
        BehaviorNodeItem("HasDoubleTap", { (_ options: [String:Any]) -> BehaviorNode in return HasDoubleTap(options) }),
        BehaviorNodeItem("HasTouch", { (_ options: [String:Any]) -> BehaviorNode in return HasTouch(options) }),
        BehaviorNodeItem("HasTap", { (_ options: [String:Any]) -> BehaviorNode in return HasTap(options) }),
        BehaviorNodeItem("DistanceToShape", { (_ options: [String:Any]) -> BehaviorNode in return DistanceToShape(options) }),
        BehaviorNodeItem("ShapeContactCount", { (_ options: [String:Any]) -> BehaviorNode in return ShapeContactCount(options) }),
        BehaviorNodeItem("RandomColor", { (_ options: [String:Any]) -> BehaviorNode in return RandomColorNode(options) }),
        BehaviorNodeItem("Random", { (_ options: [String:Any]) -> BehaviorNode in return RandomNode(options) }),
        BehaviorNodeItem("Log", { (_ options: [String:Any]) -> BehaviorNode in return LogNode(options) }),

        BehaviorNodeItem("PlayAudio", { (_ options: [String:Any]) -> BehaviorNode in return PlayAudioNode(options) }),

        BehaviorNodeItem("Set", { (_ options: [String:Any]) -> BehaviorNode in return SetNode(options) }),
        BehaviorNodeItem("IsVariable", { (_ options: [String:Any]) -> BehaviorNode in return IsVariable(options) }),
        BehaviorNodeItem("IsComponent", { (_ options: [String:Any]) -> BehaviorNode in return IsComponent(options) }),

        BehaviorNodeItem("CreateInstance2D", { (_ options: [String:Any]) -> BehaviorNode in return CreateInstance2D(options) }),
        BehaviorNodeItem("DestroyInstance2D", { (_ options: [String:Any]) -> BehaviorNode in return DestroyInstance2D(options) }),
        
        BehaviorNodeItem("SetVisible", { (_ options: [String:Any]) -> BehaviorNode in return SetVisible(options) }),
        BehaviorNodeItem("SetActive", { (_ options: [String:Any]) -> BehaviorNode in return SetActive(options) }),
        BehaviorNodeItem("GetLinearVelocity2D", { (_ options: [String:Any]) -> BehaviorNode in return GetLinearVelocity2D(options) }),
        BehaviorNodeItem("SetLinearVelocity2D", { (_ options: [String:Any]) -> BehaviorNode in return SetLinearVelocity2D(options) }),
        BehaviorNodeItem("ApplyForce2D", { (_ options: [String:Any]) -> BehaviorNode in return ApplyForce2D(options) }),

        BehaviorNodeItem("SetPosition2D", { (_ options: [String:Any]) -> BehaviorNode in return SetPosition2D(options) }),

        BehaviorNodeItem("IsVisible", { (_ options: [String:Any]) -> BehaviorNode in return IsVisible(options) }),

        BehaviorNodeItem("ApplyTexture2D", { (_ options: [String:Any]) -> BehaviorNode in return ApplyTexture2D(options) }),
        BehaviorNodeItem("ApplyTextureFlip2D", { (_ options: [String:Any]) -> BehaviorNode in return ApplyTextureFlip2D(options) }),
        
        BehaviorNodeItem("SetCamera2D", { (_ options: [String:Any]) -> BehaviorNode in return SetCamera2D(options) }),

        BehaviorNodeItem("MoveTo2D", { (_ options: [String:Any]) -> BehaviorNode in return MoveTo2D(options) }),
        BehaviorNodeItem("Length", { (_ options: [String:Any]) -> BehaviorNode in return LengthNode(options) }),
        BehaviorNodeItem("Distance", { (_ options: [String:Any]) -> BehaviorNode in return DistanceNode(options) }),

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
        
        let behavior = asset.behavior!
        
        let ns = asset.value as NSString
        var lineNumber  : Int32 = 0
        
        var currentTree     : BehaviorTree? = nil
        var currentBranch   : [BehaviorNode] = []
        var lastLevel       : Int = -1

        ns.enumerateLines { (str, _) in
            if error.error != nil { return }
            error.line = lineNumber
            
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
            
            // Get the current indention level
            let level = (str.prefix(while: {$0 == " "}).count) / 4

            leftOfComment = leftOfComment.trimmingCharacters(in: .whitespaces)
            
            // If empty, bail out, nothing todo
            if leftOfComment.count == 0 {
                lineNumber += 1
                return
            }
            
            // Drop the last branch when indention decreases
            if level < lastLevel {
                let levelsToDrop = lastLevel - level
                //print("dropped at line", error.line, "\"", str, "\"", level, levelsToDrop)
                for _ in 0..<levelsToDrop {
                    currentBranch = currentBranch.dropLast()
                }
            }
            
            var variableName : String? = nil
            var assignmentType : GraphVariableAssignmentNode.AssignmentType = .Copy

            // --- Check for variable assignment
            if leftOfComment.contains("="){
             
                var values : [String] = []
                
                if leftOfComment.contains("*=") {
                    assignmentType = .Multiply
                    values = leftOfComment.components(separatedBy: "*=")
                } else
                if leftOfComment.contains("/=") {
                    assignmentType = .Divide
                    values = leftOfComment.components(separatedBy: "/=")
                } else
                if leftOfComment.contains("+=") {
                    assignmentType = .Add
                    values = leftOfComment.components(separatedBy: "+=")
                } else
                if leftOfComment.contains("-=") {
                    assignmentType = .Subtract
                    values = leftOfComment.components(separatedBy: "+=")
                } else {
                    values = leftOfComment.components(separatedBy: "=")
                }
                
                if values.count == 2 {
                    variableName = String(values[0]).trimmingCharacters(in: .whitespaces)
                    leftOfComment = String(values[1])
                }
            }
            
            /// Splits the option string into a possible command and its <> enclosed options
            func splitIntoCommandPlusOptions(_ string: String,_ error: inout CompileError) -> [String]
            {
                var rc : [String] = []
                
                if let first = string.firstIndex(of: "<")?.utf16Offset(in: string) {

                    let index = string.index(string.startIndex, offsetBy: first)
                    let possibleCommand = string[..<index]//string.prefix(index)
                    rc.append(String(possibleCommand))
                    
                    //let rest = string[index...]
                    
                    var offset      : Int = first
                    var hierarchy   : Int = -1
                    var option      = ""
                    
                    while offset < string.count {
                        if string[offset] == "<" {
                            if hierarchy >= 0 {
                                option.append(string[offset])
                            }
                            hierarchy += 1
                        } else
                        if string[offset] == ">" {
                            if hierarchy == 0 {
                                rc.append(option)
                                option = ""
                                hierarchy = -1
                            } else
                            if hierarchy < 0 {
                                error.error = "Syntax Error"
                            } else {
                                hierarchy -= 1
                                if hierarchy >= 0 {
                                    option.append(string[offset])
                                }
                            }
                        } else {
                            option.append(string[offset])
                        }
                        
                        offset += 1
                    }
                    if option.isEmpty == false && error.error == nil {
                        error.error = "Syntax Error: \(option)"
                    }
                }
                               
                return rc
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
                                    asset.behavior!.lines[error.line!] = "tree"

                                    // Rest of the parameters are incoming variables
                                    
                                    if arguments.count > 2 {
                                        var variablesString = ""
                                        
                                        for index in 2..<arguments.count {
                                            var string = arguments[index].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                                            string = string.replacingOccurrences(of: ">", with: "<")
                                            variablesString += string
                                        }
                                        
                                        var rightValueArray = variablesString.split(separator: "<")
                                        while rightValueArray.count > 1 {
                                            let possibleVar = rightValueArray[0].lowercased()
                                            let varName = String(rightValueArray[1])
                                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: varName)) {
                                                if possibleVar == "int" {
                                                    currentTree?.parameters.append(Int1(varName, 0))
                                                } else
                                                if possibleVar == "bool" {
                                                    currentTree?.parameters.append(Bool1(varName))
                                                } else
                                                if possibleVar == "float" {
                                                    currentTree?.parameters.append(Float1(varName, 0))
                                                } else
                                                if possibleVar == "float2" {
                                                    currentTree?.parameters.append(Float2(varName, 0,0))
                                                } else
                                                if possibleVar == "float3" {
                                                    currentTree?.parameters.append(Float3(varName, 0,0,0))
                                                } else
                                                if possibleVar == "float4" {
                                                    currentTree?.parameters.append(Float4(varName, 0,0,0,0))
                                                }
                                            } else { error.error = "Invalid variable '\(varName)'" }
                                            
                                            rightValueArray = Array(rightValueArray.dropFirst(2))
                                        }
                                        
                                        behavior.parameters = currentTree!.parameters
                                    }
                                }
                            } else { error.error = "Invalid name for tree '\(name)'" }
                        } else { error.error = "No name given for tree" }
                    }
                }
                
                if processed == false {
                    var rightValueArray : [String]
                        
                    if variableName == nil {
                        rightValueArray = splitIntoCommandPlusOptions(leftOfComment, &error)
                        if rightValueArray.isEmpty {
                            rightValueArray = [leftOfComment]
                        }
                    } else {
                        rightValueArray = [leftOfComment]
                    }
                                                            
                    if rightValueArray.count > 0 && error.error == nil {
                        
                        var possibleCmd = String(rightValueArray[0]).trimmingCharacters(in: .whitespaces)
                        let cmdSplit = possibleCmd.split(separator: " ")
                        if cmdSplit.count > 1 {
                            possibleCmd = String(cmdSplit[0])
                        }
                        
                        if variableName == nil {
                            
                            // Looking for branch
                            for branch in self.branches {
                                if branch.name == possibleCmd {
                                    
                                    // Build options
                                    var nodeOptions : [String:String] = [:]
                                    var no = leftOfComment.split(separator: " ")
                                    no.removeFirst()
                                    
                                    for s in no {
                                        let ss = String(s)
                                        nodeOptions[ss] = ss
                                    }

                                    let newBranch = branch.createNode(nodeOptions)
                                    
                                    newBranch.verifyOptions(context: asset.behavior!, tree: currentTree!, error: &error)
                                    if error.error == nil {
                                        if currentBranch.count == 0 {
                                            currentTree?.leaves.append(newBranch)
                                            currentBranch.append(newBranch)
                                            
                                            newBranch.lineNr = error.line!
                                            asset.behavior!.lines[error.line!] = newBranch.name
                                        } else {
                                            if let branch = currentBranch.last {
                                                branch.leaves.append(newBranch)
                                                
                                                newBranch.lineNr = error.line!
                                                asset.behavior!.lines[error.line!] = newBranch.name
                                            }
                                            currentBranch.append(newBranch)
                                        }
                                        processed = true
                                    }
                                }
                            }
                            
                            if processed == false {
                                // Looking for leave
                                for leave in self.leaves {
                                    if leave.name == possibleCmd {
                                        
                                        var options : [String: String] = [:]
                                        
                                        // Fill in options
                                        rightValueArray.removeFirst()
                                        if rightValueArray.count == 1 && rightValueArray[0] == "" {
                                            // Empty Arguments
                                        } else {
                                            while rightValueArray.count > 0 {
                                                let array = rightValueArray[0].split(separator: ":")
                                                //print("2", array)
                                                rightValueArray.removeFirst()
                                                if array.count == 2 {
                                                    let optionName = array[0].lowercased().trimmingCharacters(in: .whitespaces)
                                                    let values = array[1].trimmingCharacters(in: .whitespaces)

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
                                                    asset.behavior!.lines[error.line!] = behaviorNode.name
                                                    processed = true
                                                }
                                            } else { createError("Leaf node without active branch") }
                                        }
                                    }
                                }
                            }
                        } else
                        if var variableName = variableName {
                            
                            // Variable assignment
                            let rightSide = leftOfComment.trimmingCharacters(in: .whitespaces)
                            //print(variableName, "rightSide", rightSide)
                            let exp = ExpressionContext()
                            exp.parse(expression: rightSide, container: asset.behavior!, error: &error)
                            
                            if error.error == nil {
                                
                                var branch = currentBranch.last
                                if branch == nil {
                                    if let tree = currentTree {
                                        branch = tree
                                    }
                                }
                                
                                if let branch = branch {
                                    
                                    var assignmentComponents : Int = 0
                                    
                                    if variableName.contains(".") {
                                        let array = variableName.split(separator: ".")
                                        if array.count == 2 {
                                            variableName = String(array[0])
                                            assignmentComponents = array[1].count
                                        }
                                    }
                                    
                                    let variableNode = VariableAssignmentNode()
                                    variableNode.givenName = variableName
                                    variableNode.assignmentComponents = assignmentComponents
                                    variableNode.assignmentType = assignmentType
                                    variableNode.expression = exp
                                    
                                    variableNode.execute(game: self.game, context: behavior, tree: currentTree)
                                    
                                    variableNode.lineNr = error.line!
                                    branch.leaves.append(variableNode)
                                    asset.behavior!.lines[error.line!] = variableNode.name
                                    processed = true
                                } else
                                if error.error == nil { createError("Leaf node without active branch") }
                            } else { createError("Invalid expression") }
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
        
        behavior.parameters = nil
        
        return error
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout CompileError) -> [String:Any]
    {
        //print("Processing Options", options)

        var res: [String:Any] = [:]
        
        for(name, value) in options {
            res[name] = value
        }
        
        return res
    }
    
    func startTimer(_ asset: Asset)
    {
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: 0.2,
                                             target: self,
                                             selector: #selector(self.cursorCallback),
                                             userInfo: nil,
                                             repeats: true)
            self.cursorTimer = timer
        })
    }
    
    func stopTimer()
    {
        if cursorTimer != nil {
            cursorTimer?.invalidate()
            cursorTimer = nil
        }
    }
    
    @objc func cursorCallback(_ timer: Timer) {
        if game.state == .Idle && game.scriptEditor != nil {
            game.scriptEditor!.getSessionCursor({ (line, _) in
                if let asset = self.game.assetFolder.current, asset.type == .Behavior {
                    if let context = asset.behavior {
                        if let name = context.lines[line] {
                            if name != self.game.contextKey {
                                if let helpText = self.game.scriptEditor!.getBehaviorHelpForKey(name) {
                                    self.game.contextText = helpText
                                    self.game.contextKey = name
                                    self.game.contextTextChanged.send(self.game.contextText)

                                }
                            }
                        } else {
                            if self.game.contextKey != "BehaviorHelp" {
                                self.game.contextText = self.game.scriptEditor!.behaviorHelpText
                                self.game.contextKey = "BehaviorHelp"
                                self.game.contextTextChanged.send(self.game.contextText)
                            }
                        }
                    }
                }
            })
        }
    }
}
