//
//  EditorView.swift
//  Denrim
//
//  Created by Markus Moenig on 23/12/21.
//

import SwiftUI

struct EditorView: View {
    
    @State var game                                     : Game

    @State private var isMaximized                      = false
    @State private var isRunning                        = false
    @State private var showingDebug                     = false
    
    @State private var isShowingImage                   = false

    @State private var imageScaleValue                  : Float = 1
    @State private var imageScaleText                   : String = "1"
    @State private var imageScaleRange                  = float2(0.001, 4)
    
    @State private var imageIndexValue                  : Float = 0
    @State private var imageIndexText                   : String = "0"
    @State private var imageIndexRange                  = float2(0, 1)

    @Environment(\.colorScheme) var deviceColorScheme   : ColorScheme

    var body: some View {
        
        VStack {
        
            HStack(spacing: 12) {
                
                Button(action: {
                    if game.view == nil { return }
                    
                    if isMaximized {
                        isMaximized.toggle()
                        game.editorIsMaximized.send(isMaximized)
                    }
                    
                    game.stop(silent: true)
                    game.start()
                })
                {
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("r")
                .padding(.leading, 10)
                
                Button(action: {
                    if game.view == nil { return }
                    game.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .imageScale(.large)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isRunning)
                .keyboardShortcut(".")
                
                Button(action: {
                    if let scriptEditor = game.scriptEditor {
                        if game.showingDebugInfo == false {
                            scriptEditor.activateDebugSession()
                            showingDebug = true
                        } else {
                            game.showingDebugInfo = false
                            showingDebug = false
                            if let current = game.assetFolder.current {
                                game.assetFolder.select(current.id)
                            }
                        }
                    }
                }) {
                    Image(systemName: showingDebug ? "ant.fill" : "ant")
                        .imageScale(.large)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("b")
                
                if isShowingImage {
                    Divider()
                
                    Text("Index")
                    DataIntSliderView("Index", $imageIndexValue, $imageIndexText, $imageIndexRange)
                        .frame(width: 120)
                        .onChange(of: imageIndexValue) { newState in
                            if let asset = game.assetFolder.current {
                                asset.dataIndex = Int(newState)
                                game.assetFolder.createPreview()
                            }
                        }
                    
                    Text("Scale")
                    DataFloatSliderView("Scale", $imageScaleValue, $imageScaleText, $imageScaleRange)
                        .frame(width: 120)
                        .onChange(of: imageScaleValue) { newState in
                            if let asset = game.assetFolder.current {
                                asset.dataScale = Double(newState)
                                game.assetFolder.createPreview()
                            }
                        }
                }
                
                Spacer()
                
                Button(action: {
                    isMaximized.toggle()
                    game.editorIsMaximized.send(isMaximized)
                }) {
                    Image(systemName: isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .imageScale(.large)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 12)
                .keyboardShortcut("t")
            }
            .frame(height: 20)
            
            WebView(game, deviceColorScheme)
            .onChange(of: deviceColorScheme) { newValue in
                game.scriptEditor?.setTheme(newValue)
            }
        
            .onReceive(game.gameIsRunning) { value in
                isRunning = value
                showingDebug = false
            }
            
            .onReceive(game.isShowingImage) { value in
                isShowingImage.toggle()
                isShowingImage = value
                if value {
                    imageIndexValue = Float(game.assetFolder.current!.dataIndex)
                    imageIndexRange.y = Float(game.assetFolder.current!.data.count) - 1
                }
            }
        }
    }
}
