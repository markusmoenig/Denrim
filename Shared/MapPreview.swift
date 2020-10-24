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
        
        game.helpText = ""
        
        //let screenSize = map.getScreenSize()
        //let aspect = float2(map.texture!.width, map.texture!.height)
        //let aspectY = Float(map.texture!.height)
        //let aspectRatio = min(aspect.x, aspect.y)

        if let variable = variable {

            if let image = map.images[variable] {
                game.helpText = "Image"
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
                map.drawAlias(0, 0, alias, scale: 1)
            } else
            if let layer = map.layers[variable] {
                game.helpText = "Layer - Defines a layer of visual content in a Scene\n\n"
                map.drawLayer(0, 0, layer, scale: 1)
            } else
            if let scene = map.scenes[variable] {
                game.helpText = "Scene - Defines a scene in the game which consists of several layers of visual content\n\n<Layers: Layer,...>"
                map.drawScene(0, 0, scene, scale: 1)
            } else
            if let shape = map.shapes2D[variable] {
                game.helpText = "Shape2D<Type: Text><Position: Float2> - Defines a 2D shape of a given type (Disk, Box, Text)\n\n"

                if shape.shape == .Disk {
                    game.helpText += "<Type: \"Disk\"> - <Radius: Float><Border: Float><Color: Float4>"
                } else
                if shape.shape == .Box {
                    game.helpText += "<Type: \"Box\"> - <Size: Float2><Round: Float><Border: Float><Color: Float4>"
                } else
                if shape.shape == .Text {
                    game.helpText += "<Type: \"Text\"> - <Font: Text><FontSize: Float><Int|Float|Text: Value><Digits: Int><Color: Float4>"
                }
                map.drawShape(shape)
            }
        }
        
        game.stopDrawing()
        game.updateOnce()
                
        game.helpTextChanged.send()
    }
    
    func drawTexture(_ texture: Texture2D)
    {
        if let map = map {
            var object : [String:Any] = [:]
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
