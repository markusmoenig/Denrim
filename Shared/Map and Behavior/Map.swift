//
//  Map.swift
//  Denrim
//
//  Created by Markus Moenig on 7/9/20.
//

import MetalKit
import AVFoundation
import CryptoKit

class Map
{
    enum ScaleMode {
        case UpDown, Fixed
    }
    
    var scaleMode           : ScaleMode = .UpDown
    
    // Resources
    var images              : [String:MapImage] = [:]
    var audio               : [String:MapAudio] = [:]
    var aliases             : [String:MapAlias] = [:]
    var sequences           : [String:MapSequence] = [:]
    var layers              : [String:MapLayer] = [:]
    var scenes              : [String:MapScene] = [:]
    var behavior            : [String:MapBehavior] = [:]
    var physics2D           : [String:MapPhysics2D] = [:]

    var shapes2D            : [String:MapShape2D] = [:]
    var shaders             : [String:MapShader] = [:]
    
    var gridInstancers      : [String:MapGridInstance2D] = [:]
    var onDemandInstancers  : [String:MapOnDemandInstance2D] = [:]
    
    var timer               : [Timer] = []

    var commands            : [MapCommand] = []

    var lines               : [Int32:String] = [:]
    var commandLines        : [Int32:String] = [:]

    var resources           : [String:Any] = [:]
    
    var subMaps             : [Map] = []
    
    var layerPreviewZoom    : Float = 1
    
    var renderEncoder       : MTLRenderCommandEncoder!

    // Rendering
    
    var camera2D            = Camera2D()
    var globalAlpha         : Float = 1
    
    var textureState        : MetalStates.States = .DrawTexture
    
    // Have to be set!
    var game                : Game!
    var texture             : Texture2D!
    var aspect              : Float3!
    
    var canvasSize          = Float2(0,0)
    var viewBorder          = Float2(0,0)
    
    var currentSampler      : MTLSamplerState!
    
    var lastPreviewOffset   = float2(0,0)

    deinit {
        clear()
        resources = [:]
    }
    
    // Clears all assets of this map and it's subMaps
    func clear(_ releaseResources: Bool = false)
    {
        images = [:]
        audio = [:]
        aliases = [:]
        sequences = [:]
        layers = [:]
        scenes = [:]
        behavior = [:]
        physics2D = [:]
        shapes2D = [:]
        shaders = [:]
        commands = []
        lines = [:]
        commandLines = [:]
        
        for t in timer {
            t.invalidate()
        }
        timer = []
        onDemandInstancers = [:]
        if releaseResources {
            resources = [:]
        }
        for sM in subMaps {
            sM.clear()
        }
        subMaps = []
        currentSampler = nil
    }
    
    /// Adds a subMap and copies all structs
    func addSubMap(_ subMap: Map)
    {
        for (key, val) in subMap.behavior { behavior[key] = val }
        for (key, val) in subMap.images { images[key] = val }
        for (key, val) in subMap.audio { audio[key] = val }
        for (key, val) in subMap.aliases { aliases[key] = val }
        for (key, val) in subMap.sequences { sequences[key] = val }
        for (key, val) in subMap.layers { layers[key] = val }
        for (key, val) in subMap.scenes { scenes[key] = val }
        for (key, val) in subMap.physics2D { physics2D[key] = val }
        for (key, val) in subMap.shapes2D { shapes2D[key] = val }
        for (key, val) in subMap.shaders { shaders[key] = val }
        for (key, val) in subMap.gridInstancers { gridInstancers[key] = val }
        for (key, val) in subMap.onDemandInstancers { onDemandInstancers[key] = val }
        commands += subMap.commands
        subMaps.append(subMap)
    }
    
    /// Returns a behavior linked in the map
    func getBehavior(_ name: String) -> MapBehavior? {
        if behavior[name] != nil { return behavior[name] }
        else {
            for sM in subMaps {
                if sM.behavior[name] != nil { return sM.behavior[name] }
            }
        }
        return nil
    }
    
    /// Setup  the aspect and view
    func setup(game: Game, forceFixedScale: Bool = false)
    {
        self.game = game
        self.texture = game.texture
        
        canvasSize = getCanvasSize()
        
        let scale: Float = min(texture.width / canvasSize.x, texture.height / canvasSize.y)
        let scaledWidth: Float
        let scaledHeight: Float
        
        if scaleMode == .UpDown && forceFixedScale == false {
            scaledWidth = canvasSize.x * scale
            scaledHeight = canvasSize.y * scale
        } else //if scaleMode == .Fixed
        {
            scaledWidth = canvasSize.x
            scaledHeight = canvasSize.y
        }

        viewBorder = Float2((texture.width - scaledWidth) / 2.0, (texture.height - scaledHeight) / 2.0)

        viewBorder.x = round(viewBorder.x)
        viewBorder.y = round(viewBorder.y)
        
        viewBorder.x = max(viewBorder.x, 0)
        viewBorder.y = max(viewBorder.y, 0)

        aspect = Float3(texture.width, texture.height, 0)
        aspect.x = (scaledWidth / 100.0)
        aspect.y = (scaledHeight / 100.0)
        aspect.z = min(aspect.x, aspect.y)

        game._Aspect.x = aspect.x
        game._Aspect.y = aspect.y
        
        currentSampler = game.linearSampler
        
        // Setup all Lua scripts referenced in Behavior trees
        
        for (_, b) in behavior {
            let asset = b.behaviorAsset
            
            if let behavior = asset.behavior {
                for p in behavior.variables {
                    if let lua = p.value as? Lua1 {
                        game.luaBuilder.compileIntoBehavior(context: behavior, variable: lua)
                    }
                }
            }
        }
    }
    
