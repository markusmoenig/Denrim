//
//  Asset.swift
//  Metal-Z
//
//  Created by Markus Moenig on 26/8/20.
//

import MetalKit

class AssetGroup        : Codable, Equatable
{
    private enum CodingKeys: String, CodingKey {
        case id
        case name
    }
    
    var id              = UUID()
    var name            : String = ""
    
    init(_ name: String)
    {
        self.name = name
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try container.decodeIfPresent(UUID.self, forKey: .id) {
            self.id = id
        }
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }
    
    static func ==(lhs:AssetGroup, rhs:AssetGroup) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}

class AssetFolder       : Codable
{
    var assets          : [Asset] = []
    var game            : Game!
    var current         : Asset? = nil
    
    var groups          : [AssetGroup] = []
    
    var currentPath     : String? = nil
    
    private enum CodingKeys: String, CodingKey {
        case assets
        case groups
    }
    
    init()
    {
    }
    
    func setup(_ game: Game)
    {
        self.game = game
        
        guard let path = Bundle.main.path(forResource: "Game", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        guard let path1 = Bundle.main.path(forResource: "Box", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        guard let path2 = Bundle.main.path(forResource: "Map", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let value = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Behavior, name: "Game", value: value))
            current = assets[0]
        }
        
        if let value = try? String(contentsOfFile: path1, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Behavior, name: "Box", value: value))
        }
        
        if let value = try? String(contentsOfFile: path2, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .Map, name: "Map", value: value))
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assets = try container.decode([Asset].self, forKey: .assets)
        if let gs = try container.decodeIfPresent([AssetGroup].self, forKey: .groups)
        {
            groups = gs
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assets, forKey: .assets)
        try container.encode(groups, forKey: .groups)
    }
    
    /// Adds a Behavior
    func addBehavior(_ name: String, value: String = "", groupId: UUID? = nil)
    {
        guard let path = Bundle.main.path(forResource: "NewBehavior", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let behaviorTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            let asset = Asset(type: .Behavior, name: name, value: behaviorTemplate)
            asset.groupId = groupId
            assets.append(asset)
            select(asset.id)
            game.scriptEditor?.createSession(asset)
        }
    }
    
    func addShader(_ name: String, groupId: UUID? = nil)
    {
        guard let path = Bundle.main.path(forResource: "NewShader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let shaderTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            let asset = Asset(type: .Shader, name: name, value: shaderTemplate)
            asset.groupId = groupId
            assets.append(asset)
            select(asset.id)
            game.scriptEditor?.createSession(asset)
        }
    }
    
    func addMap(_ name: String, groupId: UUID? = nil)
    {
        let asset = Asset(type: .Map, name: name, value: "")
        asset.groupId = groupId
        assets.append(asset)
        select(asset.id)
        game.scriptEditor?.createSession(asset)
    }
    
    func addImages(_ name: String, _ urls: [URL], existingAsset: Asset? = nil)
    {
        let asset: Asset
            
        if existingAsset != nil {
            asset = existingAsset!
        } else {
            asset = Asset(type: .Image, name: name)
            assets.append(asset)
        }

        for url in urls {
            if let imageData: Data = try? Data(contentsOf: url) {
                asset.data.append(imageData)
            }
        }
        
        game.scriptEditor?.createSession(asset)
        select(asset.id)
    }
    
    func addAudio(_ name: String, _ urls: [URL], existingAsset: Asset? = nil)
    {
        let asset: Asset
            
        if existingAsset != nil {
            asset = existingAsset!
        } else {
            asset = Asset(type: .Audio, name: name)
            assets.append(asset)
        }

        for url in urls {
            if let audioData: Data = try? Data(contentsOf: url) {
                asset.data.append(audioData)
            }
        }
        
        game.scriptEditor?.createSession(asset)
        select(asset.id)
    }
    
    /// Select the asset of the given id
    func select(_ id: UUID)
    {
        if let current = current {
            if current.type == .Map {
                if game.mapBuilder.cursorTimer != nil {
                    game.mapBuilder.stopTimer()
                }
                current.map = nil
            } else
            if current.type == .Behavior {
                if game.behaviorBuilder.cursorTimer != nil {
                    game.behaviorBuilder.stopTimer()
                }
                current.map = nil
            }
        }

        for asset in assets {
            if asset.id == id {
                if asset.scriptName.isEmpty {
                    game.scriptEditor?.createSession(asset)
                }
                game.scriptEditor?.setAssetSession(asset)
                
                if game.state == .Idle {
                    assetCompile(asset)
                    if asset.type == .Map {
                        if game.mapBuilder.cursorTimer == nil {
                            game.mapBuilder.startTimer(asset)
                        }
                    } else
                    if asset.type == .Behavior {
                        if game.behaviorBuilder.cursorTimer == nil {
                            game.behaviorBuilder.startTimer(asset)
                        }
                    }
                }
                
                current = asset
                break
            }
        }
    }
    
    /// Get a system image name for the given asset
    func getSystemName(_ id: UUID) -> String {
        
        if let asset = getAssetById(id) {
            if asset.type == .Behavior {
                return "lightbulb"//"circles.hexagongrid.fill"
            } else
            if asset.type == .Map {
                return "list.and.film"
            } else
            if asset.type == .Audio {
                return "waveform"
            } else
            if asset.type == .Image {
                return "photo.on.rectangle"
            } else
            if asset.type == .Shader {
                return "fx"
            }
        }
        
        return ""
    }
    
    /// Returns the group identified by the given id
    func getGroupById(_ id: UUID) -> AssetGroup? {
        for group in groups {
            if group.id == id {
                return group
            }
        }
        return nil
    }
    
    /// Exctracts the path
    func extractPath(_ path: String) -> String?
    {
        if path.contains("/") {
            let a = path.split(separator: "/")
            var p = ""
            for index in 0..<a.count-1  {
                if index > 0 { p += "/" }
                p += a[index]
            }
            return p
        }        
        return nil
    }
    
    /// Resolves the given path into the name and the id of the AssetGroup
    func resolvePath(_ path: String) -> (String, UUID?)?
    {
        var name = ""
        var groupId : UUID? = nil
        
        if path.contains("/") {
            let a = path.split(separator: "/")
            if a.count >= 2 {
                for group in groups {
                    if group.name == a[0] {
                        groupId = group.id
                        
                        // Future, check for sub groups
                        break
                    }
                }
                name = String(a[a.count - 1])
                return (name, groupId)
            }
        } else {
            return (path, groupId)
        }
        return nil
    }
    
    /// Get an asset based on the path and type
    func getAsset(_ name: String,_ type: Asset.AssetType = .Behavior) -> Asset?
    {
        var path = name
        
        // Add the current subpath if any
        if let current = currentPath {
            path = current + "/" + name
        }
        
        if let tuple = resolvePath(path) {
            let name = tuple.0
            let groupId = tuple.1
            
            for asset in assets {
                if asset.type == type && asset.name == name && asset.groupId == groupId {
                    return asset
                }
            }
        }
        return nil
    }
    
    /// Get an asset based on its id and type
    func getAssetById(_ id: UUID,_ type: Asset.AssetType = .Behavior) -> Asset?
    {
        for asset in assets {
            if asset.type == type && asset.id == id {
                return asset
            }
        }
        return nil
    }
    
    /// Get an asset based on its id only
    func getAssetById(_ id: UUID) -> Asset?
    {
        for asset in assets {
            if asset.id == id {
                return asset
            }
        }
        return nil
    }
    
    /// Creates an MTLTexture for the given Image index
    func getAssetTexture(_ path: String,_ index: Int = 0) -> MTLTexture?
    {
        if let asset = getAsset(path, .Image) {
            if index >= 0 && index < asset.data.count {
                let data = asset.data[index]
                
                let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : false, .SRGB : false]                
                return try? game.textureLoader.newTexture(data: data, options: options)
            }
        }
        return nil
    }
    
    /// The asset was updated in the editor, compile it
    func assetUpdated(id: UUID, value: String)//, deltaStart: Int32, deltaEnd: Int32)
    {
        for asset in assets {
            if asset.id == id {
                asset.value = value
                if game.state == .Idle {
                    assetCompile(asset)
                }
            }
        }
    }
    
    // Compile the asset
    func assetCompile(_ asset: Asset)
    {
        if asset.type == .Behavior {
            game.behaviorBuilder.compile(asset)
        } else
        if asset.type == .Map {
            game.mapBuilder.compile(asset)//, deltaStart: deltaStart, deltaEnd: deltaEnd)
        } else
        if asset.type == .Shader {
            game.shaderCompiler.compile(asset: asset, cb: { (shader, errors) in
                if shader == nil {
                    if Thread.isMainThread {
                        self.game.scriptEditor!.setErrors(errors)
                    } else {
                        DispatchQueue.main.sync {
                            self.game.scriptEditor!.setErrors(errors)
                        }
                    }
                } else {
                    asset.shader = nil
                    asset.shader = shader
                    
                    if Thread.isMainThread {
                        self.game.createPreview(asset)
                        self.game.scriptEditor!.clearAnnotations()
                    } else {
                        DispatchQueue.main.sync {
                            self.game.createPreview(asset)
                            self.game.scriptEditor!.clearAnnotations()
                        }
                    }
                }
            })
        }
    }
    
    /// Safely removes an asset from the project
    func removeAsset(_ asset: Asset)
    {
        if let index = assets.firstIndex(of: asset) {
            if asset.type == .Behavior {
                game.behaviorBuilder.stopTimer()
            } else
            if asset.type == .Map {
                game.mapBuilder.stopTimer()
            }
            assets.remove(at: index)
            select(assets[0].id)
        }
    }
    
    // Create a preview for the current asset
    func createPreview()
    {
        if let asset = current {
            //if asset.type == .Behavior {
            //    game.behaviorBuilder.compile(asset)
            //} else
            if asset.type == .Map, asset.map != nil {
                game.mapBuilder.createPreview(asset.map!, true)
            } else
            if asset.type == .Shader {
                self.game.createPreview(asset)
            } else
            if asset.type == .Image {
                self.game.createPreview(asset)
            }
        }
    }
}

