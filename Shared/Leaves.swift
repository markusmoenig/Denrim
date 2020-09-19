//
//  Leaves.swift
//  Denrim
//
//  Created by Markus Moenig on 19/9/20.
//

import Foundation

class DrawDisk      : BehaviorNode
{
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        print("drawdisk")
        
        game.texture!.drawDisk(options)
        return .Success
    }
}
