//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

#if os(OSX)
var toolbarPlacement1 : ToolbarItemPlacement = .navigation

#else
var toolbarPlacement1 : ToolbarItemPlacement = .navigationBarLeading
#endif

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

    @State private var showBehaviorItems: Bool = true
    @State private var showMapItems: Bool = false
    @State private var showShaderItems: Bool = false
    @State private var showImageItems: Bool = false

    @State private var helpText: String = ""

    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme
    
    var body: some View {
        NavigationView() {
            List {
                #if os(OSX)
                Section(header: Text("Behavior")) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Behavior {
                            Button(action: {
                                document.game.assetFolder.select(asset.id)
                                document.game.createPreview(asset)
                                scriptIsVisible = true
                                updateView.toggle()
                            })
                            {
                                Text(asset.name)
                                //Label(asset.name, systemImage: "x.circle.fill")
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(document.game.assetFolder.current === asset ? Color.accentColor : Color.primary)
                        }
                    }
                }
                Section(header: Text("Map Files")) {
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
                #else
                //Section(header: Text("Behavior")) {
                DisclosureGroup("Behavior", isExpanded: $showBehaviorItems) {
                    ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                        if asset.type == .Behavior {
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
                DisclosureGroup("Map Files", isExpanded: $showMapItems) {
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
                DisclosureGroup("Shaders", isExpanded: $showShaderItems) {
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
                DisclosureGroup("Image Groups", isExpanded: $showImageItems) {
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
                #endif
            }
            .frame(minWidth: 140, idealWidth: 200)
            .layoutPriority(0)
            // Asset deletion
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
            // Edit Asset name
            .popover(isPresented: self.$showAssetNamePopover,
                     arrowEdge: .top
            ) {
                VStack(alignment: .leading) {
                    Text("Name")
                    TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                        if let asset = document.game.assetFolder.current {
                            asset.name = assetName
                            self.updateView.toggle()
                        }
                    })
                    .frame(minWidth: 200)
                }.padding()
            }
            /*
            GeometryReader { g in
                ScrollView {
                    if let current = document.game.assetFolder.current {
                        ZStack {
                            WebView(document.game, deviceColorScheme).tabItem {
                            }
                            .zIndex(scriptIsVisible ? 1 : 0)
                            .frame(height: g.size.height)
                            .tag(1)
                            /*
                            .onReceive(self.document.game.compileErrorOccured) { state in
                                
                                if let asset = self.document.game.error.asset {
                                    document.game.assetFolder.select(asset.id)
                                }
                                
                                if self.document.game.error.error != nil {
                                    self.document.game.scriptEditor?.setError(self.document.game.error)
                                }
                                self.updateView.toggle()
                            }*/
                            .onChange(of: deviceColorScheme) { newValue in
                                document.game.scriptEditor?.setTheme(newValue)
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
            .frame(minWidth: 300, maxWidth: .infinity)*/
            
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    ScrollView {

                        WebView(document.game, deviceColorScheme).tabItem {
                        }
                            .frame(height: geometry.size.height)
                            .tag(1)
                    }
                        .zIndex(0)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(2)
                    Text(helpText)
                        .zIndex(1)
                        .background(Color.gray)
                        .opacity(0.8)
                        .frame(minWidth: 0,
                               maxWidth: .infinity,
                               minHeight: 0,
                               maxHeight: .infinity,
                               alignment: .bottomLeading)
                        .onReceive(self.document.game.helpTextChanged) { state in
                            helpText = self.document.game.helpText
                        }
                    MetalView(document.game)
                        .zIndex(2)
                        .frame(minWidth: 0,
                               maxWidth: geometry.size.width / document.game.previewFactor,
                               minHeight: 0,
                               maxHeight: geometry.size.height / document.game.previewFactor,
                               alignment: .topTrailing)
                        .opacity(document.game.state == .Running ? 1 : document.game.previewOpacity)
                        .animation(.default)
                
                    VStack {
                        if document.game.assetFolder.current!.type == .Image {
                            HStack {
                                if document.game.assetFolder.current!.data.count >= 2 {
                                    Text("Index " + String(Int(imageIndex)))
                                    Slider(value: $imageIndex, in: 0...Double(document.game.assetFolder.current!.data.count-1), step: 1)
                                    .padding()
                                }
                            }
                            .padding()
                            #if os(OSX)
                            let image = NSImage(data: document.game.assetFolder.current!.data[Int(imageIndex)])!
                            #else
                            let image = UIImage(data: document.game.assetFolder.current!.data[Int(imageIndex)])!
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
                    .zIndex(scriptIsVisible ? 0 : 2)
                    .background(Color.gray)
                    HelpWebView()
                        .zIndex(helpIsVisible ? 4 : -1)
                        .frame(minWidth: 0,
                               maxWidth: .infinity,
                               minHeight: 0,
                               maxHeight: .infinity)
                }
            }
            .layoutPriority(2)
            .toolbar {
                ToolbarItemGroup(placement: toolbarPlacement1) {
                    Menu {
                        Menu("Behavior") {
                            Button("Object 2D", action: {
                                document.game.assetFolder.addBehaviorTree("New Object 2D")
                                updateView.toggle()
                            })
                        }
                        Button("Map File", action: {
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
                        Text(" Asset")//.foregroundColor(Color.gray)
                        Label("Add", systemImage: "plus")
                    }
                    
                    // Optional toolbar items depending on asset
                    if let asset = document.game.assetFolder.current {
                        
                        Button(action: {
                            assetName = String(asset.name.split(separator: ".")[0])
                            showAssetNamePopover = true
                        })
                        {
                            Label("Rename", systemImage: "pencil")//rectangle.and.pencil.and.ellipsis")
                        }
                        .disabled(asset.name == "Game")
                        
                        if asset.type == .Behavior || asset.type == .Shader {
                            Button(action: {
                                showDeleteAssetAlert = true
                            })
                            {
                                Label("Remove", systemImage: "minus")
                            }
                            .disabled(asset.name == "Game")
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
                ToolbarItemGroup(placement: .automatic) {
                                    
                    // Game Controls
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
                        //Text("Preview")
                        Label("View", systemImage: "viewfinder")
                    }
                    
                    // Documentation
                    Button(action: {
                        helpIsVisible.toggle()
                    }) {
                        //Text(!helpIsVisible ? "Help" : "Hide")
                        Label("Help", systemImage: "questionmark")
                    }
                    .keyboardShortcut("h")
                }
            }
            /*
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
            }
            .layoutPriority(2)
            */
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(DenrimDocument()))
    }
}
