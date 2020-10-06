//
//  Branches.swift
//  Denrim
//
//  Created by Markus Moenig on 20/9/20.
//

import Foundation


class SequenceBranch: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "Sequence"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        for l in leaves {
            let rc = l.execute(game: game, context: context, tree: tree)
            if rc == .Failure {
                //return .Failure
                break
            }
        }
        return .Success
    }
}
