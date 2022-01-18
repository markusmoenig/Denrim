//
//  MapEditor.swift
//  Denrim
//
//  Created by Markus Moenig on 17/1/22.
//

import MetalKit

class MapEditor
{
    let game                        : Game
    
    var map                         : Map!
    var layer                       : MapLayer!
        
    init(_ game: Game)
    {
        self.game = game
    }
    
    func draw(_ map: Map, layer: MapLayer) {
        
        self.map = map
        self.layer = layer
        
        if let asset = game.assetFolder.current {
            //game.texture?.clear()//Float4(0.5, 0.5, 0.5, 1))
            
            let scale = Float(asset.dataScale)

            //game.texture?.drawGrid(size: layer.options.gridSize.x, scale: scale)//Float(asset.dataScale))
            
            let gridSize = layer.options.gridSize.x * scale

            game.texture?.drawChecker(size: Float2(gridSize, gridSize))

            if game.assetFolder.tileMaps[layer.options.tileMap] != nil {

                for (pos, a) in game.assetFolder.tileMaps[layer.options.tileMap]! {
                                     
                    if map.aliases[a] != nil {
                        var options : [String:Any] = [:]

                        func checkAliasTexture(_ alias: inout MapAlias) {
                            if alias.options.texture == nil {
                                if alias.type == .Image {
                                    if let image = map.images[alias.pointsTo] {
                                        if let texture2D = map.getImageResource(image.resourceName) {
                                            alias.options.texture = texture2D
                                        }
                                    }
                                }
                            }
                        }
                        
                        checkAliasTexture(&map.aliases[a]!)
                        
                        let texture2D = map.aliases[a]!.options.texture

                        options["texture"] = texture2D
                        options["position"] = Float2(Float(pos.x) * gridSize, Float(-pos.y) * gridSize)

                        if let rect = map.aliases[a]!.options.rect {
                            options["width"] = rect.z * scale
                            options["height"] = rect.w * scale
                            options["rect"] = Rect2D(rect.x, rect.y, rect.z, rect.w)
  
                        } else {
                            options["width"] = map.aliases[a]!.options.width.x * scale
                            options["height"] = map.aliases[a]!.options.height.x * scale
                        }

                        game.texture?.drawTexture(options)
                    }
                }
            }
        }
    }
    
    func mouseDown(_ x: Float,_ y: Float) {

        let scale = Float(2)
        
        let cX = Int(x / (layer.options.gridSize.x * scale))
        let cY = Int(y / (layer.options.gridSize.x * scale))
        
        if game.assetFolder.tileMaps[layer.options.tileMap] == nil {
            game.assetFolder.tileMaps[layer.options.tileMap] = [:]
        }
        
        if game.assetFolder.tileMaps[layer.options.tileMap] != nil {

            game.assetFolder.tileMaps[layer.options.tileMap]![SIMD2<Int>(cX, cY)] = game.mapBuilder.selectedAlias

            print("ttt set", cX, cY, "to", game.mapBuilder.selectedAlias)
        }
    }
}
