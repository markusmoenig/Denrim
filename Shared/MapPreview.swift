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
    
    func preview(_ map: Map,_ variable: String?, _ command: String? = nil)
    {
        self.map = map
        currentVariable = variable
        
        game.startDrawing()
        map.texture?.drawChecker()
        
        var helpKey = "MapHelp"
        game.contextText = ""
        
        if let command = command {
            helpKey = command
        }
        
        if let variable = variable {
            if let image = map.images[variable] {
                stopTimer()
                if let texture2D = map.getImageResource(image.resourceName) {
                    drawTexture(texture2D)
                }
                helpKey = "Image"
            } else
            if let _ = map.audio[variable] {
                stopTimer()
                helpKey = "Audio"
            } else
            if let _ = map.behavior[variable] {
                stopTimer()
                helpKey = "Behavior"
            } else
            if let _ = map.physics2D[variable] {
                stopTimer()
                helpKey = "Physics2D"
            } else
            if let _ = map.shaders[variable] {
                stopTimer()
                helpKey = "Shader"
            } else
            if let _ = map.gridInstancers[variable] {
                stopTimer()
                helpKey = "GridInstance2D"
            } else
            if let _ = map.onDemandInstancers[variable] {
                stopTimer()
                helpKey = "OnDemandInstance2D"
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
                helpKey = "Sequence"
            } else
            if map.aliases[variable] != nil {
                map.drawAlias(0, 0, &map.aliases[variable]!)
                helpKey = "Alias"
            } else
            if let layer = map.layers[variable] {
                helpKey = "Layer"
                map.drawLayer(0, 0, layer)
            } else
            if let scene = map.scenes[variable] {
                helpKey = "Scene"
                map.drawScene(0, 0, scene)
            } else
            if let shape = map.shapes2D[variable] {
                helpKey = "Shape2D"
                map.drawShape(shape)
            }
        }
        
        if helpKey != game.contextKey {
            if helpKey != "MapHelp" {
                if let helpText = game.scriptEditor!.getMapHelpForKey(helpKey) {
                    game.contextText = helpText
                    game.contextKey = helpKey
                }
            } else {
                game.contextText = game.scriptEditor!.mapHelpText
                game.contextKey = "MapHelp"
            }
            game.contextTextChanged.send(game.contextText)
        }
        
        game.stopDrawing()
        game.updateOnce()
    }
    
    func drawTexture(_ texture: Texture2D)
    {
        if let map = map {            
            var options = MapAliasData2D(Float2(0,0))
            options.texture = texture
            options.width = Float1(texture.width)
            options.height = Float1(texture.height)
            map.drawTexture(options)
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
