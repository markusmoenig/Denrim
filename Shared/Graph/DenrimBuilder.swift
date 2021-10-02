//
//  GraphBuilder.swift
//  Signed
//
//  Created by Markus Moenig on 13/12/20.
//

import Foundation
import Combine

class DenrimGraphBuilder: GraphBuilder {
    let game                : Game
    
    let selectionChanged    = PassthroughSubject<UUID?, Never>()
    
    var cursorTimer         : Timer? = nil
    var currentNode         : GraphNode? = nil
    
    init(_ game: Game)
    {
        self.game = game
        super.init()
    }
    
    @discardableResult override func compile(_ asset: Asset, silent: Bool = false) -> CompileError
    {
        var error = super.compile(asset, silent: silent)
        
        if silent == false {
            
            if game.state == .Idle {
                if error.error != nil {
                    error.line = error.line! + 1
                    game.scriptEditor?.setError(error)
                } else {
                    game.scriptEditor?.clearAnnotations()
                }
            }
        }
        
        return error
    }
    
    func startTimer(_ asset: Asset)
    {
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: 0.2,
                                             target: self,
                                             selector: #selector(self.cursorCallback),
                                             userInfo: nil,
                                             repeats: true)
            self.cursorTimer = timer
        })
    }
    
    func stopTimer()
    {
        if cursorTimer != nil {
            cursorTimer?.invalidate()
            cursorTimer = nil
        }
    }
    
    var lastContextHelpName :String? = "d"
    @objc func cursorCallback(_ timer: Timer) {
        if game.state == .Idle && game.scriptEditor != nil {
            /*
            game.scriptEditor!.getSessionCursor({ (line, column) in
            
                if let asset = self.game.assetFolder.current, asset.type == .Source {
                    if let context = asset.graph {
                        if let node = context.lines[line] {
                            if node.name != self.lastContextHelpName {
                                self.currentNode = node
                                self.selectionChanged.send(node.id)
                                self.core.contextText = self.generateNodeHelpText(node)
                                self.core.contextTextChanged.send(self.core.contextText)
                                self.lastContextHelpName = node.name
                            }
                        } else {
                            if self.lastContextHelpName != nil {
                                self.currentNode = nil
                                self.selectionChanged.send(nil)
                                self.core.contextText = ""
                                self.core.contextTextChanged.send(self.core.contextText)
                                self.lastContextHelpName = nil
                            }
                        }
                    }
                }
            })*/
        }
    }
    
    /// Generates a markdown help text for the given node
    func generateNodeHelpText(_ node:GraphNode) -> String
    {
        var help = "## " + node.name + "\n"
        help += node.getHelp()
        let options = node.getOptions()
        if options.count > 0 {
            help += "\nOptional Parameters\n"
        }
        for o in options {
            help += "* **\(o.name)** (\(o.variable.getTypeName())) - " + o.help + "\n"
        }
        return help
    }
    
    /*
    /// Go to the line of the node
    func gotoNode(_ node: GraphNode)
    {
        if currentNode != node {
            game.scriptEditor?.gotoLine(node.lineNr+1)
            currentNode = node
        }
    }*/
}
