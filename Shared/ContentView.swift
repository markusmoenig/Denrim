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

    @State private var scriptIsVisible: Bool = true
    @State private var helpIsVisible: Bool = false

    @State private var imageIndex: Double = 0
    
    @State private var showDeleteAssetAlert: Bool = false

    var body: some View {
        NavigationView() {
            NavigationView() {
                List {
                    Section(header: Text("Scripts")) {
                        ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                            if asset.type == .JavaScript {
                                Button(action: {
                                    document.game.assetFolder.select(asset.id)
                                    document.game.createPreview(asset)
                                    scriptIsVisible = true
                                    updateView.toggle()
                                })
                                {
                                    Text(asset.name)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                            }
                        }
                    }
                    Section(header: Text("Maps")) {
                        ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                            if asset.type == .Map {
                                Button(action: {
                                    document.game.assetFolder.select(asset.id)
                                    document.game.createPreview(asset)
                                    scriptIsVisible = false
                                    updateView.toggle()
                                })
                                {
                                    Text(asset.name)

                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                            }
                        }
                    }
                    Section(header: Text("Shaders")) {
                        ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                            if asset.type == .Shader {
                                Button(action: {
                                    document.game.assetFolder.select(asset.id)
                                    document.game.createPreview(asset)
                                    scriptIsVisible = true
                                    updateView.toggle()
                                })
                                {
                                    Text(asset.name)

                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                            }
                        }
                    }
                    Section(header: Text("Image Groups")) {
                        ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                            if asset.type == .Image {
                                Button(action: {
                                    document.game.assetFolder.select(asset.id)
                                    document.game.createPreview(asset)
                                    scriptIsVisible = false
                                    updateView.toggle()
                                })
                                {
                                    Text(asset.name)

                                }
                                .buttonStyle(PlainButtonStyle())
                                .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                            }
                        }
                    }
                }
                .frame(minWidth: 120, idealWidth: 200)
                .layoutPriority(0)
            }
            .navigationSubtitle("Assets")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Menu {
                        Menu("Script") {
                            Button("Object Script", action: {
                                document.game.assetFolder.addScript("New Script")
                                updateView.toggle()
                            })
                            Button("Empty Script", action: {
                                document.game.assetFolder.addScript("New Script")
                                updateView.toggle()
                            })
                        }
                        Button("Map", action: {
                            document.game.assetFolder.addMap("New Map")
                            updateView.toggle()
                        })
                        Button("Shader", action: {
                            document.game.assetFolder.addShader("New Shader")
                            if let asset = document.game.assetFolder.current {
                                //assetName = String(asset.name.split(separator: ".")[0])
                                //showAssetNamePopover = true
                                document.game.createPreview(asset)
                            }
                            updateView.toggle()
                        })
                        Button("Image(s)", action: {
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
                                    if openPanel.url != nil {
                                        document.game.assetFolder.addImages(openPanel.url!.deletingPathExtension().lastPathComponent, openPanel.urls)
                                        
                                        //if let asset = document.game.assetFolder.current {
                                            //assetName = String(asset.name.split(separator: ".")[0])
                                            //showAssetNamePopover = true
                                        //}
                                        scriptIsVisible = false
                                        updateView.toggle()
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
            GeometryReader { g in
                ScrollView {
                    if let current = document.game.assetFolder.current {
                        ZStack {
                            WebView(document.game).tabItem {
                            }
                            .zIndex(scriptIsVisible ? 1 : 0)
                            .frame(height: g.size.height)
                            .tag(1)
                            .onReceive(self.document.game.javaScriptErrorOccured) { state in
                                
                                if let asset = self.document.game.jsError.asset {
                                    document.game.assetFolder.select(asset.id)
                                }
                                
                                if self.document.game.jsError.error != nil {
                                    self.document.game.scriptEditor?.setError(self.document.game.jsError)
                                }
                                self.updateView.toggle()
                            }
                            VStack {
                                if current.type == .Image {
                                    HStack {
                                        if current.data.count >= 2 {
                                            Text("Index " + String(Int(imageIndex)))
                                            Slider(value: $imageIndex, in: 0...Double(current.data.count-1), step: 1)
                                            .padding()
                                        }
                                    }
                                    .padding()
                                    #if os(OSX)
                                    let image = NSImage(data: current.data[Int(imageIndex)])!
                                    #else
                                    let image = UIImage(data: current.data[Int(imageIndex)])!
                                    #endif
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

                                    Spacer()
                                }
                            }
                            .zIndex(scriptIsVisible ? 0 : 1)
                            .background(Color.gray)
                        }
                    }
                }.frame(height: g.size.height)
            }
            .frame(minWidth: 300)
            .layoutPriority(2)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    
                    // Optional toolbar items depending on asset
                    if let asset = document.game.assetFolder.current {
                        
                        Button(action: {
                            assetName = String(asset.name.split(separator: ".")[0])
                            showAssetNamePopover = true
                        })
                        {
                            Label("Rename", systemImage: "pencil")//rectangle.and.pencil.and.ellipsis")
                        }
                        .disabled(asset.name == "Game.js")
                        
                        if asset.type == .JavaScript || asset.type == .Shader {
                            Button(action: {
                                showDeleteAssetAlert = true
                            })
                            {
                                Label("Remove Script", systemImage: "minus")
                            }
                            .disabled(asset.name == "Game.js")
                        } else
                        if asset.type == .Image {
                            Button(action: {
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
                                        if openPanel.url != nil {
                                            document.game.assetFolder.addImages(openPanel.url!.deletingPathExtension().lastPathComponent, openPanel.urls, existingAsset: document.game.assetFolder.current)
                                            scriptIsVisible = false
                                            updateView.toggle()
                                        }
                                    }
                                    openPanel.close()
                                }
                                #endif
                            })
                            {
                                Label("Add to Group", systemImage: "plus")
                            }
                            
                            Button(action: {
                                showDeleteAssetAlert = true
                            })
                            {
                                Label("Remove Image Group", systemImage: "minus")
                            }
                            
                            Button(action: {
                                if let asset = document.game.assetFolder.current {
                                    asset.data.remove(at: Int(imageIndex))
                                }
                                updateView.toggle()
                            })
                            {
                                Label("Remove Image", systemImage: "minus.circle")
                            }
                            .disabled(document.game.assetFolder.current == nil || document.game.assetFolder.current!.data.count < 2)
                        }
                    }
                }
            }
            .alert(isPresented: $showDeleteAssetAlert) {
                Alert(
                    title: Text("Do you want to delete the asset?"),
                    message: Text("This action cannot be undone!"),
                    primaryButton: .destructive(Text("Yes"), action: {
                        if let asset = document.game.assetFolder.current {
                            if let index = document.game.assetFolder.assets.firstIndex(of: asset) {
                                document.game.assetFolder.assets.remove(at: index)
                                document.game.assetFolder.select(document.game.assetFolder.assets[0].id)
                                self.updateView.toggle()
                            }
                        }
                    }),
                    secondaryButton: .cancel(Text("No"), action: {})
                )
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
                            self.updateView.toggle()
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            ZStack() {
                HelpWebView()
                    .zIndex(helpIsVisible ? 1 : 0)
                MetalView(document.game)
                    .zIndex(helpIsVisible ? 0 : 1)
                    .frame(minWidth: 200)
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            Button(action: {
                                document.game.stop()
                                document.game.start()
                                helpIsVisible = false
                                updateView.toggle()
                            })
                            {
                                Label("Run", systemImage: "play.fill")
                            }
                            .keyboardShortcut("r")
                            Button(action: {
                                document.game.stop()
                                updateView.toggle()
                            }) {
                                Label("Stop", systemImage: "stop.fill")
                            }.keyboardShortcut("t")
                            .disabled(document.game.state == .Idle)
                            Button(action: {
                                if let asset = document.game.assetFolder.current {
                                    document.game.createPreview(asset)
                                }
                            }) {
                                Label("Update", systemImage: "arrow.counterclockwise")
                            }.keyboardShortcut("u")
                            .disabled(document.game.state == .Running || document.game.assetFolder.current?.type != .Shader )
                            Spacer()
                            Button(!helpIsVisible ? "Help" : "Hide", action: {
                                helpIsVisible.toggle()
                            })
                            .keyboardShortcut("h")
                        }
                    }
            }.layoutPriority(2)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(DenrimDocument()))
    }
}
