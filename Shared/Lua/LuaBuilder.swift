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
            print("success")
            extractGlobals(asset)
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
                //extractGlobals(asset)
                if values.isEmpty == false {}
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
    
    /// Extract globals
    func extractGlobals(_ asset: Asset) {
        
        /*
        let globals = asset.vm!.globals
        let keys = globals.keys()
        
        print(keys)
        
        for k in keys {
            if let t = globals[k] as? Table {
                if let id = t["id"] as? String {
                    print(k, "here", id)
                }
            } else
            if let n = globals[k] as? Number {
                print(k, n.toFloat())
            }
        }*/
    }
}
