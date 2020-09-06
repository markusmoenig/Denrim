//
//  Asset.swift
//  Metal-Z
//
//  Created by Markus Moenig on 26/8/20.
//

import Foundation

class AssetFolder   : Codable
{
    var assets      : [Asset] = []
    var game        : Game!
    var current     : Asset? = nil
    
    private enum CodingKeys: String, CodingKey {
        case assets
    }
    
    init()
    {
    }
    
    func setup(_ game: Game)
    {
        self.game = game
        
        guard let path = Bundle.main.path(forResource: "Game", ofType: "js", inDirectory: "Resources") else {
            return
        }
        
        if let gameTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            assets.append(Asset(type: .JavaScript, name: "Game", value: gameTemplate))
            current = assets[0]
        }
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        assets = try container.decode([Asset].self, forKey: .assets)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(assets, forKey: .assets)
    }
    
    func addScript(_ name: String, value: String = "")
    {
        let asset = Asset(type: .JavaScript, name: name, value: value)
        assets.append(asset)
        current = asset
        game.scriptEditor?.createSession(asset)
    }
    
    func addShader(_ name: String)
    {
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "txt", inDirectory: "Resources") else {
            return
        }
        
        if let shaderTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                
            let asset = Asset(type: .Shader, name: name, value: shaderTemplate)
            assets.append(asset)
            current = asset
            game.scriptEditor?.createSession(asset)
        }
    }
    
    func addMap(_ name: String)
    {
        //guard let path = Bundle.main.path(forResource: "Shader", ofType: "txt", inDirectory: "Resources") else {
        //    return
        //}
        
        //if let mapTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                
            let asset = Asset(type: .Map, name: name, value: "")
            assets.append(asset)
            current = asset
            game.scriptEditor?.createSession(asset)
        //}
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
        
        current = asset
    }
    
    func select(_ id: UUID)
    {
        for asset in assets {
            if asset.id == id {
                if asset.type == .JavaScript || asset.type == .Shader {
                    game.scriptEditor?.setAssetSession(asset)
                }
                current = asset
                break
            }
        }
    }
    
    func getAsset(_ name: String,_ type: Asset.AssetType = .JavaScript) -> Asset?
    {
        for asset in assets {
            if asset.type == type && (asset.name == name || String(asset.name.split(separator: ".")[0]) == name) {
                return asset
            }
        }
        return nil
    }
    
    func assetUpdated(name: String, value: String)
    {
        for asset in assets {
            if asset.name == name {
                asset.value = value
                if game.state == .Idle {
                    game.mapBuilder.compile(asset)
                }
            }
        }
    }
}

class Asset         : Codable, Equatable
{
    enum AssetType  : Int, Codable {
        case JavaScript, Image, Shader, Map
    }
    
    var type        : AssetType = .JavaScript
    
    var id          = UUID()
    
    var group       = ""
    
    var name        = ""
    var value       = ""
    
    var data        : [Data] = []
    
    var scriptName  = ""
        
    private enum CodingKeys: String, CodingKey {
        case type
        case id
        case group
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
        group = try container.decode(String.self, forKey: .group)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        data = try container.decode([Data].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(group, forKey: .group)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(data, forKey: .data)
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
