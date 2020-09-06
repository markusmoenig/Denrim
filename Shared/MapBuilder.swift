//
//  MapBuilder.swift
//  Denrim
//
//  Created by Markus Moenig on 6/9/20.
//

import MetalKit

class MapBuilder
{
    let game            : Game
    
    var images          : [String:MTLTexture] = [:]
    
    enum Types : String, CaseIterable
    {
        case Image = "Image";
    }
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func compile(_ asset: Asset)
    {
        print("compiling...")
        
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
            
            leftOfComment = String(leftOfComment.filter { !" \n\t\r".contains($0) })
            
            if leftOfComment.count > 0 {
                
                let values = leftOfComment.split(separator: "=")

                if values.count == 2 {
                    
                    let leftValue = String(values[0])
                    let rightValue = values[1]

                    var rightValueArray = rightValue.split(separator: "<")
                    
                    if rightValueArray.count > 0 {
                        
                        var type : Types? = nil
                        Types.allCases.forEach {
                            if $0.rawValue == rightValueArray[0] {
                                if type != nil { return }
                                type = $0
                            }
                        }
                        
                        if let type = type {
                            
                            var options : [String: String] = [:]
                            
                            //print("1", rightValueArray)
                            rightValueArray.removeFirst()
                            while rightValueArray.count > 0 {
                                let array = rightValueArray[0].split(separator: ":")
                                //print("2", array)
                                rightValueArray.removeFirst()
                                if array.count == 2 {
                                    let optionName = array[0].lowercased()
                                    var values = array[1]
                                    //print("option", optionName, "value", values)
                                                                        
                                    if values.count > 0 && values.last! != ">" {
                                        createError("No closing '>' for option '\(optionName)'")
                                    } else {
                                        values = values.dropLast()
                                    }
                                    options[optionName] = String(values)
                                } else { createError(); rightValueArray = [] }
                            }
                            
                            // test = Image<Group: "imagegroup"><Index: 0><Rect: 0,0,0,0> # adwddawd
                         
                            let map = self.parser_processOptions(options, &error)
                            if error.error == nil {
                                self.parser_processAssignment(type, variable: leftValue, options: map, error: &error)
                            }
                        } else { createError("Unknown Type `\(rightValueArray[0])`")}
                    }
                } else { createError() }
            }
            
            lineNumber += 1
        }
        
        if error.error != nil {
            print(error.error!)
            game.scriptEditor?.setError(error)
        } else {
            game.scriptEditor?.clearAnnotations()
        }        
    }
    
    func parser_processAssignment(_ type: Types, variable: String, options: [String:Any], error: inout JSError)
    {
        print("Processing Assignment", type, variable, options, error.line!)
        if type == .Image {
            if let group = options["group"] as? String {
                if let asset = game.assetFolder.getAsset(group, .Image) {
                    var index : Int = 0
                    if let ind = options["index"] as? Int {
                        index = ind
                    }
                    if index >= 0 && index < asset.data.count {
                        
                    } else { error.error = "Image group '\(group)' index '\(index)' for '\(variable)' out of bounds" }
                } else { error.error = "Image group '\(group)' for '\(variable)' not found" }
            } else { error.error = "Image type for '\(variable)' expects a 'Group' option" }
        }
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout JSError) -> [String:Any]
    {
        print("Processing Options", options)

        let stringOptions = ["group"]
        let integerOptions = ["index"]

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
            if name == "rect" {
                let array = value.split(separator: ",")
                if array.count == 4 {
                    let x : Float; if let v = Float(array[0]) { x = v } else { x = 0 }
                    let y : Float; if let v = Float(array[1]) { y = v } else { y = 0 }
                    let width : Float; if let v = Float(array[2]) { width = v } else { width = 1 }
                    let height : Float; if let v = Float(array[3]) { height = v } else { height = 1 }
                    res[name] = MMRect(x, y, width, height)
                } else { error.error = "Rect must have 4 arguments" }
            }
        }
        
        return res
    }
    
    func createPreview()
    {
    }
}
