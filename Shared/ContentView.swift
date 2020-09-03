//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: DenrimDocument
    
    @State private var showAssetNamePopover: Bool = false
    @State private var assetName: String = ""

    @State private var helpIsShowing: Bool = false
    @State private var updateView: Bool = false
    
    @State private var metalViewIndex: Double = 1
    @State private var helpViewIndex: Double = 0
    
    func showMetal() {
        metalViewIndex = 1
        helpViewIndex = 0
    }

    var body: some View {
        NavigationView() {
            GeometryReader { g in
                ScrollView {
                    if let current = document.game.assetFolder.current {
                        if current.type != .Image {
                            WebView(document.game).tabItem {
                            }
                            .frame(height: g.size.height)
                            .tag(1)
                            .onReceive(self.document.game.javaScriptErrorOccured) { state in
                                self.updateView.toggle()
                            }
                        } else {
                            #if os(OSX)
                            let image = NSImage(data: current.data[0])!
                            #else
                            let image = UIImage(data: current.data[0])!
                            #endif
                            VStack {
                                #if os(OSX)
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                #else
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                #endif
                                HStack {
                                    Spacer()
                                    Text("Width: \(Int(image.size.width))")
                                    Spacer()
                                    Text("Height: \(Int(image.size.height))")
                                    Spacer()
                                }.padding()
                            }
                            
                        }
                    }
                }.frame(height: g.size.height)
            }.frame(minWidth: 300)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu(document.game.currentName) {
                        Section(header: Text("Current Project")) {
                            
                        }
                        Menu("Scripts")
                        {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                
                                if asset.type == .JavaScript {
                                    Button(asset.name, action: {
                                        self.document.game.assetFolder.select(asset.id)
                                        updateView.toggle()
                                    })
                                }
                            }
                        }
                        Menu("Shader")
                        {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Shader {
                                    Button(asset.name, action: {
                                        document.game.assetFolder.select(asset.id)
                                        document.game.createPreview(asset)
                                        updateView.toggle()
                                    })
                                }
                            }
                        }
                        Menu("Images")
                        {
                            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                if asset.type == .Image {
                                    Button(asset.name, action: {
                                        document.game.assetFolder.select(asset.id)
                                        updateView.toggle()
                                    })
                                }
                            }
                        }
                        Divider()
                        Button("Rename Asset", action: {
                            if let asset = document.game.assetFolder.current {
                                assetName = String(asset.name.split(separator: ".")[0])
                                showAssetNamePopover = true
                            }
                        })
                    }.frame(minWidth: 150)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Menu("Script") {
                            Button("Object Script", action: {
                                document.game.assetFolder.addScript("New Script")
                                if let asset = document.game.assetFolder.current {
                                    assetName = String(asset.name.split(separator: ".")[0])
                                    //showAssetNamePopover = true
                                }
                            })
                            Button("Empty Script", action: {
                                document.game.assetFolder.addScript("New Script")
                                if let asset = document.game.assetFolder.current {
                                    assetName = String(asset.name.split(separator: ".")[0])
                                    //showAssetNamePopover = true
                                }
                            })
                        }
                        Button("Shader", action: {
                            document.game.assetFolder.addShader("New Shader")
                            if let asset = document.game.assetFolder.current {
                                assetName = String(asset.name.split(separator: ".")[0])
                                //showAssetNamePopover = true
                                document.game.createPreview(asset)
                            }
                        })
                        Button("Image", action: {
                            #if os(OSX)
                            
                            let openPanel = NSOpenPanel()
                            openPanel.canChooseFiles = true
                            openPanel.allowsMultipleSelection = true
                            openPanel.canChooseDirectories = false
                            openPanel.canCreateDirectories = false
                            openPanel.title = "Select Image(s)"
                            //openPanel.directoryURL =  containerUrl
                            openPanel.showsHiddenFiles = false
                            //openPanel.allowedFileTypes = [appExtension]
                            
                            openPanel.beginSheetModal(for:document.game.view.window!) { (response) in
                                if response == NSApplication.ModalResponse.OK {
                                    document.game.assetFolder.addImage(openPanel.url!.deletingPathExtension().lastPathComponent, openPanel.url!)
                                    
                                    if let asset = document.game.assetFolder.current {
                                        assetName = String(asset.name.split(separator: ".")[0])
                                        //showAssetNamePopover = true
                                    }
                                }
                                openPanel.close()
                            }
                            #endif
                        })
                    }
                    label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            // Popover for asset name
            .popover(isPresented: self.$showAssetNamePopover,
                     arrowEdge: .top
            ) {
                VStack(alignment: .leading) {
                    Text("Name")
                    TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                        if let asset = document.game.assetFolder.current {
                            if asset.type == .JavaScript {
                                asset.name = assetName + ".js"
                            } else
                            if asset.type == .Shader {
                                asset.name = assetName + ".sh"
                            } else {
                                asset.name = assetName
                            }
                            document.game.currentName = asset.name
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            ZStack() {
                HelpWebView()
                    .zIndex(helpViewIndex)
                MetalView(document.game)
                    .zIndex(metalViewIndex)
                    .frame(minWidth: 500)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigation) {
                            Button(action: {
                                document.game.start()
                                showMetal()
                                updateView.toggle()
                            })
                            {
                                Label("Run", systemImage: "play")
                            }
                            .keyboardShortcut("r")
                            Button(action: {
                                document.game.stop()
                                updateView.toggle()
                            }) {
                                Label("Stop", systemImage: "stop")
                            }.keyboardShortcut("t")
                            .disabled(!document.game.isRunning)
                            Button(action: {
                                if let asset = document.game.assetFolder.current {
                                    document.game.createPreview(asset)
                                }
                            }) {
                                Label("Update", systemImage: "arrow.counterclockwise")
                            }.keyboardShortcut("u")
                            .disabled(document.game.isRunning || document.game.assetFolder.current?.type != .Shader )
                        }
                        ToolbarItemGroup(placement: .automatic) {
                            Button(helpViewIndex == 0 ? "Help" : "Hide", action: {
                                if helpViewIndex == 0 {
                                    helpViewIndex = 1
                                    metalViewIndex = 0
                                } else {
                                    helpViewIndex = 0
                                    metalViewIndex = 1
                                }
                            })
                            .keyboardShortcut("h")
                        }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(DenrimDocument()))
    }
}
