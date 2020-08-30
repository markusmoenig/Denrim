//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: DenrimDocument

    @State private var current: String = ""

    @State private var showAssetNamePopover: Bool = false
    @State private var assetName: String = ""

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
            }.frame(minWidth: 200)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button("Build") {
                            document.game.build()
                        }.keyboardShortcut("b")
                        Menu(document.game.current) {
                            Section(header: Text("Current Project")) {
                                
                            }
                            Menu("Scripts")
                            {
                                if document.game.changeCounter >= 0 {
                                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                        
                                        if asset.type == .JavaScript {
                                            Button(asset.name, action: {
                                                self.document.game.assetFolder.select(asset.id)
                                            })
                                        }
                                    }
                                }
                            }
                            Menu("Shader")
                            {
                                if document.game.changeCounter >= 0 {
                                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                        if asset.type == .Shader {
                                            Button(asset.name, action: {
                                                self.document.game.assetFolder.select(asset.id)
                                            })
                                        }
                                    }
                                }
                            }
                            Menu("Images")
                            {
                                if document.game.changeCounter >= 0 {
                                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                                        
                                        if asset.type == .Image {
                                            Button(asset.name, action: {
                                                self.document.game.assetFolder.select(asset.id)
                                            })
                                        }
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
                        }.frame(minWidth: 100)
                        // Menu for showing add actions
                        Menu {
                            Button("Script", action: {
                                document.game.assetFolder.addScript("New Script")
                                if let asset = document.game.assetFolder.current {
                                    assetName = String(asset.name.split(separator: ".")[0])
                                    showAssetNamePopover = true
                                }
                            })
                            Button("Shader", action: {
                                document.game.assetFolder.addShader("New Shader")
                            })
                            Button("Image", action: {
                                #if os(OSX)
                                
                                let openPanel = NSOpenPanel()
                                openPanel.canChooseFiles = true
                                openPanel.allowsMultipleSelection = false
                                openPanel.canChooseDirectories = false
                                openPanel.canCreateDirectories = false
                                openPanel.title = "Select Image"
                                //openPanel.directoryURL =  containerUrl
                                openPanel.showsHiddenFiles = false
                                //openPanel.allowedFileTypes = [appExtension]
                                
                                func load(url: URL) -> String
                                {
                                    var string : String = ""
                                    
                                    do {
                                        string = try String(contentsOf: url, encoding: .utf8)
                                    }
                                    catch {
                                        print(error.localizedDescription)
                                    }
                                    
                                    return string
                                }
                                
                                openPanel.beginSheetModal(for:document.game.view.window!) { (response) in
                                    if response == NSApplication.ModalResponse.OK {
                                        
                                        document.game.assetFolder.addImage(openPanel.url!.deletingPathExtension().lastPathComponent, openPanel.url!)
                                        /*
                                        let string = load(url: openPanel.url!)
                                        app.loadFrom(string)
                                        
                                        self.name = openPanel.url!.deletingPathExtension().lastPathComponent
                                        
                                        app.mmView.window!.title = self.name
                                        app.mmView.window!.representedURL = self.url()
                                        
                                        app.mmView.undoManager!.removeAllActions()*/
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
                            document.game.current = asset.name
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            MetalView(document.game).frame(minWidth: 200)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu("Documentation") {
                            Button("Game Object") {
                            }
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
