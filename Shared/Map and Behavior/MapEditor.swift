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
    
    var splitView                   = true
        
    init(_ game: Game)
    {
        self.game = game
    }
    
    func draw(_ map: Map, layer: MapLayer) {
        
        self.map = map
        self.layer = layer

        if let tileMap = game.assetFolder.tileMaps[layer.options.tileMap] {

            let scale = tileMap.scale
            let gridSize = layer.options.gridSize.x * scale

            game.texture?.drawChecker(size: Float2(gridSize, gridSize))
            
            // Draw Tiles
            for (pos, a) in tileMap.tiles {
                                 
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
                    options["position"] = Float2(Float(pos.x + Int(tileMap.offset.x)) * gridSize, Float(-pos.y - Int(tileMap.offset.y)) * gridSize)

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
            
            // Draw Cursor
            
            var options : [String:Any] = [:]

            options["position"] = Float2(Float(tileMap.cursor.x + Int(tileMap.offset.x)) * gridSize, Float(-tileMap.cursor.y - Int(tileMap.offset.y)) * gridSize)

            options["border"] = Float(1.5)
            options["color"] = Float4(0,0,0,0)
            options["bordercolor"] = Float4(1,1,1,1)

            options["size"] = Float2(layer.options.gridSize.x * scale, layer.options.gridSize.x * scale)
            
            game.texture?.drawBox(options)
        }
    }
    
    func mouseDown(_ x: Float,_ y: Float) {

        if game.assetFolder.tileMaps[layer.options.tileMap] == nil {
            game.assetFolder.tileMaps[layer.options.tileMap] = TileMap2D()
        }
        
        if let tileMap = game.assetFolder.tileMaps[layer.options.tileMap] {

            let cX = Int(x / (layer.options.gridSize.x * tileMap.scale)) - Int(tileMap.offset.x)
            let cY = Int(y / (layer.options.gridSize.x * tileMap.scale)) - Int(tileMap.offset.y)
            
            tileMap.tiles[SIMD2<Int>(cX, cY)] = game.mapBuilder.selectedAlias
            tileMap.cursor = SIMD2<Int>(cX, cY)

            print("ttt set", cX, cY, "to", game.mapBuilder.selectedAlias)
        }
    }
    
    func scrollWheel(with event: NSEvent) {
        if let tileMap = game.assetFolder.tileMaps[layer.options.tileMap] {
            if game.view.commandIsDown {
                //map.camera2D.zoom += Float(event.deltaY) * 0.1
                //map.camera2D.zoom = max(map.camera2D.zoom, 0.01)
            } else {
                tileMap.offset.x += Float(event.deltaX)
                tileMap.offset.y += Float(event.deltaY)
            }
            game.mapBuilder.createPreview(map, true)
        }
    }
    
    func setScale(_ scale: Float) {
        if let tileMap = game.assetFolder.tileMaps[layer.options.tileMap] {
            tileMap.scale = scale
        }
    }
}
