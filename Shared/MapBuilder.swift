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
                print(split)
                if split.count == 2 {
                    leftOfComment = String(str.split(separator: "#")[0])
                } else {
                    leftOfComment = ""
                }
            } else {
                leftOfComment = str
            }
            
            print(leftOfComment)
            if leftOfComment.count > 0 {
                
                let values = leftOfComment.split(separator: "=")

                if values.count == 2 {
                    
                    let leftValue = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let rightValue = values[1].trimmingCharacters(in: .whitespacesAndNewlines)

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
        //print(error, errorLine)
        
    }
    
    func parser_processAssignment(_ type: Types, variable: String, options: [String:Any], error: inout JSError)
    {
        print("Processing Assignment", type, variable, options, error.line!)
    }
    
    func parser_processOptions(_ options: [String:String],_ error: inout JSError) -> [String:Any]
    {
        let stringOptions = ["group"]
        
        var res: [String:Any] = [:]
        
        for(name, value) in options {
            if stringOptions.firstIndex(of: name) != nil {
                // String
                res[name] = value.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
            } else
            if name == "rect" {
                //let array = value.split(
            }
        }
        
        return res
    }
    
    func createPreview()
    {
    }
}
