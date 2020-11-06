//
//  MapBuilder.swift
//  Denrim
//
//  Created by Markus Moenig on 6/9/20.
//

import MetalKit
import JavaScriptCore

class MapBuilder
{
    let game            : Game
    
    var cursorTimer     : Timer? = nil
    var scriptLine      : Int32? = nil
    var previewLine     : Int32? = nil

    let mapPreview      : MapPreview
    
    var currentLayer    : String? = nil

    enum Types : String, CaseIterable
    {
        case Image = "Image"        // Points to a single image
        case Audio = "Audio"        // Points to an audio file
        case Sequence = "Sequence"  // Points to a range of images in a group or a range of tiles in an image
        case Alias = "Alias"        // An alias of or into one of the above assets
        case Layer = "Layer"        // Contains alias data of a layer
        case Scene = "Scene"        // List of layers
        case Physics2D = "Physics2D"// 2D Physics
        case Behavior = "Behavior"  // Behavior Tree

        case Shape2D = "Shape2D"    // 2D Shape
        case Shader = "Shader"      // Shader

        case GridInstance2D = "GridInstance2D" // GridInstance
        case OnDemandInstance2D = "OnDemandInstance2D" // OnDemandInstance

        // Commands
        case CanvasSize = "CanvasSize"
        case ApplyPhysics2D = "ApplyPhysics2D"
        case ApplyTexture2D = "ApplyTexture2D"
    }
    
    init(_ game: Game)
    {
        self.game = game
        mapPreview = MapPreview(game)
    }
    
    @discardableResult func compile(_ asset: Asset) -> CompileError
    {
        //print("compiling...")
        
        if asset.map == nil {
            asset.map = Map()
        } else {
            asset.map!.clear()
        }
        
        game.currentMap = asset
                
        let ns = asset.value as NSString
        var lineNumber : Int32 = 0
        
        var error = CompileError()
        error.asset = asset
        error.column = 0
                
        func createError(_ errorText: String = "Syntax Error") {
            error.error = errorText
        }
        
        ns.enumerateLines { (str, _) in
            
            if error.error != nil { return }
            error.line = lineNumber
            
            // Layer Data ?
            if self.currentLayer != nil {
                if str.starts(with: ":") {
                    
                    var data = str
                    data.removeFirst()
                    data = data.trimmingCharacters(in: .whitespaces)
                    
                    asset.map!.layers[self.currentLayer!]?.data.append(data)
                    
                    lineNumber += 1
                    return
                } else {
                    asset.map!.layers[self.currentLayer!]?.endLine = lineNumber
                    self.currentLayer = nil
                }
            }
            
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
            
            leftOfComment = leftOfComment.trimmingCharacters(in: .whitespaces)//String(leftOfComment.filter { !" \n\t\r".contains($0) })
            
            if leftOfComment.count > 0 {
                
                let values = leftOfComment.split(separator: "=")

                if values.count == 1 || values.count == 2 {
                    
                    var leftValue : String? = nil
                    var rightValue: String = ""
                    
                    if values.count == 2 {
                        leftValue = String(values[0]).trimmingCharacters(in: .whitespaces)
                        rightValue = values[1].trimmingCharacters(in: .whitespaces)
                    } else {
                        rightValue = values[0].trimmingCharacters(in: .whitespaces)
                    }

                    var rightValueArray = rightValue.split(separator: "<")
                    
                    if rightValueArray.count > 0 {
                        
                        let possbibleType = String(rightValueArray[0]).trimmingCharacters(in: .whitespaces)
                        var type : Types? = nil
                        Types.allCases.forEach {
                            if $0.rawValue == possbibleType {
                                if type != nil { return }
                                type = $0
                            }
                        }
                                                
                        if let type = type {
                            
                            var options : [String: String] = [:]
                            
                            rightValueArray.removeFirst()
                            if rightValueArray.count == 1 && rightValueArray[0] == ">" {
                                // Empty Arguments
                            } else {
                                while rightValueArray.count > 0 {
                                    let array = rightValueArray[0].split(separator: ":")
                                    rightValueArray.removeFirst()
                                    if array.count == 2 {
                                        let optionName = array[0].lowercased().trimmingCharacters(in: .whitespaces)
                                        var values = array[1].trimmingCharacters(in: .whitespaces)

                                        if values.count > 0 && values.last! != ">" {
                                            createError("No closing '>' for option '\(optionName)'")
                                        } else {
                                            values = String(values.dropLast())
                                        }
                                        options[optionName] = String(values)
                                    } else { createError(); rightValueArray = [] }
                                }
                            }
                            
                            // test = Image<Group: "imagegroup"><Index: 0><Rect: 0,0,0,0> # adwddawd
                         
                            let map = self.parser_processOptions(options, &error)
                            if error.error == nil {
                                if let leftValue = leftValue {
                                    self.parser_processAssignment(type, variable: leftValue, options: map, error: &error, map: asset.map!)
                                } else {
                                    self.parser_processCommand(type, options: map, error: &error, map: asset.map!)
                                }
                            }
                        } else { createError("Unknown Type `\(rightValueArray[0])`")}
                    }
                } else { createError() }
            }
            
            lineNumber += 1
        }
        
        if game.state == .Idle {
            if error.error != nil {
                error.line = error.line! + 1
                game.scriptEditor?.setError(error)
            } else {
                game.scriptEditor?.clearAnnotations()
                DispatchQueue.main.async {
                    self.createPreview(asset.map!)
                }
            }
        } else
        if game.state == .Running {
            if error.error != nil {
                error.line = error.line! + 1
                game.stop()
                game.assetError = error
                game.gameError.send()
            }
        }
        
        return error
    }
    
