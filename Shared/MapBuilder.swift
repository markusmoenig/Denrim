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
    
    let mapPreview      : MapPreview
    
    var currentLayer    : String? = nil

    enum Types : String, CaseIterable
    {
        case Image = "Image"        // Points to a single image
        case Sequence = "Sequence"  // Points to a range of images in a group or a range of tiles in an image
        case Alias = "Alias"        // An alias of or into one of the above assets
        case Layer = "Layer"        // Contains alias data of a layer
        case Scene = "Scene"        // List of layers
        case Object2D = "Object2D"  // An 2D object
    }
    
    init(_ game: Game)
    {
        self.game = game
        mapPreview = MapPreview(game)
    }
    
    @discardableResult func compile(_ asset: Asset) -> JSError
    {
        print("compiling...")
        
        if asset.map == nil {
            asset.map = Map()
        } else {
            asset.map!.clear()
        }
                
        let ns = asset.value as NSString
        var lineNumber : Int32 = 0
        
        var error = JSError()
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

                if values.count == 2 {
                    
                    let leftValue = String(values[0]).trimmingCharacters(in: .whitespaces)
                    let rightValue = values[1].trimmingCharacters(in: .whitespaces)

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
                            
                            // test = Image<Group: "imagegroup"><Index: 0><Rect: 0,0,0,0> # adwddawd
                         
                            let map = self.parser_processOptions(options, &error)
                            if error.error == nil {
                                self.parser_processAssignment(type, variable: leftValue, options: map, error: &error, map: asset.map!)
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
        }
        
        return error
    }
    
    func parser_processAssignment(_ type: Types, variable: String, options: [String:Any], error: inout JSError, map: Map)
    {
        print("Processing Assignment", type, variable, options, error.line!)
        
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
                    var index : Int = 0
                    if let ind = options["index"] as? Int {
                        index = ind
                    }
                    if index >= 0 && index < asset.data.count {
                        if map.images[variable] != nil {
                            map.images[variable] = nil
                        }
                        if map.images[variable] == nil {
                            let resourceName : String = asset.id.uuidString + ":" + String(index)
                            map.images[variable] = MapImage(resourceName: resourceName, options: options)
                            setLine(variable)
                        }
                    } else { error.error = "Image group '\(group)' index '\(index)' for '\(variable)' out of bounds" }
                } else { error.error = "Image group '\(group)' for '\(variable)' not found" }
            } else { error.error = "Image type for '\(variable)' expects a 'Group' option" }
        } else
        if type == .Sequence {
            if let group = options["group"] as? String {
                if let asset = game.assetFolder.getAsset(group, .Image) {
                    var from : Int = 0
                    var to : Int = 0
                    if let vec = options["range"] as? Vec2 {
                        from = Int(vec.x)
                        to = Int(vec.y)
                    }
                    var array : [String] = []
                    for index in from...to {
                        if index >= 0 && index < asset.data.count {
                            //print("Creating image for ", variable)
                            let resourceName : String = asset.id.uuidString + ":" + String(index)
                            array.append(resourceName)
                        } else { error.error = "Sequence group '\(group)' index '\(index)' for '\(variable)' out of bounds" }
                    }
                    if map.sequences[variable] != nil {
                        map.sequences[variable] = nil
                    }
                    map.sequences[variable] = MapSequence(resourceNames: array, options: options)
                    setLine(variable)
                } else { error.error = "Image group '\(group)' for '\(variable)' not found" }
            } else { error.error = "Sequence type for '\(variable)' expects a 'Group' option" }
        } else
        if type == .Alias {
            if variable.count == 2 {
                if let id = options["id"] as? String {
                    
                    if map.images[id] != nil {
                        map.aliases[variable] = MapAlias(type: .Image, pointsTo: id, options: options)
                        setLine(variable)
                    }
                }
            } else { error.error = "Alias '\(variable)' must contain of two characters" }
        } else
        if type == .Layer {
            map.layers[variable] = MapLayer(data: [], options: options)
            setLine(variable)
            currentLayer = variable
        } else
        if type == .Object2D {
            map.objects2D[variable] = MapObject2D(name: variable, options: options)
            setLine(variable)
        } else
        if type == .Scene {
            map.scenes[variable] = MapScene(options: options)
            setLine(variable)
        } else { error.error = "Unknown type '\(type.rawValue)'" }
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout JSError) -> [String:Any]
    {
        print("Processing Options", options)

        let stringOptions = ["group", "id", "class"]
        let integerOptions = ["index"]
        let sizeOptions = ["sceneoffset", "range"]
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
            if sizeOptions.firstIndex(of: name) != nil {
                // Size
                let array = value.split(separator: ",")
                if array.count == 2 {
                    let width : Float; if let v = Float(array[0].trimmingCharacters(in: .whitespaces)) { width = v } else { width = 1 }
                    let height : Float; if let v = Float(array[1].trimmingCharacters(in: .whitespaces)) { height = v } else { height = 1 }
                    res[name] = Vec2(width, height)
                } else { error.error = "Vec2 must have 2 arguments" }
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
    
    func createPreview(_ map: Map)
    {
        var name : String? = nil
        if let line = scriptLine {
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
        }
        
        map.game = game
        map.texture = game.texture
        
        mapPreview.preview(map, name)
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
    
    func stopTimer(_ asset: Asset)
    {
        if cursorTimer != nil {
            cursorTimer?.invalidate()
            cursorTimer = nil
        }
        mapPreview.stopTimer()
        asset.map = nil
    }
    
    @objc func cursorCallback(_ timer: Timer) {
        if game.state == .Idle && game.scriptEditor != nil {
            game.scriptEditor!.getSessionCursor({ (line) in
                let asset = (timer.userInfo as! Asset)

                let needsUpdate = self.scriptLine != line
                self.scriptLine = line
                if needsUpdate && asset.map != nil {
                    self.createPreview(asset.map!)
                }
            })
        }
    }
}
