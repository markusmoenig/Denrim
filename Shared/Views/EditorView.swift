//
//  EditorView.swift
//  Denrim
//
//  Created by Markus Moenig on 23/12/21.
//

import SwiftUI

struct EditorView: View {
    
    @State var game                                     : Game

    @State private var isMaximized                      =  false
    @State private var isRunning                        =  false
    @State private var showingDebug                     =  false

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
                    
                    //isRunning = true
                    //helpIsVisible = false
                    //updateView.toggle()
                })
                {
                    //Label("Run", systemImage: "play.fill")
                    Image(systemName: "play.fill")
                        .imageScale(.large)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("r")
                .padding(.leading, 10)
                
                Button(action: {
                    if game.view == nil { return }
                    game.stop()
                    //isRunning = false
                    //updateView.toggle()
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
        }
    }
}
