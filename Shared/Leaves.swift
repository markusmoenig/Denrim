//
//  Leaves.swift
//  Denrim
//
//  Created by Markus Moenig on 19/9/20.
//

import Foundation

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
