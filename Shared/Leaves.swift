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
