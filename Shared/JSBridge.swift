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
        
        context = JSContext()!        
        context?.globalObject.setValue(JSValue(object: game.texture, in: context!), forProperty: "__mainTexture")

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
