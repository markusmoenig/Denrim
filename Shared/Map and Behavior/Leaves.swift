//
//  Leaves.swift
//  Denrim
//
//  Created by Markus Moenig on 19/9/20.
//

import Foundation
import simd

/// VariableAssignmentNode, assign or modify a variable via assignment, =, *=, -= etc
final class VariableAssignmentNode : BehaviorNode
{
    /// The right handed expression the variables gets assigned to
    var expression                  : ExpressionContext? = nil
    /// The components  of the assignment (like outColor.xyz has 3 assignment components)
    var assignmentComponents        : Int = 0
    /// The assignment type
    var assignmentType              : GraphVariableAssignmentNode.AssignmentType = .Copy
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "VariableAsignment"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let expression = expression {
            // Assign to existing variable
            if let existing = context.variables[givenName] {
                if let v = expression.execute() {
                    existing.role = expression.isConstant() ? .User : .System
                    if v.getType() == .Float && (assignmentType == .Multiply || assignmentType == .Divide) {
                        existing.assignFromFloat(from: v, using: assignmentType, upTo: assignmentComponents)
                    } else {
                        existing.role = expression.isConstant() ? .User : .System
                        existing.assign(from: v, using: assignmentType)
                    }
                }
            } else {
                // New variable
                
                context.variables[givenName] = expression.execute()//expression.values.last!
                if context.variables[givenName] != nil {
                    context.variables[givenName]!.role = expression.isConstant() ? .User : .System
                }
            }
        }
        return .Success
    }
}

// Logs the given variables
class LogNode: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Log"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        var text: String = ""
        for (_, exp) in options {
            if let string = exp as? String {
                if let value = context.getVariableValue(string) {
                    if let v = value as? Int1 {
                        text += string + " " + String(v.x)
                    } else
                    if let v = value as? Float1 {
                        text += string + " " + String(v.x)
                    } else
                    if let v = value as? Float2 {
                        text += string + " <" + String(v.x) + ", " + String(v.y) + ">"
                    } else
                    if let v = value as? Text1 {
                        text += string + v.name
                    }
                } else {
                    text += text + " " + string
                }
            }
        }
        game.logText.append(text + "\n")
        return .Success
    }
}

