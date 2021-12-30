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
        addPrint(vm)
        addSceneClass(vm)

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
            addPrint(vm)
            addSceneClass(vm)
            
            injectGlobals(vm, context: context)
                    
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
    
    /// AddPrint
    func addPrint(_ vm: VirtualMachine) {
                
        vm.globals["_print"] = vm.createFunction([String.arg]) { args in
            if args.values.isEmpty == false {                                
                let text = args.string
                self.game.logText += text + "\n"
            }
            return .nothing
        }
        
        _ = vm.eval("""
        
        print = function(...)
            local args = {...}
            local printResult = ""
            for i,v in ipairs(args) do
                if i > 1 then
                    printResult = printResult .. ", "
                end
                printResult = printResult .. tostring(v)
            end
            _print(printResult)
        end
        
        """, args: [])
    }
    
    /// Adds the scene class, giving lua scripts access to information about the current scene
    func addSceneClass(_ vm: VirtualMachine) {

        class LuaDenrimScene : CustomTypeInstance {
            
            var name        = ""
            //var cmd         : SignedCommand? = nil
            
            static func luaTypeName() -> String {
                return "scene"
            }
        }
        
        let sceneLib:CustomType<LuaDenrimScene> = vm.createCustomType { type in
        
        }
        
        // Get named float for the cmd
        sceneLib["getTileSize"] = vm.createFunction([]) { args in
            /*
            if args.values.count == 2 {
                let (paramName) = (args.string)
                if let cmd = cmd.cmd {
                    if let v = self.getFloat(name: paramName, groups: cmd.allDataGroups()) {
                        return .value(Double(v))
                    }
                }
            }*/
            
            if let map = self.game.currentMap?.map {
             
                if let layer = map.layers["town"] {
                    
                    let xOff = layer.options.gridSize.x / map.canvasSize.x * map.aspect.x * 100.0
                    
                    return .value(Double(xOff))
                }
            }
            
            return .value(0)
        }
        
        // Get the type of the given grid position
        sceneLib["getTileTypeAt"] = vm.createFunction([Number.arg, Number.arg]) { args in
            
            var x = 0
            var y = 0
                     
            /*
            if args.values.count == 1 {
                let table = args.table
                let v = self.getFloat2(table)
                x = Int(v.x)
                y = Int(v.y)
            } else {*/
                
            if args.values.count == 2 {
                x = Int(args.number.toInteger())
                y = Int(args.number.toInteger())
            }
            
            if let map = self.game.currentMap?.map, x >= 0, y >= 0 {
                for (_, layer) in map.layers {
                    
                    if layer.options.gridBased == false || layer.maxWidth == 1 {
                        continue
                    }
                    
                    if y < layer.maxHeight && x < layer.maxWidth {
                        let line = layer.data[y]
                        if x < line.line.count {
                            return .value(line.line[x].options.type)
                        }
                    }
                }
            }
            
            return .value(-1)
        }
        
        vm.globals["scene"] = sceneLib
    }

    /// Runs the lua script function given by its name
    func runLuaFunction(_ variable: Lua1, context: BehaviorContext, functionName: String) {
        if let vm = variable.vm {
            if let f = vm.globals[functionName] as? Function {
                injectGlobals(vm, context: context)
                _ = f.call([])
                extractGlobals(vm, context: context)
            }
        }
    }
    
    /// Injects the variables of the context as global script variables
    func injectGlobals(_ vm: VirtualMachine, context: BehaviorContext) {
        for (name, v) in context.variables {
            if let f1 = v as? Float1 {
                vm.globals[name] = Double(f1.x)
            } else
            if let f2 = v as? Float2 {
                if let table = vm.globals[name] as? Table {
                    table["x"] = Double(f2.x)
                    table["y"] = Double(f2.y)
                } else {
                    let table = vm.createTable()
                    table["id"] = "Float2"
                    table["x"] = Double(f2.x)
                    table["y"] = Double(f2.y)
                    vm.globals[name] = table
                }
            } else
            if let f3 = v as? Float3 {
                if let table = vm.globals[name] as? Table {
                    table["x"] = Double(f3.x)
                    table["y"] = Double(f3.y)
                    table["z"] = Double(f3.z)
                } else {
                    let table = vm.createTable()
                    table["id"] = "Float3"
                    table["x"] = Double(f3.x)
                    table["y"] = Double(f3.y)
                    table["z"] = Double(f3.z)
                    vm.globals[name] = table
                }
            } else
            if let f4 = v as? Float4 {
                if let table = vm.globals[name] as? Table {
                    table["x"] = Double(f4.x)
                    table["y"] = Double(f4.y)
                    table["z"] = Double(f4.z)
                    table["w"] = Double(f4.z)
                } else {
                    let table = vm.createTable()
                    table["id"] = "Float4"
                    table["x"] = Double(f4.x)
                    table["y"] = Double(f4.y)
                    table["z"] = Double(f4.z)
                    table["w"] = Double(f4.z)
                    vm.globals[name] = table
                }
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
                    
                    if name == "scene" { continue }
                    
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
                        } else
                        // Float3
                        if id == "Float3" {
                            if let x = t["x"] as? Number {
                                if let y = t["y"] as? Number {
                                    if let z = t["z"] as? Number {
                                        let existing = context.variables[name]
                                        if let f3 = existing as? Float3 {
                                            f3.x = x.toFloat()
                                            f3.y = y.toFloat()
                                            f3.z = z.toFloat()
                                        } else
                                        if existing == nil {
                                            let f3 = Float3(name, x.toFloat(), y.toFloat(), z.toFloat())
                                            context.addVariable(f3)
                                        }
                                    }
                                }
                            }
                        } else
                        // Float4
                        if id == "Float4" {
                            if let x = t["x"] as? Number {
                                if let y = t["y"] as? Number {
                                    if let z = t["z"] as? Number {
                                        if let w = t["w"] as? Number {
                                            let existing = context.variables[name]
                                            if let f4 = existing as? Float4 {
                                                f4.x = x.toFloat()
                                                f4.y = y.toFloat()
                                                f4.z = z.toFloat()
                                                f4.w = w.toFloat()
                                            } else
                                            if existing == nil {
                                                let f4 = Float4(name, x.toFloat(), y.toFloat(), z.toFloat(), w.toFloat())
                                                context.addVariable(f4)
                                            }
                                        }
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
    
    /// Extracts an float2 value from the given lua table
    func getFloat2(_ table: Table) -> float2 {
        var v = float2()
        if let x = table["x"] as? Number {
            v.x = x.toFloat()
        }
        if let y = table["y"] as? Number {
            v.y = y.toFloat()
        }
        return v
    }
}
