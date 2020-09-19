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
    var createNode   : (() -> BehaviorNode)? = nil
    
    init(_ name: String, _ createNode: (() -> BehaviorNode)?)
    {
        self.name = name
        self.createNode = createNode
    }
}

class BehaviorBuilder
{
    let game            : Game
    
    enum Types : String, CaseIterable
    {
        case Image = "Image"        // Points to a single image
        case Sequence = "Sequence"  // Points to a range of images in a group or a range of tiles in an image
        case Alias = "Alias"        // An alias of or into one of the above assets
        case Layer = "Layer"        // Contains alias data of a layer
        case Scene = "Scene"        // List of layers
        case Physics2D = "Physics2D"// 2D Physics
        case Object2D = "Object2D"  // An 2D object
        case Fixture2D = "Fixture2D"// A fixture for an Object2D
    }
    
    var branches        : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("sequence", { () -> BehaviorNode in return BehaviorNode() })
    ]
    
    var leaves          : [BehaviorNodeItem] =
    [
        BehaviorNodeItem("sequence", { () -> BehaviorNode in return BehaviorNode() })
    ]
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    @discardableResult func compile(_ asset: Asset) -> CompileError
    {
        var error = CompileError()
        error.asset = asset
        
        if asset.behavior == nil {
            asset.behavior = BehaviorContext(game)
        } else {
            //asset.behavior!.clear()
        }
        
        print("compile")
        let ns = asset.value as NSString
        var lineNumber  : Int32 = 0
        
        var currentTree : BehaviorTree? = nil
        var lastLevel   : Int32 = -1

        ns.enumerateLines { (str, _) in
            if error.error != nil { return }
            error.line = lineNumber
            
            let level = (str.prefix(while: {$0 == " "}).count) / 4
            print(str, level)
            
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

            if leftOfComment.count > 0 {
                let arguments = leftOfComment.split(separator: " ", omittingEmptySubsequences: true)
                if arguments.count > 0 {
                    print(level, arguments)
                    
                    let cmd = arguments[0].lowercased().trimmingCharacters(in: .whitespaces)
                    if cmd == "tree" {
                        if arguments.count == 2 {
                            let name = arguments[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)

                            if CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: name)) {
                                if level == 0 {
                                    print("new tree", name)
                                    currentTree = BehaviorTree(name)
                                }
                            } else { error.error = "Invalid name for tree '\(name)'" }
                        } else { error.error = "No name given for tree" }
                    }
                }
            }
            
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
}
