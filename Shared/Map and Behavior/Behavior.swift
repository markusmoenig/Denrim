//
//  Behavior.swift
//  Denrim
//
//  Created by Markus Moenig on 18/9/20.
//

import Foundation

class BehaviorNode {
    
    enum Result {
        case Success, Failure, Running, Unused
    }
    
    // Only applicable for branch nodes like a sequence
    var leaves              : [BehaviorNode] = []
    
    var name                : String = ""
    var givenName           : String = ""

    var lineNr              : Int32 = 0
    
    // Options
    var options             : [String:Any]
    
    init(_ options: [String:Any] = [:])
    {
        self.options = options
    }
    
    /// Verify options
    func verifyOptions(context: BehaviorContext, tree: BehaviorTree, error: inout CompileError) {
    }
    
    /// Executes a node inside a behaviour tree
    @discardableResult func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        return .Success
    }
}

class BehaviorTree  : BehaviorNode
{
    var parameters  : [BaseVariable] = []

    init(_ name: String)
    {
        super.init()
        self.name = name
    }
    
    @discardableResult override func execute(game: Game, context: BehaviorContext, tree: BehaviorTree?) -> Result
    {
        
        let prevParams = context.parameters
        context.parameters = parameters
        for leave in leaves {
            leave.execute(game: game, context: context, tree: self)
        }
        context.parameters = prevParams
        return .Success
    }
}

class BehaviorContext       : VariableContainer
{
    var trees               : [BehaviorTree] = []
    var failedAt            : [Int32] = []
    
    var lines               : [Int32:String] = [:]
            
    let game                : Game
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func clear()
    {
        trees = []
        variables = [:]
        lines = [:]
    }
    
    func addVariable(_ variable: BaseVariable)
    {
        variables[variable.name] = variable
    }
    
    override func getVariableValue(_ name: String) -> BaseVariable?
    {
        // Globals
        if name == "Time" {
            return game._Time
        } else
        if name == "Aspect" {
            return game._Aspect
        }

        return super.getVariableValue(name)
    }
    
    func getTree(_ name: String) -> BehaviorTree?
    {
        // Check the context variables
        for t in trees {
            if t.name == name {
                return t
            }
        }
        return nil
    }
    
    func addFailure(lineNr: Int32)
    {
        failedAt.append(lineNr)
    }
    
    @discardableResult func execute(name: String) -> BehaviorNode.Result
    {        
        failedAt = []
        for tree in trees {
            if tree.name == name {
                tree.execute(game: game, context: self, tree: tree)
                return .Success
            }
        }
        return .Failure
    }
    
    func debug()
    {
        for tree in trees {
            print(tree.name, tree.leaves.count )
            for l in tree.leaves {
                print("  \(l.name)", l.leaves.count)
                for l in tree.leaves {
                    print("    \(l.name)", l.leaves.count)
                }
            }
        }
    }
}
