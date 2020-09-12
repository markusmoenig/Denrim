//
//  Font.swift
//  Denrim
//
//  Created by Markus Moenig on 4/9/20.
//

import MetalKit
import JavaScriptCore

struct BMChar       : Decodable {
    let id          : Int
    let index       : Int
    let char        : String
    let width       : Float
    let height      : Float
    let xoffset     : Float
    let yoffset     : Float
    let xadvance    : Float
    let chnl        : Int
    let x           : Float
    let y           : Float
    let page        : Int
}

struct BMCommon     : Decodable {
    let lineHeight  : Float
}

struct BMFont       : Decodable {
    let pages       : [String]
    let chars       : [BMChar]
    let common      : BMCommon
}

/*
class CharBuffer
{
    let vertexBuffer: MTLBuffer
    let dataBuffer  : MTLBuffer
    
    init(vertexBuffer: MTLBuffer, dataBuffer: MTLBuffer)
    {
        self.vertexBuffer = vertexBuffer
        self.dataBuffer = dataBuffer
    }
    
    deinit {
        vertexBuffer.setPurgeableState(.empty)
        dataBuffer.setPurgeableState(.empty)
    }
}

@objc protocol TextBuffer_JSExports: JSExport {
}

class TextBuffer    : NSObject, TextBuffer_JSExports
{
    var chars       : [CharBuffer]
    var x, y        : Float
    var viewWidth   : Float
    var viewHeight  : Float

    init(chars: [CharBuffer], x: Float, y: Float, viewWidth: Float, viewHeight: Float)
    {
        self.chars = chars
        self.x = x
        self.y = y
        self.viewWidth = viewWidth
        self.viewHeight = viewHeight
    }
}*/

@objc protocol Font_JSExports: JSExport {
    
    var name        : String { get }

    static func getAvailableFonts() -> [String]
    static func create(_ name: String) -> Font?
    //func createTextBuffer(_ object: [AnyHashable:Any]) -> TextBuffer
}

class Font          : NSObject, Font_JSExports
{
    var uuid        = UUID()
    
    var name        : String
    var game        : Game
    
    var atlas       : MTLTexture?
    var bmFont      : BMFont?

    init(name: String, game: Game)
    {
        self.name = name
        self.game = game
        
        super.init()
        
        atlas = loadTexture( name )
        
        let path = Bundle.main.path(forResource: name, ofType: "json")!
        let data = NSData(contentsOfFile: path)! as Data
        
        guard let font = try? JSONDecoder().decode(BMFont.self, from: data) else {
            print("Error: Could not decode JSON of \(name)")
            return
        }
        bmFont = font
    }
    
    deinit {
        clear()
    }
    
    func clear()
    {
        if let texture = atlas {
            texture.setPurgeableState(.empty)
            atlas = nil
            bmFont = nil
        }
        print("freeing font", name)
    }
    
    class func getAvailableFonts() -> [String]
    {
        let game = getGameObject()

        return game.availableFonts
    }
    
    class func create(_ name: String) -> Font?
    {
        let game = getGameObject()

        if game.availableFonts.firstIndex(of: name) != nil {
            let font = Font(name: name, game: game)
            game.resources.append(font)
            return font//JSManagedValue(value: JSValue(object: font, in: game.jsBridge.context))
        }

        return nil
    }
    
    /*
    func createTextBuffer(_ object: [AnyHashable:Any]) -> TextBuffer
    {
        /*
        //var x : Float; if let v = object["x"] as? Float { x = v } else { x = 0 }
        //var y : Float; if let v = object["y"] as? Float { y = v } else { y = 0 }
        let size : Float; if let v = object["size"] as? Float { size = v } else { size = 1 }
        let text : String; if let v = object["text"] as? String { text = v } else { text = "" }

        var array : [CharBuffer] = []
        
        //if textBuffer != nil {
        //    print("No buffer for", text, textBuffer, textBuffer!.x, x, textBuffer!.y, y)
        //}

        for c in text {
            let bmChar = getItemForChar( c )
            if bmChar != nil {
                //let char = drawChar( font, char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: y + bmChar!.yoffset * adjScale, color: color, scale: scale, fragment: fragment)
                array.append(char)
                //print( bmChar?.char, bmChar?.x, bmChar?.y, bmChar?.width, bmChar?.height)
                posX += bmChar!.xadvance * adjScale;
            
            }
        }
        */
    
        return TextBuffer(chars:array, x: x, y: y, viewWidth: mmRenderer.width, viewHeight: mmRenderer.height)
    }*/
    
    func loadTexture(_ name: String, mipmaps: Bool = false, sRGB: Bool = false ) -> MTLTexture?
    {
        let path = Bundle.main.path(forResource: name, ofType: "tiff")!
        let data = NSData(contentsOfFile: path)! as Data
        
        let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : mipmaps, .SRGB : sRGB]
        
        return try? game.textureLoader.newTexture(data: data, options: options)
    }
    
    func getLineHeight(_ fontScale: Float) -> Float
    {
        return (bmFont!.common.lineHeight * fontScale) / 2
    }
    
    func getItemForChar(_ char: Character ) -> BMChar?
    {
        let array = bmFont!.chars
        
        for item in array {
            if Character( item.char ) == char {
                return item
            }
        }
        return nil
    }
    
    @discardableResult func getTextRect(text: String, scale: Float = 1.0, rectToUse: MMRect? = nil) -> MMRect
    {
        var rect : MMRect
        if rectToUse == nil {
            rect = MMRect()
        } else {
            rect = rectToUse!
        }
        
        rect.width = 0
        rect.height = 0
        
        for c in text {
            let bmChar = getItemForChar( c )
            if bmChar != nil {
                rect.width += bmChar!.xadvance * scale / 2;
                rect.height = max( rect.height, (bmChar!.height /*- bmChar!.yoffset*/) * scale / 2)
            }
        }
        
        return rect;
    }
    
    /// Returns the game object for this context
    static func getGameObject() -> Game {
        let context = JSContext.current()
        let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
        //let main = (context!["_mT"] as? JSValue)!.toObject() as! Texture2D
        return main.game!
    }
}
