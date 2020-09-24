//
//  Leaves.swift
//  Denrim
//
//  Created by Markus Moenig on 19/9/20.
//

import Foundation

// Sets the current scene and initializes it
class SetScene: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "SetScene"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let mapName = options["map"] as? String {
            if let asset = game.assetFolder.getAsset(mapName, .Map) {
                if asset.map != nil {
                    asset.map?.clear()
                }
                if game.mapBuilder.compile(asset).error == nil {
                    if let map = asset.map {
                        if let sceneName = options["scene"] as? String {
                            if let scene = map.scenes[sceneName] {
                                game.currentMap = asset
                                game.currentScene = scene
                                map.setup(game: game)
                                return .Success
                            }
                        }
                    }
                }
            }
        }
        
        return .Failure
    }
}

class IsKeyDown: BehaviorNode
{
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
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let key = options["key"] as? String {
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
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        pair = extractPair(options, variableName: "from", context: context, error: &error, optionalVariables: ["minimum"])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let pair = pair {    
            if pair.0.data2 != nil {
                pair.1.data2!.x -= pair.0.data2!.x
                pair.1.data2!.y -= pair.0.data2!.y
                if let min = pair.2[0].data2 {
                    pair.1.data2!.x = max(pair.1.data2!.x, min.x)
                    pair.1.data2!.y = max(pair.1.data2!.y, min.y)
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
    
    override func verifyOptions(context: BehaviorContext, error: inout CompileError) {
        pair = extractPair(options, variableName: "to", context: context, error: &error, optionalVariables: ["maximum"])
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        if let pair = pair {
            if pair.0.data2 != nil {
                pair.1.data2!.x += pair.0.data2!.x
                pair.1.data2!.y += pair.0.data2!.y
                if let max = pair.2[0].data2 {
                    pair.1.data2!.x = min(pair.1.data2!.x, max.x)
                    pair.1.data2!.y = min(pair.1.data2!.y, max.y)
                }
                return .Success
            }
        }
        return .Failure
    }
}

class Clear: BehaviorNode
{
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        game.texture!.clear(options)
        return .Success
    }
}

class DrawDisk: BehaviorNode
{
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        game.texture!.drawDisk(options)
        return .Success
    }
}

class DrawBox: BehaviorNode
{
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        game.texture!.drawBox(options)
        return .Success
    }
}

class DrawText: BehaviorNode
{
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        game.texture!.drawText(options)
        return .Success
    }
}
