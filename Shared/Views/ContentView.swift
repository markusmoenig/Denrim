//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

#if os(OSX)
var toolbarPlacement1 : ToolbarItemPlacement = .automatic

#else
var toolbarPlacement1 : ToolbarItemPlacement = .navigationBarLeading
#endif


struct ContentView: View {
    
    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme

    @Binding var document                   : DenrimDocument
    
    @StateObject var storeManager           : StoreManager

    @State private var editorIsMaximized    = false

    @State private var updateView           : Bool = false

    @State private var sideBarIsVisible     : Bool = true
            
    @State private var selection            : UUID? = nil
    
    #if os(macOS)
    let leftPanelWidth                      : CGFloat = 210
    let toolBarIconSize                     : CGFloat = 13
    let toolBarTopPadding                   : CGFloat = 0
    let toolBarSpacing                      : CGFloat = 4
    #else
    let leftPanelWidth                      : CGFloat = 270
    let toolBarIconSize                     : CGFloat = 16
    let toolBarTopPadding                   : CGFloat = 8
    let toolBarSpacing                      : CGFloat = 6
    #endif

    var body: some View {
        HStack {
            NavigationView() {

                ProjectView(document: document)
                .frame(minWidth: leftPanelWidth, idealWidth: leftPanelWidth, maxWidth: leftPanelWidth)
                
                if self.document.game.assetFolder.isNewProject {
                    GeometryReader { geometry in

                        BrowserView(document.game, updateView: $updateView, selection: $selection)
                            .frame(minWidth: geometry.size.width,
                                   maxWidth: geometry.size.width,
                                   minHeight: geometry.size.height,
                                   maxHeight: geometry.size.height,
                                   alignment: .topLeading)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

                    }
                } else {
                    VStack {
                        
                        //VStack {
                        MetalView(document.game)
                            .frame(maxHeight: editorIsMaximized ? 0 : .infinity)
                            .opacity(1)
                            .onReceive(document.game.editorIsMaximized) { value in
                                editorIsMaximized = value
                            }

                        EditorView(game: document.game)
                    
                        .onReceive(self.document.game.contentChanged) { state in
                            document.updated.toggle()
                        }
                    }
                }
            }
            if sideBarIsVisible == true && document.game.assetFolder.isNewProject == false {
                SideBarView(game: document.game)
            }        
        }
        .frame(minWidth: 1280, minHeight: 800)
        
        // For Mac Screenshots, 1440x900
        //.frame(minWidth: 1440, minHeight: 806)
        //.frame(maxWidth: 1440, maxHeight: 806)
        // For Mac App Previews 1920x1080
        //.frame(minWidth: 1920, minHeight: 978)
        //.frame(maxWidth: 1920, maxHeight: 978)
        // Import Audio

        .onAppear(perform: {
            if storeManager.myProducts.isEmpty {
                DispatchQueue.main.async {
                    storeManager.getProducts()
                }
            }
        })
            
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                       
                /*
                // Game Controls
                Button(action: {
                    if document.game.view == nil { return }
                    document.game.stop(silent: true)
                    document.game.start()
                    helpIsVisible = false
                    updateView.toggle()
                })
                {
                    Label("Run", systemImage: "play.fill")
                }
                .keyboardShortcut("r")
                
                Button(action: {
                    if document.game.view == nil { return }
                    document.game.stop()
                    updateView.toggle()
                }) {
                    Label("Stop", systemImage: "stop.fill")
                }.keyboardShortcut("t")
                .disabled(document.game.state == .Idle)
                
                Button(action: {
                    if let scriptEditor = document.game.scriptEditor {
                        if document.game.showingDebugInfo == false {
                            scriptEditor.activateDebugSession()
                        } else {
                            document.game.showingDebugInfo = false
                            if let current = document.game.assetFolder.current {
                                document.game.assetFolder.select(current.id)
                            }
                        }
                    }
                }) {
                    Label("Bug", systemImage: "ant.fill")
                }.keyboardShortcut("b")
                
                Divider()
                    .padding(.horizontal, 20)
                    .opacity(0)
                
                Menu {
                    Section(header: Text("Preview")) {
                        Button("Small", action: {
                            document.game.previewFactor = 4
                            updateView.toggle()
                        })
                        .keyboardShortcut("1")
                        Button("Medium", action: {
                            document.game.previewFactor = 2
                            updateView.toggle()
                        })
                        .keyboardShortcut("2")
                        Button("Large", action: {
                            document.game.previewFactor = 1
                            updateView.toggle()
                        })
                        .keyboardShortcut("3")
                    }
                    Section(header: Text("Opacity")) {
                        Button("Opacity Off", action: {
                            document.game.previewOpacity = 0
                            updateView.toggle()
                        })
                        .keyboardShortcut("4")
                        Button("Opacity Half", action: {
                            document.game.previewOpacity = 0.5
                            updateView.toggle()
                        })
                        .keyboardShortcut("5")
                        Button("Opacity Full", action: {
                            document.game.previewOpacity = 1.0
                            updateView.toggle()
                        })
                        .keyboardShortcut("6")
                    }
                }
                label: {
                    if let texture = document.game.texture?.texture {
                        Text("\(texture.width) x \(texture.height)")
                    }
                }
                .frame(minWidth: 100)
                .onReceive(self.document.game.updateUI) { value in
                    updateView.toggle()
                }
                
                Divider()
                    .padding(.horizontal, 20)
                    .opacity(0)
                 */
                /*
                Button(action: {
                    helpIsVisible.toggle()
                }) {
                    Label("Help", systemImage: "questionmark")
                }
                .keyboardShortcut("h")
                 */
                
                Menu {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Small Tip")
                                .font(.headline)
                            Text("Tip of $2 for the author")
                                .font(.caption2)
                        }
                        Button(action: {
                            storeManager.purchaseId("com.moenig.Denrim.IAP.Tip2")
                        }) {
                            Text("Buy for $2")
                        }
                        .foregroundColor(.blue)
                        Divider()
                        VStack(alignment: .leading) {
                            Text("Medium Tip")
                                .font(.headline)
                            Text("Tip of $5 for the author")
                                .font(.caption2)
                        }
                        Button(action: {
                            storeManager.purchaseId("com.moenig.Denrim.IAP.Tip5")
                        }) {
                            Text("Buy for $5")
                        }
                        .foregroundColor(.blue)
                        Divider()
                        VStack(alignment: .leading) {
                            Text("Large Tip")
                                .font(.headline)
                            Text("Tip of $10 for the author")
                                .font(.caption2)
                        }
                        Button(action: {
                            storeManager.purchaseId("com.moenig.Denrim.IAP.Tip10")
                        }) {
                            Text("Buy for $10")
                        }
                        .foregroundColor(.blue)
                        Divider()
                        Text("You are awesome! ❤️❤️")
                    }
                }
                label: {
                    Label("Dollar", systemImage: "gift")//dollarsign.circle")
                }
                
                Button(action: { sideBarIsVisible.toggle() }, label: {
                    Image(systemName: "sidebar.right")
                })
            }
        }
        
        .onReceive(self.document.game.gameError) { state in
            if let asset = self.document.game.assetError.asset {
                document.game.assetFolder.select(asset.id)
                document.game.scriptEditor?.setError(self.document.game.assetError, scrollToError: true)
            }
            self.updateView.toggle()
        }
    }
}

