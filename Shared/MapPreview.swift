//
//  MapPreview.swift
//  Denrim
//
//  Created by Markus Moenig on 10/9/20.
//

import MetalKit

class MapPreview
{
    var animationTimer  : Timer? = nil

    let game            : Game
    weak var map        : Map?
    
    var currentVariable : String?
    var animIndex       : Int = 0
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func preview(_ map: Map,_ variable: String?)
    {
        self.map = map
        currentVariable = variable
        
        game.startDrawing()
        map.texture?.drawChecker()
        
        if let variable = variable {

            if let image = map.images[variable] {
                stopTimer()
                if let texture2D = map.getImageResource(image.resourceName) {
                    drawTexture(texture2D)
                }
            } else
            if let seq = map.sequences[variable] {
                if let range = seq.options["range"] as? Float2 {
                    if animIndex > Int(range.y) {
                        animIndex = Int(range.x)
                    }
                }
                
                let resourceName = seq.resourceNames[animIndex]
                if let texture2D = map.getImageResource(resourceName) {
                    drawTexture(texture2D)
                }
                
                if animationTimer == nil {
                    startTimer()
                }
            } else
            if let alias = map.aliases[variable] {
                map.drawAlias(0, 0, alias, scale: 4)
            } else
            if let layer = map.layers[variable] {
                map.drawLayer(0, 0, layer, scale: 4)
            } else
            if let scene = map.scenes[variable] {
                map.drawScene(0, 0, scene, scale: 1)
            }
        }
        
        game.stopDrawing()
        game.updateOnce()
    }
    
    func drawTexture(_ texture: Texture2D)
    {
        if let map = map {
            var object : [AnyHashable : Any] = [:]
            object["texture"] = texture
            
            map.texture?.drawTexture(object)
        }
    }
    
    func startTimer()
    {
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: 0.2,
                                             target: self,
                                             selector: #selector(self.animationCallback),
                                             userInfo: nil,
                                             repeats: true)
            self.animationTimer = timer
        })
    }
    
    func stopTimer()
    {
        if animationTimer != nil {
            animationTimer?.invalidate()
            animationTimer = nil
        }
    }
    
    @objc func animationCallback(_ timer: Timer) {
        if let map = map {
            if let variable = currentVariable {
                animIndex += 1
                preview(map, variable)
            }
        }
    }
}
