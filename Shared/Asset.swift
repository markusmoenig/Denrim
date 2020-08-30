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
            assets.append(Asset(type: .JavaScript, name: "Game.js", value: gameTemplate))
            game.changed()
            game.current = "Game.js"
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
    
    func addScript(_ name: String)
    {
        let asset = Asset(type: .JavaScript, name: name + ".js", value: "ho")
        assets.append(asset)
        game.changed()
        game.current = name + ".js"
        current = asset
        game.scriptEditor?.createSession(asset)
    }
    
    func addShader(_ name: String)
    {
        guard let path = Bundle.main.path(forResource: "Shader", ofType: "txt", inDirectory: "Resources") else {
            return
        }
        
        if let shaderTemplate = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                
            let asset = Asset(type: .Shader, name: name + ".sh", value: shaderTemplate)
            assets.append(asset)
            game.changed()
            game.current = name + ".sh"
            current = asset
            game.scriptEditor?.createSession(asset)
        }
    }
    
    func addImage(_ name: String, _ url: URL)
    {
        if let imageData: Data = try? Data(contentsOf: url) {
            let asset = Asset(type: .Image, name: name, data: [imageData])
            
            current = asset
            assets.append(asset)
            game.current = name
            game.changed()
        }
    }
    
    func select(_ id: UUID)
    {
        for asset in assets {
            if asset.id == id {
                game.changed()
                game.current = asset.name
                current = asset
                if asset.type == .JavaScript || asset.type == .Shader {
                    game.scriptEditor?.setAssetSession(asset)
                }
                break
            }
        }
    }
    
    func getAsset(_ name: String,_ type: Asset.AssetType = .JavaScript) -> Asset?
    {
        for asset in assets {
            if asset.name == name && asset.type == type {
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
                game.changed()
            }
        }
    }
}

class Asset         : Codable, Equatable
{
    enum AssetType  : Int, Codable {
        case JavaScript, Image, Shader
    }
    
    var type        : AssetType = .JavaScript
    
    var id          = UUID()
    
    var name        = ""
    var value       = ""
    
    var data        : [Data] = []
    
    var scriptName  = ""
        
    private enum CodingKeys: String, CodingKey {
        case type
        case id
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
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(String.self, forKey: .value)
        data = try container.decode([Data].self, forKey: .data)
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(value, forKey: .value)
        try container.encode(data, forKey: .data)
    }
    
    static func ==(lhs:Asset, rhs:Asset) -> Bool { // Implement Equatable
        return lhs.id == rhs.id
    }
}