    func parser_processCommand(_ type: Types, options: [String:Any], error: inout CompileError, map: Map)
    {
        //print("Processing Command", type, options, error.line!)
        
        func setLine(_ command: String)
        {
            map.commandLines[error.line!] = command
        }
        
        map.commands.append(MapCommand(command: type.rawValue, options: options))
        setLine(type.rawValue)
    }
    
    func parser_processAssignment(_ type: Types, variable: String, options: [String:Any], error: inout CompileError, map: Map)
    {
        //print("Processing Assignment", type, variable, options, error.line!)
        
        func setLine(_ variable: String)
        {
            // Remove previous lines with the same variable
            for (l,v) in map.lines {
                if v == variable {
                    map.lines[l] = nil
                }
            }
            map.lines[error.line!] = variable
        }
        
        if type == .Image {
            if let group = options["group"] as? String {
                if let asset = game.assetFolder.getAsset(group, .Image) {
                    var index : Int1 = Int1(0)
                    if let ind = options["index"] as? Int1 {
                        index = ind
                    }
                    if index.x >= 0 && index.x < asset.data.count {
                        if map.images[variable] != nil {
                            map.images[variable] = nil
                        }
                        if map.images[variable] == nil {
                            let resourceName : String = asset.id.uuidString + ":" + String(index.x)
                            map.images[variable] = MapImage(resourceName: resourceName, options: options)
                            setLine(variable)
                        }
                    } else { error.error = "Image group '\(group)' index '\(index)' for '\(variable)' out of bounds" }
                } else { error.error = "Image group '\(group)' for '\(variable)' not found" }
            } else { error.error = "Image type for '\(variable)' expects a 'Group' option" }
        } else
        if type == .Audio {
            if let name = options["name"] as? String {
                if let asset = game.assetFolder.getAsset(name, .Audio) {                    
                    let resourceName : String = asset.id.uuidString
                    map.audio[variable] = MapAudio(resourceName: resourceName, options: options)
                    if let global = options["global"] as? Bool1 {
                        if global.x == true {
                            map.audio[variable]!.isLocal = false
                        }
                    }
                    if let loops = options["loops"] as? Int1 {
                        map.audio[variable]!.loops = loops.x
                    }
                    setLine(variable)
                } else { error.error = "Image '\(name)' for '\(variable)' not found" }
            } else { error.error = "Audio type for '\(variable)' expects a 'Name' option" }
        } else
        if type == .Sequence {
            if let group = options["group"] as? String {
                if let asset = game.assetFolder.getAsset(group, .Image) {
                    var from : Int = 0
                    var to : Int = 0
                    if let vec = options["range"] as? Float2 {
                        from = Int(vec.x)
                        to = Int(vec.y)
                    }
                    var array : [String] = []
                    for index in from...to {
                        if index >= 0 && index < asset.data.count {
                            let resourceName : String = asset.id.uuidString + ":" + String(index)
                            array.append(resourceName)
                        } else { error.error = "Sequence group '\(group)' index '\(index)' for '\(variable)' out of bounds" }
                    }
                    if map.sequences[variable] != nil {
                        map.sequences[variable] = nil
                    }
                    map.sequences[variable] = MapSequence(resourceNames: array, options: options)
                    if let interval = options["interval"] as? Float1 {
                        map.sequences[variable]!.interval = Double(interval.x)
                    }
                    setLine(variable)
                } else { error.error = "Image group '\(group)' for '\(variable)' not found" }
            } else { error.error = "Sequence type for '\(variable)' expects a 'Group' option" }
        } else
        if type == .Alias {
            if variable.count == 2 {
                if let id = options["id"] as? String {
                    if map.images[id] != nil {
                        map.aliases[variable] = MapAlias(type: .Image, pointsTo: id, originalOptions: options, options: MapAliasData2D(options))
                        setLine(variable)
                    }
                }
            } else { error.error = "Alias '\(variable)' must contain of two characters" }
        } else
        if type == .Layer {
            map.layers[variable] = MapLayer(data: [], originalOptions: options, options: MapLayerData2D(options))
            setLine(variable)
            currentLayer = variable
        } else
        if type == .Physics2D {
            map.physics2D[variable] = MapPhysics2D(options: options)
            setLine(variable)
        } else
        if type == .Shader {
            if let shaderName = options["name"] as? String {
                if let asset = game.assetFolder.getAsset(shaderName, .Shader) {
                    var mapShader = MapShader(options: options)
                    var behaviorContext : BehaviorContext? = nil
                    
                    if let behaviorId = options["behaviorid"] as? String {
                        if let behavior = map.behavior[behaviorId] {
                            behaviorContext = behavior.behaviorAsset.behavior
                        } else { error.error = "Could not find behavior '\(behaviorId)'" }
                    }
                    
                    game.shaderCompiler.compile(asset: asset, behavior: behaviorContext, cb: { (shader, errors) in
                        mapShader.shader = shader
                        if errors.count != 0 {
                            print("Shader failed", errors[0].error!)
                            //error.error = "Referenced behavior contains errors"
                        }
                    })
                    map.shaders[variable] = mapShader
                    setLine(variable)
                } else { error.error = "Could not find shader '\(shaderName)'" }
            } else { error.error = "Missing shader name" }
        } else
        if type == .Behavior {
            if let behavior = options["name"] as? String {
                if let asset = game.assetFolder.getAsset(behavior, .Behavior) {
                    let rc = game.behaviorBuilder.compile(asset)
                    if rc.error == nil {
                        asset.behavior!.execute(name: "init")
                        map.behavior[variable] = MapBehavior(behaviorAsset: asset, name: variable, options: options)
                        setLine(variable)
                    } else { error.error = "Referenced behavior contains errors" }
                } else { error.error = "Could not find behavior '\(behavior)'" }
            } else { error.error = "Missing behavior name" }
        } else
        if type == .Shape2D {
            createShape2D(map: map, variable: variable, options: options, error: &error)
        } else
        if type == .OnDemandInstance2D {
            let shapeId = options["shapeid"] as? String
            let behaviorId = options["behaviorid"] as? String
            if shapeId != nil && behaviorId != nil {
                if map.shapes2D[shapeId!] != nil && map.behavior[behaviorId!] != nil {
                    let instancer = MapOnDemandInstance2D(shapeName: shapeId!, behaviorName: behaviorId!, variableName: variable)
                    if let delay = options["delay"] as? Float1 {
                        instancer.delay = Double(delay.x)
                    }
                    map.shapes2D[shapeId!]!.instances = instancer
                    map.behavior[behaviorId!]!.instances = instancer
                    map.onDemandInstancers[variable] = instancer
                    setLine(variable)
                }
            }
        } else
        if type == .GridInstance2D {
            let shapeId = options["shapeid"] as? String
            let behaviorId = options["behaviorid"] as? String
            
            let instances = options["grid"] as? Float2
            let offsets = options["offset"] as? Float2

            let gridLayout = Float2(1,1)
            if let instances = instances {
                gridLayout.x = instances.x
                gridLayout.y = instances.y
            }
            
            let gridOffset = Float2(10,10)
            if let offsets = offsets {
                gridOffset.x = offsets.x
                gridOffset.y = offsets.y
            }
            
            if shapeId != nil && behaviorId != nil {
                if map.shapes2D[shapeId!] != nil && map.behavior[behaviorId!] != nil {
                    
                    let grid = MapGridInstance2D(shapeName: shapeId!, behaviorName: behaviorId!, variableName: variable)
                    let origPosition = map.behavior[behaviorId!]!.behaviorAsset.behavior?.getVariableValue("position") as? Float2
                    
                    // Only create when the original behavior was compiled successfully
                    if map.behavior[behaviorId!]!.behaviorAsset.behavior != nil && origPosition != nil {
                    
                        map.shapes2D[shapeId!]!.instances = grid
                        map.behavior[behaviorId!]!.instances = grid
                        
                        grid.columns = Int(gridLayout.x)
                        grid.rows = Int(gridLayout.y)
                        grid.offsetX = gridOffset.x
                        grid.offsetY = gridOffset.y

                        var y: Float = origPosition!.y

                        for r in 1...grid.rows {
                            var x: Float = origPosition!.x
                            
                            for c in 1...grid.columns {
                                
                                var variableName = variable
                                variableName += String(c) + "_" + String(r)
                                
                                let instanceAsset = Asset(type: .Behavior, name: behaviorId!)
                                instanceAsset.value = map.behavior[behaviorId!]!.behaviorAsset.value
                                
                                game.behaviorBuilder.compile(instanceAsset)
                                createShape2D(map: map, variable: variableName, options: map.shapes2D[shapeId!]!.originalOptions, error: &error, instBehaviorName: behaviorId!, instAsset: instanceAsset)
                                if error.error == nil {
                                    var mapBehavior = MapBehavior(behaviorAsset: instanceAsset, name: variableName, options: options)
                                    var mapShape2D = map.shapes2D[variableName]!
                                    
                                    let position = mapBehavior.behaviorAsset.behavior?.getVariableValue("position") as? Float2
                                    position!.x = x
                                    position!.y = y

                                    instanceAsset.behavior!.execute(name: "init")
                                    grid.addPair(shape: &mapShape2D, behavior: &mapBehavior)
                                }
                                
                                x += grid.offsetX
                            }
                            y += grid.offsetY
                        }
                        map.gridInstancers[variable] = grid
                        setLine(variable)
                    } else { error.error = "Could not find behavior '\(behaviorId!)'" }
                } else { error.error = "Could not find shape '\(shapeId!)'" }
            } else { error.error = "Missing 'ShapeId' or 'BehaviorId' parameters" }
        } else
        if type == .Scene {
            map.scenes[variable] = MapScene(options: options)
            map.scenes[variable]!.name = variable
            if options["color"] != nil {
                map.scenes[variable]!.backColor = options["color"] as? Float4
            }
            setLine(variable)
        } else { error.error = "Unknown type '\(type.rawValue)'" }
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout CompileError) -> [String:Any]
    {
        //print("Processing Options", options)

        let stringOptions = ["group", "id", "name", "physics", "mode", "object", "type", "platform", "text", "font", "behaviorid", "shapeid", "physicsid", "body", "scale"]
        let integerOptions = ["index", "int", "digits", "groupindex", "loops"]
        let floatOptions = ["round", "radius", "onion", "fontsize", "float", "border", "rotation", "friction", "restitution", "density", "delay", "interval"]
        let float2Options = ["range", "gravity", "position", "box", "size", "float2", "offset", "grid", "scroll"]
        let float4Options = ["rect", "color", "bordercolor", "float4"]
        let boolOptions = ["repeatx", "repeaty", "visible", "bullet", "global"]
        let stringArrayOptions = ["layers", "shapes", "shaders", "collisionids"]

        var res: [String:Any] = [:]
        
        for(name, value) in options {
            if stringOptions.firstIndex(of: name) != nil {
                // String
                res[name] = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
            } else
            if integerOptions.firstIndex(of: name) != nil {
                // Integer
                if let v = Int(value) {
                    res[name] = Int1(v)
                } else {
                   // Variable
                   res[name] = value
               }
            } else
            if floatOptions.firstIndex(of: name) != nil {
                // Float
                if let v = Float(value) {
                    res[name] = Float1(v)
                } else {
                    // Variable
                    res[name] = value
                }
            } else
            if boolOptions.firstIndex(of: name) != nil {
                // Boolean
                if let v = Bool(value) {
                    res[name] = Bool1(v)
                } else {
                    // Variable
                    res[name] = value
                }
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
                    let varRef = String(array[0]).trimmingCharacters(in: .whitespaces)
                    let varArray = value.split(separator: ".")
                    if varArray.count == 2 {
                        res[name] = varRef
                    } else { error.error = "Wrong variable reference (must contain '.')" }
                } else { error.error = "Wrong argument count for Float2" }
            } else
            if float4Options.firstIndex(of: name) != nil {
                let array = value.split(separator: ",")
                if array.count == 4 {
                    let x : Float; if let v = Float(array[0]) { x = v } else { x = 0 }
                    let y : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { y = v } else { y = 0 }
                    let z : Float; if let v = Float(array[2].trimmingCharacters(in: .whitespaces)) { z = v } else { z = 1 }
                    let w : Float; if let v = Float(array[3].trimmingCharacters(in: .whitespaces)) { w = v } else { w = 1 }
                    res[name] = Float4(x, y, z, w)
                } else
                if array.count == 1 {
                    let varRef = String(array[0]).trimmingCharacters(in: .whitespaces)
                    let varArray = value.split(separator: ".")
                    if varArray.count == 2 {
                        res[name] = varRef
                    } else { error.error = "Wrong variable reference (must contain '.')" }
                } else { error.error = "Wrong argument count for Float4" }
            }
        }
        
