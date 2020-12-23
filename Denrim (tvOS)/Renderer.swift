//
//  Renderer.swift
//  Denrim
//
//  Created by Markus Moenig on 23/12/20.
//

// Our platform independent renderer class

import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
    let game    : Game
    let view    : DMTKView
    
    init(game: Game, metalKitView: DMTKView) {
        self.game = game
        self.view = metalKitView
    }
    
    func draw(in view: MTKView) {
        game.draw()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