// Plays audio
class PlayAudioNode: BehaviorNode
{
    var audioId: String? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "PlayAudio"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["id"] as? String {
            audioId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "PlayAudio requires an 'id' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let audioId = audioId {
            if let player = game.localAudioPlayers[audioId] {
                player.stop()
                player.currentTime = 0
                player.play()
                return .Success
            } else
            if let player = game.globalAudioPlayers[audioId] {
                player.stop()
                player.currentTime = 0
                player.play()
                return .Success
            }
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Sets the tick interval for the game
class TickNode: BehaviorNode
{
    var game                : Game? = nil
    var interval            : Float1? = nil

    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Tick"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        
        if let value = extractFloat1Value(options, container: context, error: &error, name: "interval") {
            interval = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        self.game = game
        
        if let timer = game.tickTimer {
            timer.invalidate()
            game.tickTimer = nil
        }
     
        game.tickTimer = Timer.scheduledTimer(timeInterval: Double(interval!.x), target: self, selector: #selector(callGameTick), userInfo: nil, repeats: true)
        
        return .Success
    }    
    
    @objc func callGameTick() {
        if let game = game {
            //DispatchQueue.main.async {
                game.executeGameTree("tick")
            //}
        }
    }
}

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
        if let value = options["sceneid"] as? String {
            sceneName = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetScene requires a 'SceneId' parameter"
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
                                map.camera2D.clear()
                                map.createDependencies(scene)
                                game.view.reset()
                                // Add Game Behavior
                                if let gameAsset = game.gameAsset {
                                    let gameBehavior = MapBehavior(behaviorAsset: gameAsset, name: "game", options: [:])
                                    map.behavior["game"] = gameBehavior
                                    return .Success
                                }
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

// Runs a given lua script function
class LuaFunctionNode: BehaviorNode
{
    var parameters          : [BaseVariable] = []

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "LuaFunction"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if options["script"] as? String == nil {
            error.error = "LuaFunction requires a 'Script' parameter"
        }
        
        if let value = options["parameters"] as? String {
            let array = value.split(separator: ",")

            for v in array {
                let val = String(v.trimmingCharacters(in: .whitespaces))
                
                if let v = context.getVariableValue(val) {
                    parameters.append(v)
                } else {
                    error.error = "Variable '\(val)' not found"
                }
            }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let scriptName = options["script"] as? String {

            if let variable = context.variables[prepVariableName(scriptName)] as? Lua1 {
                
                if var functionName = options["function"] as? String {

                    functionName = prepVariableName(functionName)
                    
                    if let variable = context.getVariableValue(functionName) as? Text1 {
                        functionName = variable.text
                    }
                    
                    game.luaBuilder.runLuaFunction(variable, context: context, functionName: functionName)
                    
                    return .Success
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
    var isVariable          : Bool = false
    
    var parameters          : [BaseVariable] = []

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Call"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if options["tree"] as? String == nil && options["tree"] as? Text1 == nil {
            error.error = "Call requires a 'Tree' parameter"
        }
        
        if let value = options["variables"] as? String {
            let array = value.split(separator: ",")

            for v in array {
                let val = String(v.trimmingCharacters(in: .whitespaces))
                
                if let v = context.getVariableValue(val) {
                    parameters.append(v)
                } else {
                    error.error = "Variable '\(val)' not found"
                }
            }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if firstCall || isVariable {
            firstCall = false
            
            if isVariable {
                treeName = nil
            }
            
            var treeName : String? = nil
            callContext = []
                        
            if var name = options["tree"] as? String {
                name = prepVariableName(name)
                if let variable = context.getVariableValue(name) as? Text1 {
                    treeName = variable.text
                    isVariable = true
                } else {
                    treeName = name
                }
            }
            
            if var treeName = treeName {
                treeName = treeName.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
                let treeArray = treeName.split(separator: ".")
                if treeArray.count == 1 {
                    // No ., tree has to be in the same context
                    callContext.append(context)
                    self.treeName = treeName
                } else
                if treeArray.count == 2 {
                    
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
                                    if let instances = behavior.instances {
                                        for inst in instances.pairs {
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
                            if let dest = param as? Int1 {
                                if let source = variable as? Int1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param as? Bool1 {
                                if let source = variable as? Bool1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param as? Float1 {
                                if let source = variable as? Float1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param as? Float2 {
                                if let source = variable as? Float2 {
                                    dest.x = source.x
                                    dest.y = source.y
                                }
                            } else
                            if let dest = param as? Float3 {
                                if let source = variable as? Float3 {
                                    dest.x = source.x
                                    dest.y = source.y
                                    dest.z = source.z
                                }
                            } else
                            if let dest = param as? Float4 {
                                if let source = variable as? Float4 {
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
        
        if let treeName = treeName {
            for context in callContext {
                context.execute(name: treeName)
            }
            return .Success
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Calls a given tree every x.x seconds
class StartTimer: BehaviorNode
{
    var callContext         : [BehaviorContext] = []
    var callTree            : BehaviorTree? = nil
    var treeName            : String? = nil
    
    var interval            : Float1? = nil
    
    var firstCall           : Bool = true
    var parameters          : [BaseVariable] = []
    
    var once                : Bool = false

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "StartTimer"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if options["tree"] as? String == nil {
            error.error = "Call requires a 'Tree' parameter"
        }
        
        if let value = extractFloat1Value(options, container: context, error: &error, name: "interval") {
            interval = value
        }
        
        if let value = options["once"] as? String {
            if value.lowercased() == "true" {
                once = true
            }
        }
        
        if let value = options["variables"] as? String {
            let array = value.split(separator: ",")

            for v in array {
                let val = String(v.trimmingCharacters(in: .whitespaces))
                var foundVar : BaseVariable? = nil
                for (_,variable) in context.variables {
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
            if var treeName = options["tree"] as? String {
                treeName = treeName.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
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
                                    if let instances = behavior.instances {
                                        for inst in instances.pairs {
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
            if game.state == .Running {
                if let map = game.currentMap?.map {
                    let timer = Timer.scheduledTimer(timeInterval: Double(interval!.x), target: self, selector: #selector(callTreeTimer), userInfo: nil, repeats: !once)
                    map.timer.append(timer)
                }
            }
            return .Success
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
    
    @objc func callTreeTimer()
    {
        if treeName != nil {
            for context in callContext {
                if let tree = context.getTree(treeName!) {
                    // Now replace the values in the tree parameters with the variable values which we pass to the tree
                    for (index, variable) in parameters.enumerated() {
                        if index < tree.parameters.count {
                            let param = tree.parameters[index]
                            if let dest = param as? Int1 {
                                if let source = variable as? Int1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param as? Bool1 {
                                if let source = variable as? Bool1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param as? Float1 {
                                if let source = variable as? Float1 {
                                    dest.x = source.x
                                }
                            } else
                            if let dest = param as? Float2 {
                                if let source = variable as? Float2 {
                                    dest.x = source.x
                                    dest.y = source.y
                                }
                            } else
                            if let dest = param as? Float3 {
                                if let source = variable as? Float3 {
                                    dest.x = source.x
                                    dest.y = source.y
                                    dest.z = source.z
                                }
                            } else
                            if let dest = param as? Float4 {
                                if let source = variable as? Float4 {
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
        }
    }
}

// Applies a texture to the given shape
class ApplyTexture2D: BehaviorNode
{
    var shapeId : String? = nil
    var id      : String? = nil

    var flipX   : Bool1? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "ApplyTexture2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "ApplyTexture2D requires a 'ShapeId' parameter"
        }
        
        if let value = options["id"] as? String {
            id = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "ApplyTexture2D requires a 'Id' parameter"
        }
        
        flipX = extractBool1Value(options, container: context, error: &error, name: "flipx", isOptional: true)
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && id != nil {
                if map.applyTextureToShape(shapeId!, id!, flipX: flipX) {
                    return .Success
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Mirrors the texture
class ApplyTextureFlip2D: BehaviorNode
{
    var shapeId : String? = nil
    var flipX   : Bool1? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "ApplyTextureFlip2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "ApplyTextureFlip2D requires a 'ShapeId' parameter"
        }
        
        flipX = extractBool1Value(options, container: context, error: &error, name: "flipx", isOptional: true)
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil {
                map.shapes2D[shapeId!]!.options.flipX = flipX == nil ? Bool1(false) : flipX!
                return .Success
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Sets the 2D camera values
class SetCamera2D: BehaviorNode
{
    var offset      : Float2? = nil
    var center      : Bool1? = nil

    var zoom        = Float1(1)

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetCamera2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        
        if let value = extractFloat2Value(options, container: context, error: &error, name: "offset", isOptional: true) {
            offset = value
        }
        if let value = extractBool1Value(options, container: context, error: &error, name: "center", isOptional: true) {
            center = value
        }
        if let value = extractFloat1Value(options, container: context, error: &error, name: "zoom", isOptional: true) {
            zoom = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if let offset = offset {

                if let gridSize = map.getGridSize() {
                    if center == nil || center!.x == false {
                        map.camera2D.xOffset = offset.x * map.aspect.x * gridSize.0.x
                        map.camera2D.yOffset = offset.y * map.aspect.y * gridSize.0.y
                    } else {
                        var off = offset.toSIMD2()
                        
                        let minX = 5 * gridSize.0.x
                        let minY = 5 * gridSize.0.y

                        off.x *= gridSize.0.x
                        off.y *= gridSize.0.y
                        
                        let xOffset = max(minX, off.x)
                        let yOffset = max(minY, off.y)

                        map.camera2D.xOffset = minX - xOffset
                        map.camera2D.yOffset = minY - yOffset
                    }
                } else {
                    if center == nil || center!.x == false {
                        map.camera2D.xOffset = offset.x * map.aspect.x
                        map.camera2D.yOffset = offset.y * map.aspect.y
                    } else {
                        let xOffset = max(50, offset.x)
                        let yOffset = max(50, offset.y)

                        map.camera2D.xOffset = 50.0 - xOffset
                        map.camera2D.yOffset = 50.0 - yOffset
                        
                        map.camera2D.xOffset *= map.aspect.x
                        map.camera2D.yOffset *= map.aspect.y
                    }
                }
            }
        }
        return .Success
    }
}

// Moves a float2 variable towards a 2D position given a certain step size
class MoveTo2D: BehaviorNode
{
    var variable    : Float2? = nil
    var destination : Float2? = nil

    var step        = Float1(1)

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "MoveTo2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        
        if let value = extractFloat2Value(options, container: context, error: &error, name: "variable") {
            variable = value
        }
        if let value = extractFloat2Value(options, container: context, error: &error, name: "destination") {
            destination = value
        }
        if let value = extractFloat1Value(options, container: context, error: &error, name: "step", isOptional: true) {
            step = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        let dx = destination!.x - variable!.x
        let dy = destination!.y - variable!.y
        
        let angle = atan2(dy, dx)
        
        variable!.x = step.x * cos(angle)
        variable!.y = step.x * sin(angle)

        return .Success
    }
}

// Gets the linear velocity for a given shape
class GetLinearVelocity2D: BehaviorNode
{
    var shapeId: String? = nil
    var f2: Float2? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "GetLinearVelocity2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "GetLinearVelocity2D requires a 'ShapeId' parameter"
        }
        
        if let value = extractFloat2Value(options, container: context, error: &error, name: "variable") {
            f2 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && f2 != nil {
                if let shape = map.shapes2D[shapeId!] {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                if let body = inst.0.body {
                                    let velocity = body.m_linearVelocity
                                    f2!.x = velocity.x
                                    f2!.y = velocity.y
                                    return .Success
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        let velocity = body.m_linearVelocity
                        f2!.x = velocity.x
                        f2!.y = velocity.y
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Set physics 2D position
class SetPosition2D: BehaviorNode
{
    var shapeId: String? = nil
    var f2: Float2? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetPosition2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetPosition2D requires a 'ShapeId' parameter"
        }
        
        if let value = extractFloat2Value(options, container: context, error: &error) {
            f2 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && f2 != nil {
                if let shape = map.shapes2D[shapeId!], shape.physicsWorld != nil {
                    let ppm = shape.physicsWorld!.ppm
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                if let body = inst.0.body {
                                    body.setTransform(position: b2Vec2((f2!.x + shape.options.size.x / 2.0) / ppm, (f2!.y + shape.options.size.y / 2.0) / ppm), angle: body.angle)
                                    return .Success
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        body.setTransform(position: b2Vec2((f2!.x + shape.options.size.x / 2.0) / ppm, (f2!.y + shape.options.size.x / 2.0) / ppm), angle: body.angle)
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Sets the linear velocity for a given shape
class SetLinearVelocity2D: BehaviorNode
{
    var shapeId: String? = nil
    var f2: Float2? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetLinearVelocity2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetLinearVelocity2D requires a 'ShapeId' parameter"
        }
        
        if let value = extractFloat2Value(options, container: context, error: &error) {
            f2 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && f2 != nil {
                if let shape = map.shapes2D[shapeId!] {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                if let body = inst.0.body {
                                    body.setLinearVelocity(b2Vec2(f2!.x, f2!.y))
                                    return .Success
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        body.setLinearVelocity(b2Vec2(f2!.x, f2!.y))
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Applies force
class ApplyForce2D: BehaviorNode
{
    var shapeId: String? = nil
    var f2: Float2? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "ApplyForce2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "ApplyForce2D requires a 'ShapeId' parameter"
        }
        
        if let value = extractFloat2Value(options, container: context, error: &error) {
            f2 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && f2 != nil {
                if let shape = map.shapes2D[shapeId!] {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                if let body = inst.0.body {
                                    body.applyForceToCenter(b2Vec2(f2!.x, f2!.y), wake: true)
                                    return .Success
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        body.applyForceToCenter(b2Vec2(f2!.x, f2!.y), wake: true)
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Sets the active physics state of a shape
class SetActive: BehaviorNode
{
    var shapeId: String? = nil
    var b1: Bool1? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetActive"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetActive requires a 'ShapeId' parameter"
        }
        
        if let value = extractBool1Value(options, container: context, error: &error) {
            b1 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && b1 != nil {
                if let shape = map.shapes2D[shapeId!] {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                if let body = inst.0.body {
                                    body.setActive(b1!.x)
                                    return .Success
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        body.setActive(b1!.x)
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Sets the visible state of a shape
class SetVisible: BehaviorNode
{
    var shapeId: String? = nil
    var b1: Bool1? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetVisible"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetActive requires a 'ShapeId' parameter"
        }
        
        if let value = extractBool1Value(options, container: context, error: &error) {
            b1 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil && b1 != nil {
                if let shape = map.shapes2D[shapeId!] {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                inst.0.options.visible.x = b1!.x
                                return .Success
                            }
                        }
                    } else {
                        shape.options.visible.x = b1!.x
                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Is the shape visible ?
class IsVisible: BehaviorNode
{
    var shapeId: String? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsVisible"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["shapeid"] as? String {
            shapeId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "SetActive requires a 'ShapeId' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if shapeId != nil {
                if let shape = map.shapes2D[shapeId!] {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                if inst.0.options.visible.x == true {
                                    return .Success
                                }
                            }
                        }
                    } else {
                        if shape.options.visible.x == true {
                            return .Success
                        }
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Creates an on demand instance
class CreateInstance2D: BehaviorNode
{
    var instancerId: String? = nil
    var position2: Float2? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "CreateInstance2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["id"] as? String {
            instancerId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "CreateInstance2D requires an 'Id' parameter for the OnDemandInstance2D reference"
        }
        
        if let value = extractFloat2Value(options, container: context, error: &error, name: "position") {
            position2 = value
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if let instancer = map.onDemandInstancers[instancerId!], position2 != nil {
                let currentTime = NSDate().timeIntervalSince1970

                var canInvoke: Bool = true
                if instancer.lastInvocation > 0 {
                    if currentTime - instancer.lastInvocation < instancer.delay {
                        canInvoke = false
                    }
                }
                                
                if canInvoke {
                    if map.createOnDemandInstance(instancerId!, position2!) {
                        instancer.lastInvocation = currentTime
                    }
                    return .Success
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

// Destroy an on demand instance
class DestroyInstance2D: BehaviorNode
{
    var instancerId: String? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "DestroyInstance2D"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["id"] as? String {
            instancerId = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "DestroyInstance2D requires an 'Id' parameter for the OnDemandInstance2D reference"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map, instancerId != nil {
            if let instancer = map.onDemandInstancers[instancerId!] {
                for (index, inst) in instancer.pairs.enumerated() {
                    if inst.1.behaviorAsset.behavior === context {
                        if let body = inst.0.body {
                            if let oshape = map.shapes2D[instancer.shapeName] {
                                if let world = oshape.physicsWorld?.world {
                                    DispatchQueue.main.async {
                                        world.destroyBody(body)
                                    }
                                }
                            }
                        }
                        
                        instancer.pairs.remove(at: index)
                        map.shapes2D[inst.0.shapeName] = nil
                        map.sequences[inst.0.shapeName] = nil

                        return .Success
                    }
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class SetNode: BehaviorNode
{
    var variable            : Any? = nil
    var value               : Any? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Set"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let variable = extractVariableValue(options, variableName: "variable", container: context, error: &error) {
                        
            if variable as? Bool1 != nil {
                if let value = extractBool1Value(options, container: context, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Bool' parameter" }
            } else
            if variable as? Int1 != nil {
                if let value = extractInt1Value(options, container: context, parameters: tree.parameters, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Int' parameter" }
            } else
            if variable as? Float1 != nil {
                if let value = extractFloat1Value(options, container: context, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float' parameter" }
            } else
            if variable as? Float2 != nil {
                if let value = extractFloat2Value(options, container: context, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float2' parameter" }
            } else
            if variable as? Float3 != nil {
                if let value = extractFloat3Value(options, container: context, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float3' parameter" }
            } else
            if variable as? Float4 != nil {
                if let value = extractFloat4Value(options, container: context, error: &error) {
                    self.variable = variable
                    self.value = value
                } else { error.error = "Missing 'Float4' parameter" }
            } else
            if variable as? Text1 != nil {
                if let str = options["value"] as? String {
                    self.variable = variable
                    self.value = prepVariableName(str)
                } else
                if let t1 = options["value"] as? Text1 {
                    self.variable = variable
                    self.value = t1
                } else { error.error = "Invalid 'Text' parameter" }
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
        } else
        if let textVar = variable as? Text1 {
            if let stringValue = value as? String {
                textVar.text = stringValue
                return .Success
            } else
            if let textValue = value as? Text1 {
                textVar.text = textValue.text
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
        position2 = extractFloat2Value(options, container: context, error: &error, name: "position")
        radius1 = extractFloat1Value(options, container: context, error: &error, name: "radius", isOptional: true)
        dest = extractFloat1Value(options, container: context, error: &error, name: "variable")

        if let shapeN = options["shapeid"] as? String {
            shapeName = shapeN
        } else {
            error.error = "Missing 'ShapeId' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let position = position2 {
            if let map = game.currentMap?.map {
                if let shape = map.shapes2D[shapeName!] {
                    
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if inst.1.behaviorAsset.behavior === context {
                                let distance = distanceToRect(position: position, shape: inst.0, map: map)
                                if let dest = dest {
                                    dest.x = distance - inst.0.options.border.x * map.aspect.z
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
                            dest.x = distance - shape.options.border.x * map.aspect.z
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

class ShapeContactCount: BehaviorNode
{
    var position2: Float2? = nil
    var radius1: Float1? = nil
    var shapeName: String? = nil
    var dest: Int1? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "ShapeContactCount"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        dest = extractInt1Value(options, container: context, parameters: tree.parameters, error: &error, name: "variable")

        if let shapeN = options["shapeid"] as? String {
            shapeName = shapeN
        } else {
            error.error = "Missing 'ShapeId' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let map = game.currentMap?.map {
            if let shape = map.shapes2D[shapeName!] {
                if let instances = shape.instances {
                    
                    for inst in instances.pairs {
                        if inst.1.behaviorAsset.behavior === context {
                            if let dest = dest {
                                dest.x = inst.0.contactList.count
                            }
                            break
                        }
                    }
                    
                    return .Success
                } else {
                    if let dest = dest {
                        dest.x = shape.contactList.count
                    }
                }
            }
        }        
        return .Success
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
        if let a = extractFloat3Value(options, container: context, error: &error, name: "a", isOptional: true) {
            self.a = a
        }
        if let b = extractFloat3Value(options, container: context, error: &error, name: "b", isOptional: true) {
            self.b = b
        }
        if let c = extractFloat3Value(options, container: context, error: &error, name: "c", isOptional: true) {
            self.c = c
        }
        if let d = extractFloat3Value(options, container: context, error: &error, name: "d", isOptional: true) {
            self.d = d
        }
        dest = extractFloat4Value(options, container: context, error: &error, name: "variable")
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

class RandomNode: BehaviorNode
{
    var from: Any? = nil
    var to: Any? = nil

    var dest: Any? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Random"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let from = extractInt1Value(options, container: context, parameters: tree.parameters, error: &error, name: "from", isOptional: true, ignoreErrors: true) {
            self.from = from
            self.to = extractInt1Value(options, container: context, parameters: tree.parameters, error: &error, name: "to")
            dest = extractInt1Value(options, container: context, parameters: tree.parameters, error: &error, name: "variable")
        } else
        if let from = extractFloat1Value(options, container: context, error: &error, name: "from", isOptional: true, ignoreErrors: true) {//}, allowExpressions: false) {
            self.from = from
            self.to = extractFloat1Value(options, container: context, error: &error, name: "to")
            dest = extractFloat1Value(options, container: context, error: &error, name: "variable")
        } else
        if let from = extractFloat2Value(options, container: context, error: &error, name: "from", isOptional: true, ignoreErrors: true) {
            
            self.from = from
            self.to = extractFloat2Value(options, container: context, error: &error, name: "to")
            dest = extractFloat2Value(options, container: context, error: &error, name: "variable")
        } else
        if let from = extractFloat3Value(options, container: context, error: &error, name: "from", isOptional: true, ignoreErrors: true) {
            self.from = from
            self.to = extractFloat3Value(options, container: context, error: &error, name: "to")
            dest = extractFloat3Value(options, container: context, error: &error, name: "variable")
        } else
        if let from = extractFloat4Value(options, container: context, error: &error, name: "from", isOptional: true) {
            self.from = from
            self.to = extractFloat4Value(options, container: context, error: &error, name: "to")
            dest = extractFloat4Value(options, container: context, error: &error, name: "variable")
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let dest = dest as? Int1 {
            if let from = from as? Int1 {
                if let to = to as? Int1 {
                    dest.x = Int.random(in: from.x...to.x)
                }
            }
            return .Success
        } else
        if let dest = dest as? Float1 {
            if let from = from as? Float1 {
                if let to = to as? Float1 {
                    dest.x = Float.random(in: from.x...to.x)
                }
            }
            return .Success
        } else
        if let dest = dest as? Float2 {
            if let from = from as? Float2 {
                if let to = to as? Float2 {
                    dest.x = Float.random(in: from.x...to.x)
                    dest.y = Float.random(in: from.y...to.y)
                }
            }
            return .Success
        } else
        if let dest = dest as? Float3 {
            if let from = from as? Float3 {
                if let to = to as? Float3 {
                    dest.x = Float.random(in: from.x...to.x)
                    dest.y = Float.random(in: from.y...to.y)
                    dest.z = Float.random(in: from.z...to.z)
                }
            }
            return .Success
        } else
        if let dest = dest as? Float4 {
            if let from = from as? Float4 {
                if let to = to as? Float4 {
                    dest.x = Float.random(in: from.x...to.x)
                    dest.y = Float.random(in: from.y...to.y)
                    dest.z = Float.random(in: from.z...to.z)
                    dest.w = Float.random(in: from.w...to.w)
                }
            }
            return .Success
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class LengthNode: BehaviorNode
{
    var variable: Float1? = nil
    var value   : Any? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Length"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = extractFloat2Value(options, container: context, error: &error, isOptional: true) {
            self.value = value
        } else
        if let value = extractFloat3Value(options, container: context, error: &error, isOptional: true) {
            self.value = value
        } else
        if let value = extractFloat4Value(options, container: context, error: &error, isOptional: true) {
            self.value = value
        }
        self.variable = extractFloat1Value(options, container: context, error: &error, name: "variable")
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let value = value as? Float2 {
            let rc = length(value.toSIMD())
            variable!.x = rc
            return .Success
        } else
        if let value = value as? Float3 {
            let rc = length(value.toSIMD())
            variable!.x = rc
            return .Success
        } else
        if let value = value as? Float4 {
            let rc = length(value.toSIMD())
            variable!.x = rc
            return .Success
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class DistanceNode: BehaviorNode
{
    var from: Any? = nil
    var to: Any? = nil

    var dest: Float1? = nil

    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Distance"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let from = extractFloat2Value(options, container: context, error: &error, name: "from", isOptional: true) {
            self.from = from
            self.to = extractFloat2Value(options, container: context, error: &error, name: "to")
        } else
        if let from = extractFloat3Value(options, container: context, error: &error, name: "from", isOptional: true) {
            self.from = from
            self.to = extractFloat3Value(options, container: context, error: &error, name: "to")
        } else
        if let from = extractFloat4Value(options, container: context, error: &error, name: "from", isOptional: true) {
            self.from = from
            self.to = extractFloat4Value(options, container: context, error: &error, name: "to")
        }
        dest = extractFloat1Value(options, container: context, error: &error, name: "variable")
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let from = from as? Float2 {
            if let to = to as? Float2 {
                dest!.x = distance(from.toSIMD(), to.toSIMD())
                return .Success
            }
        } else
        if let from = from as? Float3 {
            if let to = to as? Float3 {
                dest!.x = distance(from.toSIMD(), to.toSIMD())
                return .Success
            }
        } else
        if let from = from as? Float4 {
            if let to = to as? Float4 {
                dest!.x = distance(from.toSIMD(), to.toSIMD())
                return .Success
            }
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
        data2 = extractFloat2Value(options, container: context, error: &error, name: "variable")
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if game.view.mouseIsDown {
            if let data2 = data2 {
                if let map = game.currentMap?.map {
                    data2.x = (game.view.mousePos.x - map.viewBorder.x) / map.aspect.x
                    data2.y = (game.view.mousePos.y - map.viewBorder.y) / map.aspect.y
                    return .Success
                }
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class HasTouch: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "HasTouch"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if game.view.mouseIsDown {
            return .Success
        } else {
            context.addFailure(lineNr: lineNr)
            return .Failure
        }
    }
}

class HasTap: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "HasTap"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if game.view.hasTap {
            return .Success
        } else {
            context.addFailure(lineNr: lineNr)
            return .Failure
        }
    }
}

class HasDoubleTap: BehaviorNode
{    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "HasDoubleTap"
    }

    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if game.view.hasDoubleTap {
            return .Success
        } else {
            context.addFailure(lineNr: lineNr)
            return .Failure
        }
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

class IsButtonDown: BehaviorNode
{
    var button: String? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsButtonDown"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["button"] as? String {
            button = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        } else {
            error.error = "IsButtonDown requires a 'Button' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let button = game.view.buttonDown {
            if button == self.button {
                return .Success
            }
        }
        
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}

class Swiped: BehaviorNode
{
    var swipedDirection: String? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Swiped"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        if let value = options["direction"] as? String {
            swipedDirection = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil).lowercased()
        } else {
            error.error = "Swiped requires a 'Direction' parameter"
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if let swipedDirection = game.view.swipeDirection {
            if swipedDirection == self.swipedDirection {
                return .Success
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
        pair = extractPair(options, variableName: "from", container: context, error: &error, optionalVariables: ["minimum"])
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
        pair = extractPair(options, variableName: "to", container: context, error: &error, optionalVariables: ["maximum"])
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
        pair = extractPair(options, variableName: "with", container: context, error: &error, optionalVariables: [])
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

class IsComponent: BehaviorNode
{
    enum Mode {
        case GreaterThan, LessThan, Equal
    }
    
    var mode    : Mode = .Equal
    var pair    : (UpTo4Data, UpTo4Data, [UpTo4Data])? = nil
    var component : UpTo4Data? = nil
    var f1      : Float1? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "IsComponent"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        
        if let compData = extractComponent(options, container: context, error: &error) {
            component = compData
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
            
            if error.error == nil {
                f1 = extractFloat1Value(options, container: context, error: &error)
            }
        }
        
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        var value : Float? = nil
        
        if let f2 = component?.data2 {
            value = f2[component!.index!]
        } else
        if let f3 = component?.data3 {
            value = f3[component!.index!]
        } else
        if let f4 = component?.data4 {
            value = f4[component!.index!]
        }
        
        if let value = value {
            if mode == .Equal {
                if value == f1!.x {
                    return .Success
                }
            } else
            if mode == .GreaterThan {
                if value > f1!.x {
                    return .Success
                }
            } else
            if mode == .LessThan {
                if value < f1!.x {
                    return .Success
                }
            }
        }
 
        context.addFailure(lineNr: lineNr)
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
        pair = extractPair(options, variableName: "variable", container: context, error: &error, optionalVariables: [])
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
            // Bool
            if pair.0.bool1 != nil {
                if mode == .Equal {
                    if pair.1.bool1!.x == pair.0.bool1!.x {
                        return .Success
                    }
                }
            } else
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


