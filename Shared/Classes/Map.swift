//
//  Map.swift
//  Denrim
//
//  Created by Markus Moenig on 7/9/20.
//

import MetalKit
import JavaScriptCore

struct MapImage {
    
    var resourceName    : String
    var options         : [String:Any]
}

struct MapSequence {
    
    var resourceNames   : [String] = []
    var options         : [String:Any]
}

struct MapAlias {
    
    enum AliasType {
        case Image
    }
    
    var type            : AliasType
    var pointsTo        : String
    var options         : [String:Any]
}

struct MapLayer {

    var data            : [String] = []
    var options         : [String:Any]
    var endLine         : Int32 = 0
}

struct MapObject2D {

    var objectValue     : JSManagedValue? = nil
    var positionValue   : JSManagedValue? = nil
    var body            : b2Body? = nil
    
    var name            : String = ""
    var options         : [String:Any]
}

struct MapFixture2D {
    var options         : [String:Any]
}

struct MapPhysics2D {

    var ppm             : Float = 100
    var world           : b2World? = nil
    var options         : [String:Any]
}

struct MapScene {

    var options         : [String:Any]
}

@objc protocol Map_JSExports: JSExport {
    
    static func create(_ object: [AnyHashable:Any]) -> Map?

    func draw(_ object: [AnyHashable:Any])
}

class Map                   : NSObject, Map_JSExports
{
    var images              : [String:MapImage] = [:]
    var aliases             : [String:MapAlias] = [:]
    var sequences           : [String:MapSequence] = [:]
    var layers              : [String:MapLayer] = [:]
    var scenes              : [String:MapScene] = [:]
    var objects2D           : [String:MapObject2D] = [:]
    var fixtures2D          : [String:MapFixture2D] = [:]
    var physics2D           : [String:MapPhysics2D] = [:]

    var lines               : [Int32:String] = [:]
    
    var resources           : [String:Any] = [:]

    weak var game           : Game? = nil
    weak var texture        : Texture2D? = nil
    
    deinit {
        clear()
        resources = [:]
    }
    
    override init()
    {
        super.init()
    }
    
    func clear(_ releaseResources: Bool = false)
    {
        print("release map")
        images = [:]
        aliases = [:]
        layers = [:]
        scenes = [:]
        objects2D = [:]
        fixtures2D = [:]
        physics2D = [:]
        lines = [:]
        if releaseResources {
            resources = [:]
        }
    }
    
    class func create(_ object: [AnyHashable:Any]) -> Map?
    {
        let context = JSContext.current()

        let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
        let game = main.game!
        
