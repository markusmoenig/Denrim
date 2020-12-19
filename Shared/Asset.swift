//
//  Asset.swift
//  Metal-Z
//
//  Created by Markus Moenig on 26/8/20.
//

import MetalKit

class AssetFolder       : Codable
{
    var assets          : [Asset] = []
    var game            : Game!
    var current         : Asset? = nil
        
    var currentPath     : String? = nil
    
    private enum CodingKeys: String, CodingKey {
        case assets
    }
    
    init()
    {
    }
    
    /// Sort the array
    func sort()
    {
        func getIndex(_ asset: Asset) -> Int
        {
            if asset.type == .Folder { return 0 }
            else
            if asset.type == .Behavior { return 1 }
            else
            if asset.type == .Map { return 2 }
            else
            if asset.type == .Shader { return 3 }
            else
            if asset.type == .Image { return 4 }
            else { return 5 }
        }
        
        func sorting(_ a0: Asset,_ a1: Asset) -> Bool
        {
            if getIndex(a0) < getIndex(a1) {
                return true
            }
            return false
        }
        
        assets = assets.sorted(by: {
            if $0.type == $1.type {
                return $0.name < $1.name
            } else
            if sorting($0, $1) {
                return true
            }
            
            return false
        })
        
        for asset in assets {
            if asset.type == .Folder {
                asset.children = asset.children!.sorted(by: {
                    
                    if $0.type == $1.type {
                        return $0.name < $1.name
                    } else
                    if sorting($0, $1) {
                        return true
                    }
                    
                    return false
                })
            }
        }
    }
    
    /// Sets up the default project
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
        sort()
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assets, forKey: .assets)
    }
    
    /// Adds a folder
    func addFolder(_ name: String)
    {
        let asset = Asset(type: .Folder, name: name)

        asset.children = []
        assets.insert(asset, at: 0)
        select(asset.id)
        game.scriptEditor?.createSession(asset)
    }
    
    /// Adds a Behavior
    func addBehavior(_ name: String, value: String = "", path: String? = nil)
    {
        guard let resourcePath = Bundle.main.path(forResource: "NewBehavior", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let behaviorTemplate = try? String(contentsOfFile: resourcePath, encoding: String.Encoding.utf8) {
            let asset = Asset(type: .Behavior, name: name, value: behaviorTemplate)
            if let path = path {
                if let folder = getAsset(path, .Folder) {
                    folder.children?.append(asset)
                }
            } else {
                assets.append(asset)
            }
            select(asset.id)
            game.scriptEditor?.createSession(asset)
        }
    }
    
    func addShader(_ name: String, path: String? = nil)
    {
        guard let resourcePath = Bundle.main.path(forResource: "NewShader", ofType: "", inDirectory: "Files/default") else {
            return
        }
        
        if let shaderTemplate = try? String(contentsOfFile: resourcePath, encoding: String.Encoding.utf8) {
            let asset = Asset(type: .Shader, name: name, value: shaderTemplate)
            if let path = path {
                if let folder = getAsset(path, .Folder) {
                    folder.children?.append(asset)
                }
            } else {
                assets.append(asset)
            }
            select(asset.id)
            game.scriptEditor?.createSession(asset)
        }
    }
    
    func addMap(_ name: String, path: String? = nil)
    {
        let asset = Asset(type: .Map, name: name, value: "")
        if let path = path {
            if let folder = getAsset(path, .Folder) {
                folder.children?.append(asset)
            }
        } else {
            assets.append(asset)
        }
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

        if let asset = getAssetById(id) {
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
        }
    }
    
    /// Moves the given asset to the folder
    func moveToFolder(folderName: String, asset: Asset)
    {
        var removedSuccessfully: Bool = false
        // Remove asset from current folder
        if asset.path == "" {
            if let index = assets.firstIndex(of: asset) {
                assets.remove(at: index)
                removedSuccessfully = true
            }
        }
        
        // Insert at new folder
        
        if removedSuccessfully {
            for a in assets {
                if a.type == .Folder && a.name == folderName {
                    a.children?.append(asset)
                    a.path = folderName
                    break
                }
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
            } else
            if asset.type == .Folder {
                return "folder"
            }
        }
        
        return ""
    }
    
    /// Returns true if the preview should be visible
    func isPreviewVisible() -> Bool
    {
        if game.state == .Running {
            return true
        } else
        if game.state == .Idle {
            if let current = current {
                if current.type != .Behavior && current.type != .Audio {
                    return true
                }
            }
        }
        return false
    }
    
    /// Exctracts the path from a string
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
    
    /// Extract the path from the group id of an asset
    func extractPath(_ asset: Asset) -> String?
    {
        return asset.path
    }
    
    /// Resolves the given path into the name and the folder asset
    func resolvePath(_ path: String) -> (String, Asset?)?
    {
        var name = ""
        var folder : Asset? = nil
        
        if path.contains("/") {
            let a = path.split(separator: "/")
            if a.count >= 2 {
                for fo in assets {
                    if fo.type == .Folder && fo.name == a[0] {
                        folder = fo
                        
                        // Future, check for sub groups
                        break
                    }
                }
                name = String(a[a.count - 1])
                return (name, folder)
            }
        } else {
            return (path, nil)
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
            
            if let folder = tuple.1 {
                for asset in folder.children! {
                    if asset.type == type && asset.name == name {
                        return asset
                    }
                }
            } else {
                for asset in assets {
                    if asset.type == type && asset.name == name {
                        return asset
                    }
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
            if let children = asset.children {
                for child in children {
                    if child.type == type && child.id == id {
                        return child
                    }
                }
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
            if let children = asset.children {
                for child in children {
                    if child.id == id {
                        return child
                    }
                }
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
            if let path = extractPath(asset) {
                currentPath = path
            }
            game.mapBuilder.compile(asset)//, deltaStart: deltaStart, deltaEnd: deltaEnd)
            currentPath = nil
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
        case Behavior, Image, Shader, Map, Audio, Folder
    }
    
    var type        : AssetType = .Behavior
    var id          = UUID()
    
    var children    : [Asset]? = nil
    var path        : String? = nil
        
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
        case name
        case value
        case uuid
        case data
        case children
        case path
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
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        data = try container.decode([Data].self, forKey: .data)
        if let childs = try container.decodeIfPresent([Asset]?.self, forKey: .children) {
            children = childs
        }
        if let p = try container.decodeIfPresent(String.self, forKey: .path) {
            path = p
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(data, forKey: .data)
        try container.encode(children, forKey: .children)
        try container.encode(path, forKey: .path)
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
