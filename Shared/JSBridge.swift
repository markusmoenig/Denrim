//
//  JSBridge.swift
//  Metal-Z
//
//  Created by Markus Moenig on 26/8/20.
//

import Foundation
import JavaScriptCore
import MetalKit

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
        
        if let scriptEditor = game.scriptEditor {
            scriptEditor.clearAnnotations()
        }
        
        //context = JSContext()!
        guard let jsContext = JSContext.plus else {exit(-1)}
        context = jsContext
        context?.globalObject.setValue(JSValue(object: game.texture, in: context!), forProperty: "_mT")

        context?.exceptionHandler = { context, value in
            let lineNumber = value?.objectForKeyedSubscript("line")
            if let error = value?.toString() {
                if let scriptEditor = self.game.scriptEditor {
                    scriptEditor.setAnnotation(lineNumber: lineNumber!.toInt32(), text: error)
                }
            }
        }
        
        registerInContext(context!)

        for asset in assetFolder.assets {
            if asset.type == .JavaScript {
                context!.evaluateScript(asset.value)
            }
        }
        
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
        context.setObject(Color.self, forKeyedSubscript: "Color" as (NSCopying & NSObjectProtocol))
        context.setObject(Rect2D.self, forKeyedSubscript: "Rect2D" as (NSCopying & NSObjectProtocol))
        context.setObject(Texture2D.self, forKeyedSubscript: "Texture2D" as (NSCopying & NSObjectProtocol))
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
