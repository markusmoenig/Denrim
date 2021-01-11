//
//  Branches.swift
//  Denrim
//
//  Created by Markus Moenig on 20/9/20.
//

import Foundation

class WhileBranch: BehaviorNode
{
    var variable: Bool1? = nil
    var not: Bool = false
    
    var test: String = ""
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "while"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        for key in options {
            if key.key == "not" {
                not = true
            } else {
                let opts : [String:String] = ["bool":key.key]
                test = key.key
                variable = extractBool1Value(opts, container: context, error: &error)
            }
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        if variable == nil {
            return .Failure
        }
        var result : Result = .Success
        
        for l in leaves {
            if not == false {
                if variable!.x == true {
                    _ = l.execute(game: game, context: context, tree: tree)
                } else {
                    result = .Failure
                }
            } else {
                if variable!.x == false {
                    _ = l.execute(game: game, context: context, tree: tree)
                } else {
                    result = .Failure
                }
            }
        }
        return result
    }
}

class RepeatBranch: BehaviorNode
{
    var repetitions: Int1? = Int1(1)
    
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "repeat"
    }
    
    override func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
        for key in options {
            let opts : [String:String] = ["int":key.key]
            repetitions = extractInt1Value(opts, container: context, parameters: tree.parameters, error: &error)
        }
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        var result : Result = .Success
        for _ in 0..<repetitions!.x {
            for l in leaves {
                let rc = l.execute(game: game, context: context, tree: tree)
                if rc == .Failure {
                    result = .Failure
                }
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
                context.addFailure(lineNr: lineNr)
                return .Failure
            }
        }
        return .Success
    }
}

class SelectorBranch: BehaviorNode
{
    override init(_ options: [String:Any] = [:])
    {
        super.init(options)
        name = "selector"
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        for l in leaves {
            let rc = l.execute(game: game, context: context, tree: tree)
            if rc == .Success {
                return .Success
            }
        }
        context.addFailure(lineNr: lineNr)
        return .Failure
    }
}