class Asset         : Codable, Equatable
{
    enum AssetType  : Int, Codable {
        case Behavior, Image, Shader, Map, Audio
    }
    
    var type        : AssetType = .Behavior
    var id          = UUID()
    
    //var children    : [Asset]? = nil
    var groupId     : UUID? = nil
    
    var name        = ""
    var value       = ""
    
    var data        : [Data] = []
    var dataIndex   : Int = 0
    var dataScale   : Double = 1

    // For the script based assets
    var scriptName  = ""

    // If this is a .Map asset
    var map         : Map? = nil
    
    // If this is a .Behavior asset
    var behavior    : BehaviorContext? = nil

    // If this is a shader
    var shader      : Shader? = nil

    // If the asset has an error
    var hasError    : Bool = false
            
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case groupId
        case name
        case value
        case uuid
        case data
    }
    
    init(type: AssetType, name: String, value: String = "", data: [Data] = [])
    {
        self.type = type
        self.name = name
        self.value = value
        self.data = data
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(AssetType.self, forKey: .type)
        id = try container.decode(UUID.self, forKey: .id)
        if let gId = try container.decodeIfPresent(UUID?.self, forKey: .groupId) {
            groupId = gId
        }
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        data = try container.decode([Data].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(groupId, forKey: .groupId)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(data, forKey: .data)
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
