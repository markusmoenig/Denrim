//
//  Branches.swift
//  Denrim
//
//  Created by Markus Moenig on 20/9/20.
//

import Foundation

class RepeatBranch: BehaviorNode
{
    var repetitions: Int1? = nil
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "repeat"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        for key in options {
            let opts : [String:String] = ["int":key.key]
            repetitions = extractInt1Value(opts, context: context, tree: tree, error: &error)
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        var result : Result = .Success
        for l in leaves {
            let rc = l.execute(game: game, context: context, tree: tree)
            if rc == .Failure {
                result = .Failure
            }
        }
        return result
    }
}

class SequenceBranch: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "sequence"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        for l in leaves {
            let rc = l.execute(game: game, context: context, tree: tree)
            if rc == .Failure {
                return .Failure
            }
        }
        return .Success
    }
}