        return res
    }
    
    // Replaces the options of the shape with resolved variable references and creates the shape
    func createShape2D(map: Map, variable: String, options: [String:Any], error: inout CompileError, instBehaviorName: String? = nil, instAsset: Asset? = nil)
    {
        var replacedOptions = options
        var isValid = true

        func checkVarRef(_ name: String,_ optionName: String) -> Bool {
            var isValid = false
            var asset: Asset? = nil

            let varArray = name.split(separator: ".")
            if varArray.count > 0 {
                
                // Instance ?
                if let instBehaviorName = instBehaviorName {
                    if instBehaviorName == varArray[0] {
                        asset = instAsset!
                    }
                }
                
                if asset == nil {
                    // Not, normal reference
                    for (name, behavior) in map.behavior {
                        if name == varArray[0] {
                            asset = behavior.behaviorAsset
                            break
                        }
                    }

                    // Game Asset
                    if asset == nil && varArray[0] == "game" {
                        asset = game.gameAsset
                    }
                }
            }
                                            
            if let asset = asset, varArray.count == 2 {
                if let behavior = asset.behavior {
                    for v in behavior.variables {
                        if v.name == varArray[1] {
                            isValid = true
                            replacedOptions[optionName] = v.value
                            break
                        }
                    }
                    if isValid == false {
                        error.error = "Behavior'\(varArray[0])' does not contain variable '\(varArray[1])'"
                    }
                }
            } else
            if varArray.count > 0 {
                if varArray[0] != "game" {
                    if varArray.count > 0 {
                        error.error = "No behavior found with name '\(varArray[0])'"
                    } else {
                        error.error = "Incorrect behavior"
                    }
                }
            }
            
            return isValid
        }

        // Iterate over options
        for (n,v) in options {
            if n != "type" && n != "text" && n != "font" && n != "physics" {
                if let varRef = v as? String {
                    isValid = checkVarRef(varRef, n)
                    if isValid == false {
                        break
                    }
                }
            }
        }
        
        func setLine(_ variable: String)
        {
            if instBehaviorName == nil {
                // Remove previous lines with the same variable
                for (l,v) in map.lines {
                    if v == variable {
                        map.lines[l] = nil
                    }
                }
                map.lines[error.line!] = variable
            }
        }
        
        if isValid {
            if let shapeName = options["type"] as? String {
                if shapeName.lowercased() == "disk" {
                    map.shapes2D[variable] = MapShape2D(shapeName: variable, shape: .Disk, options: MapShapeData2D(replacedOptions), originalOptions: options)
                    setLine(variable)
                } else
                if shapeName.lowercased() == "box" {
                    map.shapes2D[variable] = MapShape2D(shapeName: variable, shape: .Box, options: MapShapeData2D(replacedOptions), originalOptions: options)
                    setLine(variable)
                } else
                if shapeName.lowercased() == "text" {
                    
                    let textRef = TextRef()
                    if let text = replacedOptions["text"] as? String {
                        textRef.text = text
                    }
                    
                    if let fontSize = replacedOptions["fontsize"] as? Float1 {
                        textRef.fontSize = fontSize.x
                    }
                    
                    if let f1 = replacedOptions["float"] as? Float1 {
                        textRef.f1 = f1
                    } else
                    if let f2 = replacedOptions["float2"] as? Float2 {
                        textRef.f2 = f2
                    } else
                    if let f3 = replacedOptions["float3"] as? Float3 {
                        textRef.f3 = f3
                    } else
                    if let f4 = replacedOptions["float4"] as? Float4 {
                        textRef.f4 = f4
                    } else
                    if let i1 = replacedOptions["int"] as? Int1 {
                        textRef.i1 = i1
                    }
                    
                    if let digits = replacedOptions["digits"] as? Int1 {
                        textRef.digits = digits
                    }
                    
                    if let fontName = replacedOptions["font"] as? String {
                        for (index, fName) in game.availableFonts.enumerated() {
                            if fontName == fName {
                                textRef.font = game.fonts[index]
                                break
                            }
                        }
                    }
                    
                    replacedOptions["text"] = textRef
                    
                    map.shapes2D[variable] = MapShape2D(shapeName: variable, shape: .Text, options: MapShapeData2D(replacedOptions), originalOptions: options)
                    setLine(variable)
                }
            }
        }
    }
    
    func createPreview(_ map: Map,_ forcePreview: Bool = false )
    {
        var name : String? = nil
        var command : String? = nil
        if let line = scriptLine {
            if line != previewLine || forcePreview {
                previewLine = line                
                game.checkTexture()
                
                command = map.commandLines[line]
                
                if let n = map.lines[line] {
                    name = n
                } else {
                        
                    // Check if the last line was a layer
                    var lastLine : Int32 = -1
                    var lastVar  : String = ""
                    for (l, variable) in map.lines {
                        if l > lastLine && l < line {
                            lastLine = l
                            lastVar = variable
                        }
                    }
                    
                    // If yes, check if the line is inside the layer range
                    if map.layers[lastVar] != nil {
                            if line < map.layers[lastVar]!.endLine {
                            name = lastVar
                        }
                    }
                }
                
                map.setup(game: game)
                mapPreview.preview(map, name, command)
            }
        }
    }
    
    func startTimer(_ asset: Asset)
    {
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: 0.2,
                                             target: self,
                                             selector: #selector(self.cursorCallback),
                                             userInfo: asset,
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
        mapPreview.stopTimer()
    }
    
    @objc func cursorCallback(_ timer: Timer) {
        if game.state == .Idle && game.scriptEditor != nil {
            game.scriptEditor!.getSessionCursor({ [weak self] (line) in
                guard let self = self else { return }

                if let asset = timer.userInfo as? Asset {
                    let needsUpdate = self.scriptLine != line
                    self.scriptLine = line
                    if needsUpdate && asset.map != nil {
                        self.createPreview(asset.map!)
                    }
                }
            })
        }
    }
}
