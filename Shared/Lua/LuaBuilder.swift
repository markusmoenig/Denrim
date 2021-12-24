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
    
    @discardableResult func compile(_ asset: Asset,_ path: String = "") -> CompileError
    {
        var error = CompileError()
        error.asset = asset
        error.column = 0
        
        asset.vm = nil
        
        let vm = VirtualMachine()
        asset.vm = vm
        
        addTypes(asset)
                
        switch vm.eval(asset.value, args: []) {
        case let .values(values):
            print("success")
            if values.isEmpty == false {
                print(values.first!)
            }
        case let .error(e):
            print(e)
        }
        
        return error
    }
    
    /// Add the inbuilt
    func addTypes(_ asset: Asset) {
        for (typeName, source) in types {
            switch asset.vm!.eval(source, args: []) {
            case let .values(values):
                if values.isEmpty {}
            case let .error(e):
                print("\(typeName) failure", e)
            }
        }
    }
}