        if let mapName = object["name"] as? String {
         
            if let asset = game.assetFolder.getAsset(mapName, .Map) {
                let error = game.mapBuilder.compile(asset)
                if error.error == nil {
                    if let map = asset.map {
                        
                        // Physics2D
                        for (variable, object) in map.physics2D {
                            var gravity = b2Vec2(0.0, -10.0)
                            if let gravityOption = object.options["gravity"] as? Vec2 {
                                gravity.x = gravityOption.x
                                gravity.y = gravityOption.y
                            }
                            map.physics2D[variable]!.world = b2World(gravity: gravity)
                        }
                        
                        // Object2D
                        for (variable, object) in map.objects2D {
                            if let className = object.options["class"] as? String {
                                let cmd = "var \(variable) = new \(className)(); \(variable)"
                                map.objects2D[variable]?.objectValue = JSManagedValue(value: context?.evaluateScript(cmd))
                                map.objects2D[variable]?.positionValue = JSManagedValue(value: context?.evaluateScript("\(variable).position"))

                                if let physicsName = object.options["physics"] as? String {
                                    if let physics2D = map.physics2D[physicsName] {
                                        
                                        let ppm = physics2D.ppm
                                        // Define the dynamic body. We set its position and call the body factory.
                                        let bodyDef = b2BodyDef()
                                        bodyDef.type = b2BodyType.staticBody

                                        if let position = object.options["position"] as? Vec2 {
                                            bodyDef.position.set(position.x / ppm, position.y / ppm)
                                        } else {
                                            bodyDef.position.set(100.0 / ppm, 100.0 / ppm)
                                        }
                                        
                                        var isDynamic = false
                                        if let mode = object.options["mode"] as? String {
                                            if mode.lowercased() == "dynamic" {
                                                bodyDef.type = b2BodyType.dynamicBody
                                                isDynamic = true
                                                print(variable, isDynamic)
                                            }
                                        }

                                        map.objects2D[variable]?.body = physics2D.world!.createBody(bodyDef)
                                        
                                        // Parse for fixtures for this object
                                        for (_, fixture) in map.fixtures2D {
                                            if let objectName = fixture.options["object"] as? String {
                                                if variable == objectName {
                                                    
                                                    let shape = b2PolygonShape()
                                                    
                                                    if let box = object.options["box"] as? Vec2 {
                                                        shape.setAsBox(halfWidth: box.x / ppm, halfHeight: box.y / ppm)
                                                    } else {
                                                        shape.setAsBox(halfWidth: 1.0 / ppm, halfHeight: 1.0 / ppm)
                                                    }
                                                    
                                                    // Define the dynamic body fixture.
                                                    let fixtureDef = b2FixtureDef()
                                                    fixtureDef.shape = shape
                                                    
                                                    // Set the box density to be non-zero, so it will be dynamic.
                                                    if isDynamic {
                                                        fixtureDef.density = 1.0
                                                    }
                                                    
                                                    // Override the default friction.
                                                    fixtureDef.friction = 0.3
                                                    
                                                    // Add the shape to the body.
                                                    map.objects2D[variable]?.body!.createFixture(fixtureDef)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    return asset.map!
                    //promise.success(value: asset.map!)
                } else {
                    //promise.fail(error: error.error!)
                }
            } else {
                //promise.fail(error: "Map not found")
            }
        } else {
            //promise.fail(error: "Map name not specified")
        }
    
        
        return nil
    }
    
    /*
    class func compile(_ object: [AnyHashable:Any]) -> JSPromise
    {
        let context = JSContext.current()
        let promise = JSPromise()

        DispatchQueue.main.async {
            let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
            let game = main.game!
            
            if let mapName = object["name"] as? String {
             
                if let asset = game.assetFolder.getAsset(mapName, .Map) {
                    let error = game.mapBuilder.compile(asset)
                                        
                    if error.error == nil {
                        promise.success(value: asset.map!)
                    } else {
                        promise.fail(error: error.error!)
                    }
                } else {
                    promise.fail(error: "Map not found")
                }
            } else {
                promise.fail(error: "Map name not specified")
            }
        }
        
        return promise
    }*/
    
    func draw(_ object: [AnyHashable:Any])
    {
        let context = JSContext.current()
        let main = context?.objectForKeyedSubscript("_mT")?.toObject() as! Texture2D
        game = main.game!
        
        if let sceneName = object["scene"] as? String {
            if let scene = scenes[sceneName] {
                drawScene(0, 0, scene)
            }
        }
        
        for (_, physics2D) in physics2D {
        
            let timeStep: b2Float = 1.0 / 60.0
            let velocityIterations = 6
            let positionIterations = 2
        
            physics2D.world!.step(timeStep: timeStep, velocityIterations: velocityIterations, positionIterations: positionIterations)
            
            let ppm = physics2D.ppm

            for (v, object) in objects2D {
                if let body = object.body {
                    print(v, body.position.x, body.position.y)
                    object.positionValue?.value.setValue(body.position.x * ppm, forProperty: "x")
                    object.positionValue?.value.setValue(body.position.y * ppm, forProperty: "y")
                }
            }
        }
        
        for (_, object) in objects2D {
            
            if let value = object.objectValue {
                value.value.invokeMethod("draw", withArguments: [])
                //context?.evaluateScript("\(variable).draw();")
            }
        }
    }
    
    func getImageResource(_ name: String) -> Texture2D?
    {
        if let texture = resources[name] as? Texture2D {
            return texture
        } else {
            let array = name.split(separator: ":")
            if array.count == 2 {
                if let asset = game?.assetFolder.getAssetById(UUID(uuidString: String(array[0]))!, .Image) {
                    if let index = Int(array[1]) {
                    
                        let data = asset.data[index]
                        
                        let texOptions: [MTKTextureLoader.Option : Any] = [.generateMipmaps: false, .SRGB: false]
                        if let texture  = try? game!.textureLoader.newTexture(data: data, options: texOptions) {
                            let texture2D = Texture2D(game!, texture: texture)
                            resources[name] = texture2D
                            return texture2D
                        }
                    }
                }
            }
        }
        return nil
    }

    @discardableResult func drawAlias(_ x: Float,_ y: Float,_ alias: MapAlias, scale: Float = 1) -> (Float, Float)
    {
        var object : [AnyHashable : Any] = [:]
        var rc     : (Float, Float) = (0,0)

        if alias.type == .Image {
            if let image = images[alias.pointsTo] {
                
                if let texture2D = getImageResource(image.resourceName) {
                    var width = texture2D.width * scale
                    var height = texture2D.height * scale

                    object["x"] = x
                    object["y"] = y
                    object["width"] = width
                    object["height"] = height
                    object["texture"] = texture2D
                    
                    if let v = alias.options["rect"] as? Rect2D {
                        object["rect"] = v
                        width = v.width * scale
                        height = v.height * scale
                        
                        object["width"] = width
                        object["height"] = height
                    }
                
                    game?.texture?.drawTexture(object)

                    if let v = alias.options["repeatx"] as? Bool {
                        if v == true {
                            var posX : Float = x + width
                            while posX < game!.texture!.width {
                                object["x"] = posX
                                game?.texture?.drawTexture(object)
                                posX += width
                            }
                        }
                    }
                    
                    rc.0 = width
                    rc.1 = height
                }
            }
        }
        
        return rc
    }
    
    func drawLayer(_ x: Float,_ y: Float,_ layer: MapLayer, scale: Float = 1)
    {
        var xPos = x
        var yPos = y
        
        for line in layer.data {
            
            var index     : Int = 0
            var maxHeight : Float = 0
            
            while index < line.count - 1 {
                
                let a = String(line[line.index(line.startIndex, offsetBy: index)]) + String(line[line.index(line.startIndex, offsetBy: index+1)])
                if let alias = aliases[a] {
                    let advance = drawAlias(xPos, yPos, alias, scale: scale)
                    xPos += advance.0
                    if advance.1 > maxHeight {
                        maxHeight = advance.1
                    }
                }
                index += 2
            }
            
            yPos -= maxHeight
            xPos = x
        }
    }
    
    func drawScene(_ x: Float,_ y: Float,_ scene: MapScene, scale: Float = 1)
    {
        if let sceneLayers = scene.options["layers"] as? [String] {
            for l in sceneLayers {
                if let layer = layers[l] {
                    
                    var layerOffX : Float = 0
                    var layerOffY : Float = 0
                    
                    if let sOff = layer.options["sceneoffset"] as? Vec2 {
                        layerOffX = sOff.x
                        layerOffY = sOff.y
                    }
                    drawLayer(x + layerOffX, y + layerOffY, layer, scale: scale)
                }
            }
        }
    }
}