    /// Creates physics, textures etc
    func createDependencies(_ scene: MapScene)
    {
        // Contact Listener
        class contactListener : b2ContactListener {
        
            var map: Map
            
            init(_ map: Map)
            {
                self.map = map
            }
            
            func getShapeNameOfFixture(_ fixture: b2Fixture) -> String?
            {
                for (shapeName, shape) in map.shapes2D {
                    if let instances = shape.instances {
                        for inst in instances.pairs {
                            if let body = inst.0.body {
                                if body.m_fixtureList === fixture {
                                    return shapeName
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        if body.m_fixtureList === fixture {
                            return shapeName
                        }
                    }
                }
                
                return nil
            }
            
            func getShapeOfFixture(_ fixture: b2Fixture, _ cb: (inout MapShape2D) -> Void)
            {
                for (shapeName, shape) in map.shapes2D {
                    if let instances = shape.instances {
                        for (index, inst) in instances.pairs.enumerated() {
                            if let body = inst.0.body {
                                if body.m_fixtureList === fixture {
                                    cb(&map.shapes2D[shapeName]!.instances!.pairs[index].0)
                                }
                            }
                        }
                    } else
                    if let body = shape.body {
                        if body.m_fixtureList === fixture {
                            cb(&map.shapes2D[shapeName]!)
                        }
                    }
                }
            }
            
            func addContactsToEachOther(_ fixtureA: b2Fixture, _ fixtureB: b2Fixture)
            {
                if let shapeNameA = getShapeNameOfFixture(fixtureA) {
                    if let shapeNameB = getShapeNameOfFixture(fixtureB) {
                
                        getShapeOfFixture(fixtureA, { (shape) in
                            shape.contactList.append(shapeNameB)
                        })
                        
                        getShapeOfFixture(fixtureB, { (shape) in
                            shape.contactList.append(shapeNameA)
                        })
                    }
                }
            }
            
            func removeContactsFromEachOther(_ fixtureA: b2Fixture, _ fixtureB: b2Fixture)
            {
                if let shapeNameA = getShapeNameOfFixture(fixtureA) {
                    if let shapeNameB = getShapeNameOfFixture(fixtureB) {
                
                        getShapeOfFixture(fixtureA, { (shape) in
                            if let index = shape.contactList.firstIndex(of: shapeNameB) {
                                shape.contactList.remove(at: index)
                            }
                        })
                        
                        getShapeOfFixture(fixtureB, { (shape) in
                            if let index = shape.contactList.firstIndex(of: shapeNameA) {
                                shape.contactList.remove(at: index)
                            }
                        })
                    }
                }
            }
            
            func beginContact(_ contact : b2Contact) {
                //print("hit", getShapeNameOfFixture(contact.fixtureA), getShapeNameOfFixture(contact.fixtureB))
                addContactsToEachOther(contact.fixtureA, contact.fixtureB)
            }
            func endContact(_ contact: b2Contact) {
                //print("end", getShapeNameOfFixture(contact.fixtureA), getShapeNameOfFixture(contact.fixtureB))
                removeContactsFromEachOther(contact.fixtureA, contact.fixtureB)
            }
            func preSolve(_ contact: b2Contact, oldManifold: b2Manifold) {}
            func postSolve(_ contact: b2Contact, impulse: b2ContactImpulse) {}
       }
        
        // Create the Physics2D instances
        for (physicsName, physics) in physics2D {
            var gravity = b2Vec2(0.0, 10.0)
            if let gravityOption = physics.options["gravity"] as? Float2 {
                gravity.x = gravityOption.x
                gravity.y = gravityOption.y
            }
            physics2D[physicsName]!.world = b2World(gravity: gravity)
            physics2D[physicsName]!.world?.setContactListener(contactListener(self))
        }
        
        var categoryBits : UInt16 = 1
        
        // First pass for physic bodies, apply the category bits
        for cmd in commands {
            if cmd.command == "ApplyPhysics2D" {
                if let physicsName = cmd.options["physicsid"] as? String {
                    if physics2D[physicsName] != nil {
                        if let shapeName = cmd.options["shapeid"] as? String {
                            if let shape2D = shapes2D[shapeName] {
                                
                                if let instances = shape2D.instances {
                                    for (index, _) in instances.pairs.enumerated() {
                                        shape2D.instances!.pairs[index].0.categoryBits = categoryBits
                                    }
                                }
 
                                shapes2D[shapeName]?.categoryBits = categoryBits
                                categoryBits *= 2
                            }
                        }
                    }
                }
            }
        }
        
        // Second pass do all
        for cmd in commands {
            // Set a texture (any visual) to a shape
            if cmd.command == "ApplyTexture2D" {
                if let shapeName = cmd.options["shapeid"] as? String {
                    if let textureName = cmd.options["id"] as? String {
                        applyTextureToShape(shapeName, textureName)
                    }
                }
            } else
            // Parse the 2D shapes and add them to the right physics world
            if cmd.command == "ApplyPhysics2D" {
                if let physicsName = cmd.options["physicsid"] as? String {
                    if let physics2D = physics2D[physicsName] {
                        if let shapeName = cmd.options["shapeid"] as? String {
                            if let shape2D = shapes2D[shapeName] {
                                
                                shapes2D[shapeName]?.physicsWorld = physics2D
                                shapes2D[shapeName]?.physicsCmd = cmd

                                let maskBits = calculateMaskBits(cmd)
                                
                                if let instances = shape2D.instances {
                                    for (index, _) in instances.pairs.enumerated() {
                                        addShapeToPhysicsWorld(physics2D, shapeName, &shape2D.instances!.pairs[index].0, cmd, maskBits)
                                    }
                                } else {
                                    addShapeToPhysicsWorld(physics2D, shapeName, &shapes2D[shapeName]!, cmd, maskBits)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Parse layers for static tiles and add them to the physics worlds
        if let sceneLayers = scene.options["layers"] as? [String] {
            for l in sceneLayers {
                if let layer = layers[l] {
                    
                    let x : Float = 0
                    let y : Float = 0

                    var xPos = x + layer.options.offset.x * aspect.x
                    var yPos = y + layer.options.offset.y * aspect.y
                    
                    //xPos += layer.options.accumScroll.x
                    //yPos += layer.options.accumScroll.y
                    
                    var pX      : Float? = nil
                    var pY      : Float? = nil
                    var pWidth  : Float = 0
                    var pHeight : Float = 0
                    var pId     : String? = nil
                    
                    func checkPhysicsBlock()
                    {
                        if let physicsId = pId, pX != nil, pY != nil {
                            let ppm = physics2D[physicsId]!.ppm
                            
                            //let width : Float = (advance.0 / aspect.x) / 2.0
                            //let height : Float = (advance.1 / aspect.y) / 2.0
                            
                            // Define the dynamic body. We set its position and call the body factory.
                            let bodyDef = b2BodyDef()
                            //bodyDef.angle = 0
                            bodyDef.type = b2BodyType.staticBody
                                    
                            let fixtureDef = b2FixtureDef()
                            fixtureDef.shape = nil

                            fixtureDef.filter.categoryBits = categoryBits
                            fixtureDef.filter.maskBits = 0xffff
                            
                            let polyShape = b2PolygonShape()
                            polyShape.setAsBox(halfWidth: pWidth / ppm - polyShape.m_radius, halfHeight: pHeight / 2.0 / ppm - polyShape.m_radius)
                            fixtureDef.shape = polyShape
                            
                            fixtureDef.friction = 0.1
                            fixtureDef.density = 0.0
                            bodyDef.position.set((pX! / aspect.x + pWidth) / ppm, (pY! / aspect.y + pHeight / 2.0) / ppm)
                            
                            //print((xPos / aspect.x + width), (yPos / aspect.y + height), width, height)

                            let body = physics2D[physicsId]!.world!.createBody(bodyDef)
                            body.createFixture(fixtureDef)
                        }
                        pX = nil; pY = nil; pId = nil
                    }

                    for line in layer.data {
                        
                        pX = nil; pY = nil
                        
                        for var a in line.line {
                            let advance = drawAlias(xPos, yPos, &a, doDraw: false)
                            // --- Add Block
                            if let physicsId = a.options.physicsId, physics2D[physicsId] != nil {
                                
                                let width : Float = (advance.0 / aspect.x) / 2.0
                                let height : Float = (advance.1 / aspect.y) / 2.0
                                
                                if pX == nil {
                                    pX = xPos
                                    pY = yPos
                                    pWidth = width
                                    pHeight = height
                                    pId = physicsId
                                } else {
                                    pWidth += width
                                    //pHeight += height
                                }
                            }
                            else {
                                checkPhysicsBlock()
                            }
                            // ---
                            xPos += advance.0
                        }
                     
                        checkPhysicsBlock()

                        yPos += layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0
                        xPos = x + layer.options.offset.x * aspect.x
                    }
                    
                    //layer.options.accumScroll.x += layer.options.scroll.x * aspect.x
                    //layer.options.accumScroll.y += layer.options.scroll.y * aspect.y
                }
            }
        }
        
        // Preload all audio
        game.clearLocalAudio()
        for (id, mapAudio) in audio {
            do {
                if let asset = game.assetFolder.getAssetById(UUID(uuidString: mapAudio.resourceName)!, .Audio) {
                    let player = try AVAudioPlayer(data: asset.data[0])
                    if mapAudio.isLocal {
                        game.localAudioPlayers[id] = player
                    } else {
                        if game.globalAudioPlayers[id] == nil {
                            game.globalAudioPlayers[id] = player
                        }
                    }
                    player.numberOfLoops = mapAudio.loops
                    player.prepareToPlay()
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    // Calculates the mask bits for the command
    func calculateMaskBits(_ cmd: MapCommand) -> UInt16
    {
        var mask : UInt16 = 0xffff
        
        if let collisionids = cmd.options["collisionids"] as? [String] {
            var maskBits : UInt16 = 0
            
            for id in collisionids {
                if shapes2D[id] != nil {
                    maskBits |= shapes2D[id]!.categoryBits
                }
            }
            
            mask = maskBits
        }
        
        return mask
    }

    // Adds the given shape to the physics world
    func addShapeToPhysicsWorld(_ physics2D: MapPhysics2D,_ shapeName: String,_ shape2D: inout MapShape2D,_ cmd: MapCommand, _ maskBits: UInt16)
    {
        let ppm = physics2D.ppm
        
        // Define the dynamic body. We set its position and call the body factory.
        let bodyDef = b2BodyDef()
        bodyDef.angle = shape2D.options.rotation.x.degreesToRadians
        bodyDef.type = b2BodyType.staticBody
                
        let fixtureDef = b2FixtureDef()
        fixtureDef.shape = nil

        fixtureDef.filter.categoryBits = shape2D.categoryBits
        fixtureDef.filter.maskBits = maskBits
            
        if var type = shape2D.originalOptions["type"] as? String {
            type = type.lowercased()
            if type == "disk" {
                let circleShape = b2CircleShape()
                circleShape.radius = shape2D.options.radius.x / ppm - circleShape.m_radius
                fixtureDef.shape = circleShape
            }
        }
        
        if fixtureDef.shape == nil {
            let polyShape = b2PolygonShape()
            
            polyShape.setAsBox(halfWidth: (shape2D.options.size.x / 2.0) / ppm - polyShape.m_radius, halfHeight: (shape2D.options.size.y / 2.0) / ppm - polyShape.m_radius)
            fixtureDef.shape = polyShape
        }
        
        if let fixedRotation = cmd.options["fixedrotation"] as? Bool1 {
            //shape2D.body?.setFixedRotation(fixedRotation.x)
            //shape2D.body?.
            //bodyDef.angularDamping = 0
            //bodyDef.angularVelocity = 0
            bodyDef.fixedRotation = fixedRotation.x
        }
        
        if let body = cmd.options["body"] as? String {
            if body.lowercased() == "dynamic" {
                bodyDef.type = b2BodyType.dynamicBody
                fixtureDef.density = 1.0
                fixtureDef.restitution = 0.0
            }
        }
                
        if let bullet = cmd.options["bullet"] as? Bool1 {
            bodyDef.bullet = bullet.x
        }
        
        if let restitution = cmd.options["restitution"] as? Float1 {
            fixtureDef.restitution = restitution.x
        } else {
            fixtureDef.restitution = 0.0
        }
        
        if let friction = cmd.options["friction"] as? Float1 {
            fixtureDef.friction = friction.x
        } else {
            fixtureDef.friction = 0.3
        }
        if let density = cmd.options["density"] as? Float1 {
            fixtureDef.density = density.x
            if density.x == 0 {
                bodyDef.type = b2BodyType.staticBody
            }
        } else {
            fixtureDef.density = 0.0
        }
        
        if let groupIndex = cmd.options["groupindex"] as? Int1 {
            fixtureDef.filter.groupIndex = Int16(groupIndex.x)
        }
        
        bodyDef.position.set((shape2D.options.position.x + shape2D.options.size.x / 2.0) / ppm, (shape2D.options.position.y + shape2D.options.size.y / 2.0) / ppm)
        
        shape2D.body = physics2D.world!.createBody(bodyDef)
        shape2D.body!.createFixture(fixtureDef)
    }
    
    // Applies a texture id to a given shape id
    @discardableResult func applyTextureToShape(_ shapeId: String,_ id: String, flipX: Bool1? = nil) -> Bool
    {
        if shapes2D[shapeId] != nil {
            if images[id] != nil {
                
                shapes2D[shapeId]!.texture = nil

                shapes2D[shapeId]!.texture = images[id]
                if flipX != nil {
                    shapes2D[shapeId]!.options.flipX = flipX!
                }
                                
                // If size is 0, apply texture size
                if shapes2D[shapeId]!.options.size.x == 0 {
                    if let image = images[id] {
                        if let texture2D = getImageResource(image.resourceName) {
                            shapes2D[shapeId]!.options.size.x = texture2D.width / canvasSize.x * 100.0
                            shapes2D[shapeId]!.options.size.y = texture2D.height / canvasSize.y * 100.0
                        }
                    }
                }
                
                return true
            } else
            if aliases[id] != nil {
                shapes2D[shapeId]!.aliasId = id
            } else
            if var sequence = sequences[id] {
                var index : Int = 0
                var lastTime : Double = 0
                if shapes2D[shapeId]!.texture != nil && shapes2D[shapeId]!.texture as? MapSequence != nil {
                    index = (shapes2D[shapeId]!.texture as? MapSequence)!.data!.animIndex
                    lastTime = (shapes2D[shapeId]!.texture as? MapSequence)!.data!.lastTime
                }
                sequence.data = MapSequenceData2D()
                sequence.data?.animIndex = index
                sequence.data?.lastTime = lastTime
                shapes2D[shapeId]!.texture = sequence
                if flipX != nil {
                    shapes2D[shapeId]!.options.flipX = flipX!
                }

                if shapes2D[shapeId]!.options.size.x == 0 && sequences[id]!.resourceNames.count > 0 {
                    if let texture2D = getImageResource(sequence.resourceNames[0]) {
                        shapes2D[shapeId]!.options.size.x = texture2D.width / canvasSize.x * 100.0
                        shapes2D[shapeId]!.options.size.y = texture2D.height / canvasSize.y * 100.0
                    }
                }
                
                return true
            }
        }
        return false
    }
    
    // Creates an instance of an OnDemandInstance2D object
    @discardableResult func createOnDemandInstance(_ instancerId: String,_ position: Float2) -> Bool
    {
        if let instancer = onDemandInstancers[instancerId] {
            let instanceAsset = Asset(type: .Behavior, name: instancer.behaviorName)
            instanceAsset.value = behavior[instancer.behaviorName]!.behaviorAsset.value
            
            var variableName = instancer.variableName
            variableName += String(Int.random(in: 0...99999999))
                
            var error = CompileError()
            game.behaviorBuilder.compile(instanceAsset)
            game.mapBuilder.createShape2D(map: self, variable: variableName, options: shapes2D[instancer.shapeName]!.originalOptions, error: &error, instBehaviorName: instancer.behaviorName, instAsset: instanceAsset)
            
            if error.error == nil {
                var mapBehavior = MapBehavior(behaviorAsset: instanceAsset, name: variableName, options: [:])
                var mapShape2D = shapes2D[variableName]!
                
                if let behavior = mapBehavior.behaviorAsset.behavior {
                    for p in behavior.variables {
                        if let lua = p.value as? Lua1 {
                            game.luaBuilder.compileIntoBehavior(context: behavior, variable: lua)
                        }
                    }
                }
                
                if let pos = mapBehavior.behaviorAsset.behavior?.getVariableValue("position") as? Float2 {
                    pos.x = position.x
                    pos.y = position.y                    
                }
                
                // In case the shape has zero size by default copy the base shape size
                mapShape2D.options.size.x = shapes2D[instancer.shapeName]!.options.size.x
                mapShape2D.options.size.y = shapes2D[instancer.shapeName]!.options.size.y
                
                mapShape2D.categoryBits = shapes2D[instancer.shapeName]!.categoryBits
                
                if shapes2D[instancer.shapeName]!.physicsWorld != nil {
                    let maskBits = calculateMaskBits(shapes2D[instancer.shapeName]!.physicsCmd!)

                    addShapeToPhysicsWorld(shapes2D[instancer.shapeName]!.physicsWorld!, variableName, &mapShape2D, shapes2D[instancer.shapeName]!.physicsCmd!, maskBits)
                }

                instanceAsset.behavior!.execute(name: "init")
                instancer.addPair(shape: &mapShape2D, behavior: &mapBehavior)
                                
                return true
            }
        }
        return false
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
    
    func drawShape(_ shape: MapShape2D, layer: MapLayer? = nil)
    {
        if let instances = shape.instances {
            for s in instances.pairs {
                let instShape = s.0
                                
                if instShape.options.visible.toSIMD() == false { continue }
                
                if let aliasId = instShape.aliasId {
                    if let layer = layer, layer.options.gridBased {
                        let posX = instShape.options.position.x * (layer.options.gridSize.x / canvasSize.x * aspect.x * 100.0)
                        let posY = instShape.options.position.y * (layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0)
                        drawAlias(posX, posY, &aliases[aliasId]!)
                    } else {
                        drawAlias(instShape.options.position.x, instShape.options.position.y, &aliases[aliasId]!)
                    }
                } else
                if instShape.shape == .Disk {
                    drawDisk(instShape.options, shape.texture)
                } else
                if instShape.shape == .Box {
                    drawBox(instShape.options, shape.texture)
                } else
                if instShape.shape == .Text {
                    drawText(instShape.options)
                }
            }
        } else {
            if shape.options.visible.toSIMD() == false { return }
            
            if let aliasId = shape.aliasId {
                if let layer = layer, layer.options.gridBased {
                    let posX = shape.options.position.x * (layer.options.gridSize.x / canvasSize.x * aspect.x * 100.0)
                    let posY = shape.options.position.y * (layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0)
                    drawAlias(posX, posY, &aliases[aliasId]!)
                } else {
                    drawAlias(shape.options.position.x, shape.options.position.y, &aliases[aliasId]!)
                }
            } else
            if shape.shape == .Disk {
                drawDisk(shape.options, shape.texture)
            } else
            if shape.shape == .Box {
                drawBox(shape.options, shape.texture)
            } else
            if shape.shape == .Text {
                drawText(shape.options)
            }
        }
    }

    @discardableResult func drawAlias(_ x: Float,_ y: Float,_ alias: inout MapAlias, doDraw: Bool = true) -> (Float, Float)
    {
        var rc     : (Float, Float) = (0,0)
                
        if alias.options.isEmpty && alias.options.rect != nil {
            return (alias.options.rect!.z / canvasSize.x * aspect.x * 100.0, alias.options.rect!.w / canvasSize.y * aspect.y * 100.0)
        }

        if alias.options.texture == nil {
            if alias.type == .Image {
                if let image = images[alias.pointsTo] {
                    if let texture2D = getImageResource(image.resourceName) {
                        alias.options.texture = texture2D
                    }
                }
            }
        }
        
        if let texture2D = alias.options.texture {
            
            var width = texture2D.width / canvasSize.x * aspect.x * 100.0
            var height = texture2D.height / canvasSize.y * aspect.y * 100.0
            
            alias.options.position.x = x + (alias.options.offset.x) * layerPreviewZoom
            alias.options.position.y = y + (alias.options.offset.y / canvasSize.y * aspect.y * 100.0) * layerPreviewZoom
                        
            // Subrect ?
            if let v = alias.options.rect {
                width = v.z / canvasSize.x * aspect.x * 100.0
                height = v.w / canvasSize.y * aspect.y * 100.0
            }
            
            if alias.options.scale == .Full {
                width = texture!.width - viewBorder.x * 2.0
                height = texture!.height - viewBorder.y * 2.0
            }
            
            alias.options.width.x = width + 0.1
            alias.options.height.x = height + 0.1
            
            if doDraw {
                drawTexture(alias.options)
            }
            
            if alias.options.repeatX == true {
                var posX : Float = x + width
                while posX + camera2D.xOffset < game!.texture!.width {
                    alias.options.position.x = posX
                    if doDraw {
                        drawTexture(alias.options)
                    }
                    posX += width
                }
            }
        
            rc.0 = width
            rc.1 = height
        }
        
        return rc
    }
    
    func drawLayer(_ x: Float,_ y: Float,_ layer: MapLayer)
    {
        if layer.options.clipToCanvas && game.state == .Running {
            game.gameScissorRect = MTLScissorRect(x: Int(viewBorder.x), y: Int(viewBorder.y), width: Int(texture!.width - 2.0 * viewBorder.x), height: Int(texture!.height - 2.0 * viewBorder.y))
        }
        
        if layer.options.filter == .Nearest {
            currentSampler = game.nearestSampler
        }
        
        if game.state == .Running {
            layerPreviewZoom = 1
        } else {
            layerPreviewZoom = camera2D.zoom
        }
        
        var xPos = x + layer.options.offset.x * aspect.x
        var yPos = y + layer.options.offset.y * aspect.y
        
        if let shs = layer.originalOptions["shaders"] as? [String] {
            for shaderName in shs {
                if let sh = shaders[shaderName] {
                    if let shader = sh.shader {
                        if sh.canvasArea == false {
                            drawShader(shader, MMRect(0,0,texture.width, texture.height))
                        } else {
                            drawShader(shader, MMRect(viewBorder.x, viewBorder.y, texture.width  - viewBorder.x * 2.0, texture.height - viewBorder.y * 2.0))
                        }
                    }
                }
            }
        }
        
        if let shapes = layer.originalOptions["shapes"] as? [String] {
            for shape in shapes {
                if let sh = shapes2D[shape] {
                    drawShape(sh, layer: layer)
                }
            }
        }
        
        xPos += layer.options.accumScroll.x
        yPos += layer.options.accumScroll.y

        for line in layer.data {
            
            for var a in line.line {
                let advance = drawAlias(xPos, yPos, &a)
                xPos += advance.0 * layerPreviewZoom
            }
            yPos += (layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0) * layerPreviewZoom
            xPos = x + layer.options.offset.x * aspect.x
        }
        
        layer.options.accumScroll.x += layer.options.scroll.x * aspect.x
        layer.options.accumScroll.y += layer.options.scroll.y * aspect.y
        
        currentSampler = game.linearSampler

        if layer.options.clipToCanvas && game.state == .Running {
            game.gameScissorRect = MTLScissorRect(x: 0, y: 0, width: texture!.texture.width, height: texture!.texture.height)
        }
    }
    
    /// If this map has a grid based layer return the pixel dimensions and the amount of tiles
    func getGridSize() -> (float2, Int, Int)? {
        for (_, layer) in layers {
            
            if layer.options.gridCoords == true {
                return (getLayerGridSize(layer), layer.maxWidth, layer.maxHeight)
            }
        }
        
        return nil
    }
    
    // Get the world grid size
    func getLayerGridSize(_ layer: MapLayer) -> float2 {
        let layerWidth = layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0 + layer.options.offset.x * aspect.x
        let layerHeight = layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0
        return float2(layerWidth, layerHeight)
    }
    
    /// Get the screen coordinate offset into the layer based on the cursor position
    func getLayerOffset(_ cursorXOff: Int32,_ cursorYOff: Int32,_ layer: MapLayer) -> (Float, Float)?
    {
        layerPreviewZoom = camera2D.zoom

        var xPos : Float = 0
        var yPos : Float = 0

        var currentY : Int32 = 1
        for line in layer.data {
            
            if currentY == cursorYOff {
                var currentX : Int32 = 0
                let cOff = cursorXOff / 2 - 1
                
                for var a in line.line {
                    
                    if currentX < cOff {
                        let advance = drawAlias(xPos, yPos, &a, doDraw: false)
                        xPos += advance.0 * layerPreviewZoom
                    } else {
                        return (xPos, yPos)
                    }
                    
                    currentX += 1
                }
                return (xPos, yPos)
            } else {
                yPos += (layer.options.gridSize.x / canvasSize.y * aspect.y * 100.0) * layerPreviewZoom
                xPos = 0
            }
            
            currentY += 1
        }
        return nil
    }
    
    func drawScene(_ x: Float,_ y: Float,_ scene: MapScene)
    {
        texture.clear(scene.backColor)
        
        startEncoding()
        
        for (_, physics2D) in physics2D {
        
            let timeStep: b2Float = 1.0 / 60.0
            let velocityIterations = 6
            let positionIterations = 2
        
            if let world = physics2D.world {
                world.step(timeStep: timeStep, velocityIterations: velocityIterations, positionIterations: positionIterations)
            }
            
            let ppm = physics2D.ppm

            for (shapeName, shape2D) in shapes2D {
                if let instances = shape2D.instances {
                    for (index, inst) in instances.pairs.enumerated() {
                        if let body = inst.0.body {
                            shapes2D[shapeName]!.instances!.pairs[index].0.options.position.x = body.position.x * ppm - shapes2D[shapeName]!.instances!.pairs[index].0.options.size.x / 2.0
                            shapes2D[shapeName]!.instances!.pairs[index].0.options.position.y = body.position.y * ppm - shapes2D[shapeName]!.instances!.pairs[index].0.options.size.y / 2.0
                            shapes2D[shapeName]!.instances!.pairs[index].0.options.rotation.x = body.angle.radiansToDegrees
                        }
                    }
                } else {
                    if let body = shape2D.body {
                        shape2D.options.position.x = body.position.x * ppm - shape2D.options.size.x / 2.0
                        shape2D.options.position.y = body.position.y * ppm - shape2D.options.size.y / 2.0
                        shape2D.options.rotation.x = body.angle.radiansToDegrees
                    }
                }
            }
        }
        
        if let sceneLayers = scene.options["layers"] as? [String] {
            for l in sceneLayers {
                if let layer = layers[l] {
                    drawLayer(x, y, layer)
                }
            }
        }
        
        stopEncoding()
    }
    
    func getCanvasSize() -> Float2 {
        var size = Float2(texture.width, texture.height)
        
        scaleMode = .UpDown

        var name = "Desktop"
        #if os(iOS)
        name = "Mobile"
        #elseif os(tvOS)
        name = "TV"
        #endif
        
        for s in commands {
            if s.command == "CanvasSize" {
                if let platform = s.options["platform"] as? String {
                    if platform == name || platform.lowercased() == "any" {
                        if let i = s.options["size"] as? Float2 {
                            size = i
                        }
                    }
                }
                if let s = s.options["scale"] as? String {
                    let scale = s.lowercased()
                    if scale == "fixed" {
                        scaleMode = .Fixed
                    }
                }
            }
        }

        return size
    }
    
    /// Returns the texture associated for a given shape, if necessary handles animation etc.
    func getTextureForShape(_ texture2D: Any?) -> Texture2D?
    {
        if let image = texture2D as? MapImage {
            if let texture = getImageResource(image.resourceName) {
                return texture
            }
        } else
        if let sequence = texture2D as? MapSequence {
            let sequenceData = sequence.data!
            let currentTime = NSDate().timeIntervalSince1970

            if sequenceData.lastTime > 0 {
                if currentTime - sequenceData.lastTime > sequence.interval {
                    sequenceData.animIndex += 1
                    sequenceData.lastTime = currentTime
                }
            } else {
                sequenceData.lastTime = currentTime
            }
            
            if sequenceData.animIndex >= sequence.resourceNames.count {
                sequenceData.animIndex = 0
            }
                                            
            if let texture = getImageResource(sequence.resourceNames[sequenceData.animIndex]) {
                return texture
            }
        }
        return nil
    }
    
    /// Draw a Disk
    func drawDisk(_ options: MapShapeData2D,_ texture2D: Any? = nil)
    {
        var position : SIMD2<Float> = float2(options.position.x * aspect.x, options.position.y * aspect.y)
        let radius : Float = options.radius.x * aspect.z
        let border : Float = options.border.x * aspect.z
        let onion : Float = options.onion.x * aspect.z
        let fillColor : SIMD4<Float> = options.color.toSIMD()
        let borderColor : SIMD4<Float> = options.borderColor.toSIMD()
        let rotation : Float = options.rotation.x

        position.x += viewBorder.x + camera2D.xOffset
        position.y += viewBorder.y + camera2D.yOffset

        position.x /= game.scaleFactor
        position.y /= game.scaleFactor
        
        var data = DiscUniform()
        data.borderSize = border / game.scaleFactor
        data.radius = radius / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        data.onion = onion / game.scaleFactor
        data.rotation = rotation.degreesToRadians

        let rect = MMRect(position.x - data.borderSize / 2, position.y - data.borderSize / 2, data.radius * 2 + data.borderSize * 2, data.radius * 2 + data.borderSize * 2, scale: game.scaleFactor )
        let vertexData = game.createVertexData(texture: texture, rect: rect)
        
        renderEncoder.setScissorRect(game.gameScissorRect!)

        data.hasTexture = 0
        if texture2D != nil {
            if let texture = getTextureForShape(texture2D) {
                data.hasTexture = 1
                data.textureSize = float2(texture.width, texture.height);
                renderEncoder.setFragmentTexture(texture.texture, index: 1)
            }
        }
                
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
        
        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<DiscUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawDisc))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /// Draw a Box
    func drawBox(_ options: MapShapeData2D,_ texture2D: Any? = nil)
    {
        var position : SIMD2<Float> = float2(options.position.x * aspect.x, options.position.y * aspect.y)
        let size : SIMD2<Float> = float2(options.size.x * aspect.x, options.size.y * aspect.y)
        let round : Float = options.round.x * aspect.z
        let border : Float = options.border.x * aspect.z
        let rotation : Float = options.rotation.x
        let onion : Float = options.onion.x * aspect.z
        let fillColor : SIMD4<Float> = options.color.toSIMD()
        let borderColor : SIMD4<Float> = options.borderColor.toSIMD()
        
        position.x += viewBorder.x + camera2D.xOffset
        position.y += viewBorder.y + camera2D.yOffset
        
        position.x /= game.scaleFactor
        position.y /= game.scaleFactor

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(size.x / game.scaleFactor, size.y / game.scaleFactor)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        data.mirrorX = options.flipX.x == true ? 1 : 0

        renderEncoder.setScissorRect(game.gameScissorRect!)

        data.hasTexture = 0
        if texture2D != nil {
            if let texture = getTextureForShape(texture2D) {
                data.hasTexture = 1
                data.textureSize = float2(texture.width, texture.height);
                renderEncoder.setFragmentTexture(texture.texture, index: 1)
            }
        }
        
        if rotation == 0 {
            let rect = MMRect(position.x, position.y, data.size.x, data.size.y, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBox))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        } else {
            data.pos.x = position.x
            data.pos.y = position.y
            data.rotation = rotation.degreesToRadians
            data.screenSize = float2(texture.width / game.scaleFactor, texture.height / game.scaleFactor)

            let rect = MMRect(0, 0, texture.width / game.scaleFactor, texture.height / game.scaleFactor, scale: game.scaleFactor)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
            
            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBoxExt))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }
    
    /// Draw a Box
    func drawDebugBox(_ options: MapShapeData2D)
    {
        var position : SIMD2<Float> = float2(options.position.x, options.position.y)
        let size : SIMD2<Float> = float2(options.size.x, options.size.y)
        let round : Float = options.round.x * aspect.z
        let border : Float = options.border.x * aspect.z
        let onion : Float = options.onion.x * aspect.z
        let fillColor : SIMD4<Float> = options.color.toSIMD()
        let borderColor : SIMD4<Float> = options.borderColor.toSIMD()
        
        position.x += camera2D.xOffset
        position.y += camera2D.yOffset

        var data = BoxUniform()
        data.onion = onion / game.scaleFactor
        data.size = float2(size.x, size.y)
        data.round = round / game.scaleFactor
        data.borderSize = border / game.scaleFactor
        data.fillColor = fillColor
        data.borderColor = borderColor
        
        data.mirrorX = options.flipX.x == true ? 1 : 0

        renderEncoder.setScissorRect(game.gameScissorRect!)

        data.hasTexture = 0

        let rect = MMRect(position.x, position.y, data.size.x, data.size.y, scale: 1)
        let vertexData = game.createVertexData(texture: texture, rect: rect)
        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        renderEncoder.setFragmentBytes(&data, length: MemoryLayout<BoxUniform>.stride, index: 0)
        renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawBox))
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    /// Draws the given text
    func drawText(_ options: MapShapeData2D)
    {
        var position : SIMD2<Float> = float2(options.position.x * aspect.x, options.position.y * aspect.y)
        let size : Float = options.text.fontSize * aspect.z
        let font : Font? = options.text.font
        var text : String = ""
        let color : SIMD4<Float> = options.color.toSIMD()

        position.x += viewBorder.x + camera2D.xOffset
        position.y += viewBorder.y + camera2D.yOffset
        
        if let t = options.text.text {
            text = t
        } else
        if let f1 = options.text.f1 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f1.x)
            } else {
                text = String(f1.x)
            }
        } else
        if let i1 = options.text.i1 {
            if let digits = options.text.digits {
                text = String(format: "%0\(digits.x)d", i1.x)
            } else {
                text = String(i1.x)
            }
        } else
        if let f2 = options.text.f2 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f2.x) + " " + String(format: "%.0\(digits.x)f", f2.y)
            } else {
                text = String(f2.x) + " " + String(f2.y)
            }
        } else
        if let f3 = options.text.f3 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f3.x) + " " + String(format: "%.0\(digits.x)f", f3.y) + " " + String(format: "%.0\(digits.x)f", f3.z)
            } else {
                text = String(f3.x) + " " + String(f3.y) + " " + String(f3.z)
            }
        } else
        if let f4 = options.text.f4 {
            if let digits = options.text.digits {
                text = String(format: "%.0\(digits.x)f", f4.x) + " " + String(format: "%.0\(digits.x)f", f4.y) + " " + String(format: "%.0\(digits.x)f", f4.z) + " " + String(format: "%.0\(digits.x)f", f4.w)
            } else {
                text = String(f4.x) + " " + String(f4.y) + " " + String(f4.z) + " " + String(f4.w)
            }
        }

        //position.y = -position.y;
        let scaleFactor : Float = game.scaleFactor
        
        func drawChar(char: BMChar, x: Float, y: Float, adjScale: Float)
        {
            var data = TextUniform()
            
            data.atlasSize.x = Float(font!.atlas!.width) * scaleFactor
            data.atlasSize.y = Float(font!.atlas!.height) * scaleFactor
            data.fontPos.x = char.x * scaleFactor
            data.fontPos.y = char.y * scaleFactor
            data.fontSize.x = char.width * scaleFactor
            data.fontSize.y = char.height * scaleFactor
            data.color = color

            let rect = MMRect(x, y, char.width * adjScale, char.height * adjScale, scale: scaleFactor)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
            
            renderEncoder.setScissorRect(game.gameScissorRect!)

            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(font!.atlas, index: 1)

            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: .DrawTextChar))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        
        if let font = font {
         
            let scale : Float = (1.0 / font.bmFont!.common.lineHeight) * size
            let adjScale : Float = scale// / 2
            
            var posX = position.x / game.scaleFactor
            let posY = position.y / game.scaleFactor

            for c in text {
                let bmChar = font.getItemForChar( c )
                if bmChar != nil {
                    drawChar(char: bmChar!, x: posX + bmChar!.xoffset * adjScale, y: posY + bmChar!.yoffset * adjScale, adjScale: adjScale)
                    posX += bmChar!.xadvance * adjScale;
                }
            }
        }
    }
    
    /// Draws the given shader
    func drawShader(_ shader: Shader, _ rect: MMRect)
    {
        let vertexData = game.createVertexData(texture: texture, rect: rect)
        
        renderEncoder.setScissorRect(game.gameScissorRect!)

        renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
        renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)

        var behaviorData = BehaviorData()
        
        if shader.hasBindings {            
            for (_, binding) in shader.intVar {
                if let value = binding.1 as? Int1 {
                    if binding.0 == 0 { behaviorData.intData.0 = Int32(value.x) }
                    else if binding.0 == 1 { behaviorData.intData.1 = Int32(value.x) }
                    else if binding.0 == 2 { behaviorData.intData.2 = Int32(value.x) }
                    else if binding.0 == 3 { behaviorData.intData.3 = Int32(value.x) }
                    else if binding.0 == 4 { behaviorData.intData.4 = Int32(value.x) }
                    else if binding.0 == 5 { behaviorData.intData.5 = Int32(value.x) }
                    else if binding.0 == 6 { behaviorData.intData.6 = Int32(value.x) }
                    else if binding.0 == 7 { behaviorData.intData.7 = Int32(value.x) }
                    else if binding.0 == 8 { behaviorData.intData.8 = Int32(value.x) }
                    else if binding.0 == 9 { behaviorData.intData.9 = Int32(value.x) }
                }
            }
            for (_, binding) in shader.floatVar {
                if let value = binding.1 as? Float1 {
                    if binding.0 == 0 { behaviorData.floatData.0 = value.x }
                    else if binding.0 == 1 { behaviorData.floatData.1 = value.x }
                    else if binding.0 == 2 { behaviorData.floatData.2 = value.x }
                    else if binding.0 == 3 { behaviorData.floatData.3 = value.x }
                    else if binding.0 == 4 { behaviorData.floatData.4 = value.x }
                    else if binding.0 == 5 { behaviorData.floatData.5 = value.x }
                    else if binding.0 == 6 { behaviorData.floatData.6 = value.x }
                    else if binding.0 == 7 { behaviorData.floatData.7 = value.x }
                    else if binding.0 == 8 { behaviorData.floatData.8 = value.x }
                    else if binding.0 == 9 { behaviorData.floatData.9 = value.x }
                }
            }
            for (_, binding) in shader.float2Var {
                if let value = binding.1 as? Float2 {
                    if binding.0 == 0 { behaviorData.float2Data.0 = value.toSIMD() }
                    else if binding.0 == 1 { behaviorData.float2Data.1 = value.toSIMD() }
                    else if binding.0 == 2 { behaviorData.float2Data.2 = value.toSIMD() }
                    else if binding.0 == 3 { behaviorData.float2Data.3 = value.toSIMD() }
                    else if binding.0 == 4 { behaviorData.float2Data.4 = value.toSIMD() }
                    else if binding.0 == 5 { behaviorData.float2Data.5 = value.toSIMD() }
                    else if binding.0 == 6 { behaviorData.float2Data.6 = value.toSIMD() }
                    else if binding.0 == 7 { behaviorData.float2Data.7 = value.toSIMD() }
                    else if binding.0 == 8 { behaviorData.float2Data.8 = value.toSIMD() }
                    else if binding.0 == 9 { behaviorData.float2Data.9 = value.toSIMD() }
                }
            }
            for (_, binding) in shader.float3Var {
                if let value = binding.1 as? Float3 {
                    if binding.0 == 0 { behaviorData.float3Data.0 = value.toSIMD() }
                    else if binding.0 == 1 { behaviorData.float3Data.1 = value.toSIMD() }
                    else if binding.0 == 2 { behaviorData.float3Data.2 = value.toSIMD() }
                    else if binding.0 == 3 { behaviorData.float3Data.3 = value.toSIMD() }
                    else if binding.0 == 4 { behaviorData.float3Data.4 = value.toSIMD() }
                    else if binding.0 == 5 { behaviorData.float3Data.5 = value.toSIMD() }
                    else if binding.0 == 6 { behaviorData.float3Data.6 = value.toSIMD() }
                    else if binding.0 == 7 { behaviorData.float3Data.7 = value.toSIMD() }
                    else if binding.0 == 8 { behaviorData.float3Data.8 = value.toSIMD() }
                    else if binding.0 == 9 { behaviorData.float3Data.9 = value.toSIMD() }
                }
            }
            for (_, binding) in shader.float4Var {
                if let value = binding.1 as? Float4 {
                    if binding.0 == 0 { behaviorData.float4Data.0 = value.toSIMD() }
                    else if binding.0 == 1 { behaviorData.float4Data.1 = value.toSIMD() }
                    else if binding.0 == 2 { behaviorData.float4Data.2 = value.toSIMD() }
                    else if binding.0 == 3 { behaviorData.float4Data.3 = value.toSIMD() }
                    else if binding.0 == 4 { behaviorData.float4Data.4 = value.toSIMD() }
                    else if binding.0 == 5 { behaviorData.float4Data.5 = value.toSIMD() }
                    else if binding.0 == 6 { behaviorData.float4Data.6 = value.toSIMD() }
                    else if binding.0 == 7 { behaviorData.float4Data.7 = value.toSIMD() }
                    else if binding.0 == 8 { behaviorData.float4Data.8 = value.toSIMD() }
                    else if binding.0 == 9 { behaviorData.float4Data.9 = value.toSIMD() }
                }
            }
        }
        
        renderEncoder.setFragmentBytes(&behaviorData, length: MemoryLayout<BehaviorData>.stride, index: 0)

        renderEncoder.setRenderPipelineState(shader.pipelineState)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    func drawTexture(_ options: MapAliasData2D)
    {
        if let sourceTexture = options.texture {
            
            var position : SIMD2<Float> = options.position.toSIMD()
            var width : Float = options.width.toSIMD()
            var height : Float = options.height.toSIMD()
            let alpha : Float = 1
            
            let subRect : Float4? = options.rect
            
            position.x += viewBorder.x + camera2D.xOffset
            position.y += viewBorder.y + camera2D.yOffset
            
            width *= camera2D.zoom
            height *= camera2D.zoom
            
            // Check if texture will be visible
            if position.x > texture!.width || position.y > texture!.height || position.x + width < 0 || position.y + height < 0 {
                return
            }
            
            var data = TextureUniform()
            data.globalAlpha = alpha

            if let subRect = subRect {
                data.pos.x = subRect.x / sourceTexture.width
                data.pos.y = subRect.y / sourceTexture.height
                data.size.x = subRect.z / sourceTexture.width
                data.size.y = subRect.w / sourceTexture.height
            } else {
                data.pos.x = 0
                data.pos.y = 0
                data.size.x = 1
                data.size.y = 1
            }
            
            let rect = MMRect(position.x, position.y, width, height, scale: 1)
            let vertexData = game.createVertexData(texture: texture, rect: rect)
            
            renderEncoder.setScissorRect(game.gameScissorRect!)

            renderEncoder.setVertexBytes(vertexData, length: vertexData.count * MemoryLayout<Float>.stride, index: 0)
            renderEncoder.setVertexBytes(&game.viewportSize, length: MemoryLayout<vector_uint2>.stride, index: 1)
            
            renderEncoder.setFragmentBytes(&data, length: MemoryLayout<TextureUniform>.stride, index: 0)
            renderEncoder.setFragmentTexture(sourceTexture.texture, index: 1)
            
            renderEncoder.setFragmentSamplerState(currentSampler, index: 2)

            renderEncoder.setRenderPipelineState(game.metalStates.getState(state: textureState))
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
    }
    
    func reverseCoordinates(_ x: Float,_ y: Float) -> SIMD2<Int>
    {
        var rc = float2(x,y)
        
        rc.x -= camera2D.xOffset
        rc.y -= camera2D.yOffset
        
        rc.x -= lastPreviewOffset.x
        rc.y -= lastPreviewOffset.y
        
        rc.x = round(rc.x / camera2D.zoom)
        rc.y = round(rc.y / camera2D.zoom)
        
        return SIMD2<Int>(Int(rc.x), Int(rc.y))
    }
    
    /// Starts encoding for this scene
    func startEncoding() {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        
        renderEncoder = game.gameCmdBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
    }
    
    /// Stops encoding for this scene
    func stopEncoding() {
        renderEncoder.endEncoding()
        renderEncoder = nil
    }
}
