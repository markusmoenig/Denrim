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

    let game                        : Game
    weak var map                    : Map?
    
    var layerOffset                 : float2? = nil
    
    var currentVariable             : String?
    var animIndex                   : Int = 0
    
    init(_ game: Game)
    {
        self.game = game
    }
    
    func preview(_ map: Map,_ variable: String?, _ command: String? = nil, layerLineOffset: Int32? = nil)
    {
        self.map = map
        currentVariable = variable
        
        layerOffset = nil
        
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
                if animIndex >= seq.resourceNames.count {
                    animIndex = 0
                }
                
                if animIndex >= 0 && animIndex < seq.resourceNames.count {
                    let resourceName = seq.resourceNames[animIndex]
                    if let texture2D = map.getImageResource(resourceName) {
                        drawTexture(texture2D)
                    }
                    
                    if animationTimer == nil {
                        startTimer()
                    }
                }
                helpKey = "Sequence"
            } else
            if map.aliases[variable] != nil {
                map.textureState = .DrawTextureWhiteAlpha
                map.currentSampler = game.nearestSampler

                let x = (game.texture!.width - map.viewBorder.x * 2.0 - map.aliases[variable]!.options.width.x * map.camera2D.zoom) / 2.0
                let y = (game.texture!.height - map.viewBorder.y * 2.0 - map.aliases[variable]!.options.height.x * map.camera2D.zoom) / 2.0

                map.startEncoding()
                map.drawAlias(x, y, &map.aliases[variable]!)
                map.stopEncoding()
                helpKey = "Alias"
                
                map.textureState = .DrawTexture
                map.currentSampler = game.linearSampler
                map.lastPreviewOffset.x = x
                map.lastPreviewOffset.y = y
            } else
            if let layer = map.layers[variable] {
                helpKey = "Layer"
                
                if layer.options.tileMap.isEmpty == false {
                    game.mapEditor.draw(map, layer: layer)
                }
                /*
                map.startEncoding()
                
                var x : Float = -map.viewBorder.x
                var y : Float = -map.viewBorder.y - layer.options.offset.y * map.aspect.y
                       
                var cX : Float? = nil
                var cY : Float? = nil

                let gridSize = map.getLayerGridSize(layer)

                // Center it
                if layer.data.count > 1 || (layer.data.count == 1 && layer.data[0].line.count > 1) {


                    if let layerLineOffset = layerLineOffset {
                        if layerLineOffset >= 1 {
                                                        
                            cX = Float((game.mapBuilder.scriptColumn - 2) / 2)
                            cY = Float(layerLineOffset - 1)
                            
                            if let cX = cX, let cY = cY {
                                
                                let iX = Int(cX)
                                let iY = Int(cY)
                            
                                if let alias = layer.getAliasAt(iX, iY) {
                                    self.game.tempTextChanged.send("(\(iX), \(iY)) : \(alias.id)")
                                } else {
                                    self.game.tempTextChanged.send("(\(iX), \(iY))")
                                }
                            }
                        }
                    }
                
                    let layerWidth = gridSize.x * Float(layer.maxWidth)
                    let layerHeight = gridSize.y * Float(layer.maxHeight)
                    
                    x -= (layerWidth - game.texture!.width) / 2.0
                    y -= (layerHeight - game.texture!.height) / 2.0
                }
                
                map.drawLayer(x, y, layer)
                
                if var cX = cX, var cY = cY {
                    
                    let layerWidth = gridSize.x * Float(layer.maxWidth)
                    let layerHeight = gridSize.y * Float(layer.maxHeight)
                    
                    cX *= gridSize.x
                    cY *= gridSize.y
                    
                    cX -= (layerWidth - game.texture!.width) / 2.0
                    cY -= (layerHeight - game.texture!.height) / 2.0
                    
                    layerOffset = float2(-(layerWidth - game.texture!.width) / 2.0, -(layerHeight - game.texture!.height) / 2.0)
                    
                    let options: [String: Any] = ["position": Float2(cX, cY),
                                                  "size"    : Float2(gridSize.x, gridSize.y),
                                                  "color"   : Float4(1,1,1,0.3)
                    ]
                    let shapeOptions = MapShapeData2D(options)
                    map.drawDebugBox(shapeOptions)
                }
                map.stopEncoding()
                */
            } else
            if let scene = map.scenes[variable] {
                helpKey = "Scene"
                map.drawScene(0, 0, scene)
            } else
            if let shape = map.shapes2D[variable] {
                helpKey = "Shape2D"
                map.startEncoding()
                map.drawShape(shape)
                map.stopEncoding()
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
    
    func mouseDown(_ x: Float,_ y: Float) {
        
        if let variable = currentVariable {
            if let map = map {
                if let layer = map.layers[variable] {
                    if let layerOffset = layerOffset {
                        let gridSize = map.getLayerGridSize(layer)

                        let cX : Int32 = Int32((x - map.camera2D.xOffset - layerOffset.x) / gridSize.x)
                        let cY : Int32 = Int32((y - map.camera2D.yOffset - layerOffset.y) / gridSize.y)
                                                                        
                        let line = cY + layer.startLine
                        let column = 2 + cX * 2
                        
                        game.scriptEditor?.goto(line: line)
                        
                        if game.mapBuilder.selectedAlias.isEmpty == true {
                            game.scriptEditor?.select(lineS: line, columnS: column, lineE: line, columnE: column + 2)
                            //game.scriptEditor?.getSelectedText({ text in
                            //    self.game.tempTextChanged.send("P: (\(cX), \(cY)), A: \(text)")
                            //})
                        } else {
                            game.scriptEditor?.selectAndReplace(lineS: line, columnS: column, lineE: line, columnE: column + 2, replaceWith: game.mapBuilder.selectedAlias)
                            //self.game.tempTextChanged.send("P: (\(cX), \(cY)), A: \(game.mapBuilder.selectedAlias)")
                        }
                        
                        //game.scriptEditor?.getSelectedRange({ sline, scolumn, eline, ecolumn in
                        //})
                    }
                }
            }
        }
    }
    
    func drawTexture(_ texture: Texture2D)
    {
        if let map = map {
            map.currentSampler = game.nearestSampler

            var options = MapAliasData2D(Float2(0,0))
            options.texture = texture
        
            options.width = Float1(texture.width)
            options.height = Float1(texture.height)
            
            let x = (game.texture!.width - map.viewBorder.x * 2.0 - texture.width * map.camera2D.zoom) / 2.0
            let y = (game.texture!.height - map.viewBorder.y * 2.0 - texture.height * map.camera2D.zoom) / 2.0
            
            options.position.x = x
            options.position.y = y

            map.startEncoding()
            map.drawTexture(options)
            map.currentSampler = game.linearSampler
            map.lastPreviewOffset.x = x
            map.lastPreviewOffset.y = y
            map.stopEncoding()
        }
    }
    
    func startTimer()
    {
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: 0.5,
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
