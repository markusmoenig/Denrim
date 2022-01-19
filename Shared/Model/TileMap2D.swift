//
//  TileMap2D.swift
//  Denrim
//
//  Created by Markus Moenig on 19/1/22.
//

import Foundation

/// TileMaps consist of alias texts at given
class TileMap2D     : Codable
{
    var tiles               : [SIMD2<Int>: String] = [:]
    var cursor              : SIMD2<Int> = SIMD2<Int>(0, 0)

    var scale               : Float = 1

    private enum CodingKeys: String, CodingKey {
        case tiles
    }
    
    init()
    {
    }
    
    required init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let tiles = try container.decodeIfPresent([SIMD2<Int>: String].self, forKey: .tiles) {
            self.tiles = tiles
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tiles, forKey: .tiles)
    }
}
