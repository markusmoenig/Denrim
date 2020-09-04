//
//  JSBridge.swift
//  Metal-Z
//
//  Created by Markus Moenig on 26/8/20.
//

import Foundation
import JavaScriptCore
import MetalKit

struct JSError
{
    var asset           : Asset? = nil
    var line            : Int32? = nil
    var column          : Int32? = nil
    var error           : String? = nil
}

class JSBridge
{
    var context         : JSContext? = nil
    var game            : Game!
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    deinit
    {
        context = nil
    }
    
    func compile(_ assetFolder: AssetFolder)
    {
        context = nil
        
        //if let scriptEditor = game.scriptEditor {
        //    scriptEditor.clearAnnotations()
        //}

        func countLines(_ string: String) -> Int32
        {
            let ns = string as NSString
            var lines : Int32 = 0
            
            ns.enumerateLines { (str, _) in
                lines += 1
            }
            
            return lines
        }
        
        guard let jsContext = JSContext.plus else {exit(-1)}
        context = jsContext
        context?.globalObject.setValue(JSValue(object: game.texture, in: context!), forProperty: "_mT")
        
        var from    : [Int32] = []
        var to      : [Int32] = []
        var assets  : [Asset] = []
        
        context?.exceptionHandler = { context, value in
            if self.game.jsError.error == nil {
                self.game.jsError.line = value?.objectForKeyedSubscript("line")?.toInt32()
                self.game.jsError.column = value?.objectForKeyedSubscript("column")?.toInt32()
                self.game.jsError.error = value?.toString()
                
                for (index, l) in to.enumerated() {
                    if l > self.game.jsError.line! {
                        self.game.jsError.asset = assets[index]
                        self.game.jsError.line = self.game.jsError.line! - from[index]
                    }
                }
            }
        }
        
        registerInContext(context!)

        var jsCode = ""
        
        for asset in assetFolder.assets {
            if asset.type == .JavaScript {
                if to.isEmpty {
                    from.append(0)
                } else {
                    from.append(to.last!)
                }
                jsCode += asset.value
                to.append(countLines(jsCode))
                assets.append(asset)
            }
        }
        
        context!.evaluateScript(jsCode)

        
        context?.evaluateScript("var game = new Game();")
    }
    
    func stop() {
        context = nil
    }
    
    func step()
    {
        if let context = context {
            context.evaluateScript("game.draw();")
        }
    }
    
    func execute(_ string: String)
    {
        if let context = context {
            context.evaluateScript(string)
        }
    }
    
    func loadAndExecuteResource(_ name: String)
    {
        guard let path = Bundle.main.path(forResource: name, ofType: "js", inDirectory: "Resources") else {
            return
        }
                
        if let string = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            context?.evaluateScript(string)
        }
    }
    
    func registerInContext(_ context: JSContext)
    {
        loadAndExecuteResource("Enums")
        context.setObject(System.self, forKeyedSubscript: "System" as (NSCopying & NSObjectProtocol))
        context.setObject(Vec4.self, forKeyedSubscript: "Vec4" as (NSCopying & NSObjectProtocol))
        context.setObject(Rect2D.self, forKeyedSubscript: "Rect2D" as (NSCopying & NSObjectProtocol))
        context.setObject(Texture2D.self, forKeyedSubscript: "Texture2D" as (NSCopying & NSObjectProtocol))
        
        // Fonts
        
        let openSans = Font(name: "OpenSans", game: game)
        game.resources[openSans.uuid] = openSans

        let square = Font(name: "Square", game: game)
        game.resources[square.uuid] = square

        let sourceCodePro = Font(name: "SourceCodePro", game: game)
        game.resources[sourceCodePro.uuid] = sourceCodePro

    }
}

extension JSContext {
    subscript(key: String) -> Any? {
        get {
            return self.objectForKeyedSubscript(key)
        }
        set{
            self.setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
}

@objc protocol JSConsoleExports: JSExport {
    static func log(_ msg: String)
}

class JSConsole: NSObject, JSConsoleExports {
    class func log(_ msg: String) {
        print(msg)
    }
}

@objc protocol JSPromiseExports: JSExport {
    func then(_ resolve: JSValue) -> JSPromise?
    func `catch`(_ reject: JSValue) -> JSPromise?
}

class JSPromise: NSObject, JSPromiseExports {
    var resolve: JSValue?
    var reject: JSValue?
    var next: JSPromise?
    var timer: Timer?
    
    func then(_ resolve: JSValue) -> JSPromise? {
        self.resolve = resolve
        
        self.next = JSPromise()
        
        self.timer?.fireDate = Date(timeInterval: 1, since: Date())
        self.next?.timer = self.timer
        self.timer = nil
        
        return self.next
    }
    
    func `catch`(_ reject: JSValue) -> JSPromise? {
        self.reject = reject
        
        self.next = JSPromise()
        
        self.timer?.fireDate = Date(timeInterval: 1, since: Date())
        self.next?.timer = self.timer
        self.timer = nil
        
        return self.next
    }
    
    func fail(error: String) {
        if let reject = reject {
            reject.call(withArguments: [error])
        } else if let next = next {
            next.fail(error: error)
        }
    }
    
    func success(value: Any?) {
        guard let resolve = resolve else { return }
        var result:JSValue?
        if let value = value  {
            result = resolve.call(withArguments: [value])
        } else {
            result = resolve.call(withArguments: [])
        }

        guard let next = next else { return }
        if let result = result {
            if result.isUndefined {
                next.success(value: nil)
                return
            } else if (result.hasProperty("isError")) {
                next.fail(error: result.toString())
                return
            }
        }
        
        next.success(value: result)
    }
}

extension JSContext {
    static var plus:JSContext? {
        let jsMachine = JSVirtualMachine()
        guard let jsContext = JSContext(virtualMachine: jsMachine) else {
            return nil
        }
        
        jsContext.evaluateScript("""
            Error.prototype.isError = () => {return true}
        """)
        jsContext["console"] = JSConsole.self
        jsContext["Promise"] = JSPromise.self
        
        let fetch:@convention(block) (String)->JSPromise? = { link in
            let promise = JSPromise()
            promise.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) {timer in
                timer.invalidate()
                
                if let url = URL(string: link) {
                    URLSession.shared.dataTask(with: url){ (data, response, error) in
                        if let error = error {
                            promise.fail(error: error.localizedDescription)
                        } else if
                            let data = data,
                            let string = String(data: data, encoding: String.Encoding.utf8) {
                            promise.success(value: string)
                        } else {
                            promise.fail(error: "\(url) is empty")
                        }
                        }.resume()
                } else {
                    promise.fail(error: "\(link) is not url")
                }
            }
            
            return promise
        }
        jsContext["fetch"] = unsafeBitCast(fetch, to: JSValue.self)
        
        return jsContext
    }
}
