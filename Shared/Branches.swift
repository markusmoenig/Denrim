//
//  Branches.swift
//  Denrim
//
//  Created by Markus Moenig on 20/9/20.
//

import Foundation


class SequenceBranch: BehaviorNode
{
    @discardableResult override func execute(game: Game, context: BehaviorContext, parent: BehaviorNode?) -> Result
    {
        var rc : Result = .Success
        for l in leaves {
            rc = l.execute(game: game, context: context, parent: self)
            if rc == .Failure {
                break
            }
        }
        return rc
    }
}
