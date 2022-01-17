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
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func draw(_ map: Map, layer: MapLayer) {
        map.startEncoding()
        map.drawGrid()
        map.stopEncoding()
    }
}
