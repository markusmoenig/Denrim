//
//  LuaBuilder.swift
//  Denrim
//
//  Created by Markus Moenig on 24/12/21.
//

import Foundation

class LuaBuilder {
    
    var game                        : Game
    
    var types                       : [String: String] = [:]
    var availableTypes              = ["Float2"]
    
    init(_ game: Game) {
        self.game = game
        
        for t in availableTypes {
            guard let resourcePath = Bundle.main.path(forResource: t, ofType: "lua", inDirectory: "Files/LuaTypes") else {
                return
            }
            
            if let source = try? String(contentsOfFile: resourcePath, encoding: String.Encoding.utf8) {
                types[t] = source
            }
        }
    }
    
    /// Used for syntax checking
    @discardableResult func compile(_ asset: Asset,_ path: String = "") -> CompileError
    {
        var error = CompileError()
        error.asset = asset
        error.column = 0
        
        //asset.vm = nil
        
        let vm = VirtualMachine()
        //asset.vm = vm
        
        addTypes(vm)
                
        switch vm.eval(asset.value, args: []) {
        case let .values(values):
            //print("success")
            if values.isEmpty == false {}
        case let .error(e):
            print(e)
        }
        
        return error
    }
    
    /// Compile a lua script variable at game startup and writes the globals into the behavior
    func compileIntoBehavior(context: BehaviorContext, variable: Lua1)
    {
        let path = variable.path.replacingOccurrences(of: "\"", with: "", options: NSString.CompareOptions.literal, range: nil)
        
        if let asset = game.assetFolder.getAsset(path, .Lua) {
          
            variable.vm = nil
            let vm = VirtualMachine()
            variable.vm = vm
            
            addTypes(vm)
                    
            switch vm.eval(asset.value, args: []) {
            case let .values(values):
                if values.isEmpty == false {}
                
                // Extract the globals into the context as variables
                extractGlobals(vm, context: context)
            case let .error(e):
                print(e)
            }
        }
    }
    
    /// Add the inbuilt types
    func addTypes(_ vm: VirtualMachine) {
        for (typeName, source) in types {
            switch vm.eval(source, args: []) {
            case let .values(values):
                if values.isEmpty {}
            case let .error(e):
                print("\(typeName) failure", e)
            }
        }
    }
    
    /// Extract globals as variables for the BehaviorContext
    func extractGlobals(_ vm: VirtualMachine, context: BehaviorContext) {
        
        let globals = vm.globals
        let keys = globals.keys()
                
        for k in keys {
            if let name = k as? String {
                if let t = globals[k] as? Table {
                    if let id = t["id"] as? String {
                        
                        // Float2
                        if id == "Float2" {
                            if let x = t["x"] as? Number {
                                if let y = t["y"] as? Number {
                                    let existing = context.variables[name]
                                    if let f2 = existing as? Float2 {
                                        f2.x = x.toFloat()
                                        f2.y = y.toFloat()
                                    } else
                                    if existing == nil {
                                        let f2 = Float2(name, x.toFloat(), y.toFloat())
                                        context.addVariable(f2)
                                    }
                                }
                            }
                        }
                        
                    }
                } else
                if let n = globals[k] as? Number {
                    let existing = context.variables[name]
                    if let f1 = existing as? Float1 {
                        f1.x = n.toFloat()
                    } else
                    if existing == nil {
                        let f1 = Float1(name, n.toFloat())
                        context.addVariable(f1)
                    }
                }
            }
        }
    }
}
