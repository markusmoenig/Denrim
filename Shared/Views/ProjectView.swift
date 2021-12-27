//
//  ProjectView.swift
//  Denrim
//
//  Created by Markus Moenig on 23/12/21.
//

import SwiftUI

#if os(macOS)
    let leftPanelWidth                      : CGFloat = 220
    let toolBarIconSize                     : CGFloat = 13
    let toolBarTopPadding                   : CGFloat = 0
    let toolBarSpacing                      : CGFloat = 4
#else
    let leftPanelWidth                      : CGFloat = 270
    let toolBarIconSize                     : CGFloat = 16
    let toolBarTopPadding                   : CGFloat = 8
    let toolBarSpacing                      : CGFloat = 6
#endif

struct ProjectView: View {
    
    @State var document                                 : DenrimDocument

    @State private var selection                        : UUID? = nil

    @State private var showAssetNamePopover             : Bool = false
    @State private var assetName                        = ""

    @State private var showDeleteAssetAlert             : Bool = false

    @State private var isAddingImages                   : Bool = false
    @State private var isImportingImages                : Bool = false
    @State private var isImportingAudio                 : Bool = false
    
    @State private var imageIndex                       : Double = 0

    var body: some View {

        HStack(spacing: toolBarSpacing) {
            Button(action: {
                document.game.assetFolder.addFolder("New Folder")
                selection = document.game.assetFolder.current!.id
                assetName = document.game.assetFolder.current!.name
                showAssetNamePopover = true
            })
            {
                Label("", systemImage: "folder")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                document.game.assetFolder.addBehavior("New Behavior", path: document.game.assetFolder.genDestinationPath())
                selection = document.game.assetFolder.current!.id
                assetName = document.game.assetFolder.current!.name
                showAssetNamePopover = true
            })
            {
                Label("", systemImage: "lightbulb")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                document.game.assetFolder.addLua("New Lua Script", path: document.game.assetFolder.genDestinationPath())
                selection = document.game.assetFolder.current!.id
                assetName = document.game.assetFolder.current!.name
                showAssetNamePopover = true
            })
            {
                Label("", systemImage: "paperplane")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                document.game.assetFolder.addMap("New Map", path: document.game.assetFolder.genDestinationPath())
                selection = document.game.assetFolder.current!.id
                assetName = document.game.assetFolder.current!.name
                showAssetNamePopover = true
            })
            {
                Label("", systemImage: "list.and.film")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())
            
            /*
            Button(action: {
                document.game.assetFolder.addShape("New Shape", path: document.game.assetFolder.genDestinationPath())
                selection = document.game.assetFolder.current!.id
                assetName = document.game.assetFolder.current!.name
                showAssetNamePopover = true
            })
            {
                Label("", systemImage: "cube")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())
            */

            Button(action: {
                document.game.assetFolder.addShader("New Shader", path: document.game.assetFolder.genDestinationPath())
                if let asset = document.game.assetFolder.current {
                    selection = document.game.assetFolder.current!.id
                    assetName = document.game.assetFolder.current!.name
                    showAssetNamePopover = true
                    document.game.createPreview(asset)
                }
            })
            {
                Label("", systemImage: "fx")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                isImportingImages = true
            })
            {
                Label("", systemImage: "photo.on.rectangle")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                isImportingAudio = true
            })
            {
                Label("", systemImage: "waveform")
                    .font(.system(size: toolBarIconSize))
            }
            .buttonStyle(PlainButtonStyle())
            .fileImporter(
                isPresented: $isImportingAudio,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                do {
                    let selectedFiles = try result.get()
                    if selectedFiles.count > 0 {
                        document.game.assetFolder.addAudio(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles)
                        assetName = document.game.assetFolder.current!.name
                        showAssetNamePopover = true
                        document.game.contentChanged.send()
                    }
                } catch {
                    // Handle failure.
                }
            }
        }
        .padding(.top, toolBarTopPadding)
        .padding(.bottom, 2)
        
        Divider()

        List(document.game.assetFolder.assets, id: \.id, children: \.children, selection: $selection) { asset in
            
            Label(asset.name, systemImage: document.game.assetFolder.getSystemName(asset.id))
            #if os(iOS)
                .foregroundColor(asset === document.game.assetFolder.current ? Color.accentColor : Color.white)
            #endif
            
            .onTapGesture {
                selection = asset.id
                document.game.assetFolder.select(asset.id)
                document.game.createPreview(asset)
                document.game.isShowingImage.send(asset.type == .Image)
            }
            
            .contextMenu {
                
                Section(header: Text("Move to Folder")) {
                    
                    Button(action: {
                        selection = asset.id
                        document.game.assetFolder.select(asset.id)
                        
                        document.game.assetFolder.moveToFolder(folderName: nil, asset: asset)
                    }) {
                        Text("Root")
                        if document.game.assetFolder.isInsideRoot(asset) {
                            Image(systemName: "checkmark")
                        }
                    }
                    .disabled(document.game.assetFolder.isFolder(asset))
                    
                    ForEach(document.game.assetFolder.assets, id: \.id) { folder in
                        if folder.type == .Folder {
                            Button(action: {
                                selection = asset.id
                                document.game.assetFolder.select(asset.id)
                                
                                document.game.assetFolder.moveToFolder(folderName: folder.name, asset: asset)
                            }) {
                                Text(folder.name)
                                if asset.path == folder.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .disabled(document.game.assetFolder.isFolder(asset))
                        }
                    }
                }
                
                Section(header: Text("Edit")) {
                    
                    Button(action: {
                        selection = nil
                        selection = asset.id
                        document.game.assetFolder.select(asset.id)
                        
                        assetName = asset.name
                        showAssetNamePopover = true
                    })
                    {
                        Label("Rename", systemImage: "pencil")
                    }
                    .disabled(document.game.assetFolder.isGameAsset(asset))
                    
                    Button(action: {
                        selection = asset.id
                        document.game.assetFolder.select(asset.id)
                        
                        showDeleteAssetAlert = true
                    })
                    {
                        Label("Remove", systemImage: "minus")
                    }
                    .disabled(document.game.assetFolder.isGameAsset(asset))
                }
                
                //if document.game.assetFolder.isImage(asset) == true {
                    
                    Section(header: Text("Image Group")) {
                        Button(action: {
                            selection = asset.id
                            document.game.assetFolder.select(asset.id)
                            
                            isAddingImages = true
                        })
                        {
                            Label("Add to Image Group", systemImage: "plus")
                        }
                        .disabled(document.game.assetFolder.isImage(asset) == false)
                        .fileImporter(
                            isPresented: $isAddingImages,
                            allowedContentTypes: [.item],
                            allowsMultipleSelection: true
                        ) { result in
                            do {
                                let selectedFiles = try result.get()
                                if selectedFiles.count > 0 {
                                    document.game.assetFolder.addImages(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles, existingAsset: document.game.assetFolder.current)

                                    selection = nil
                                    document.game.contentChanged.send()
                                    selection = asset.id
                                }
                            } catch {
                                // Handle failure.
                            }
                        }
                        
                        Button(action: {
                            selection = asset.id
                            document.game.assetFolder.select(asset.id)
                            
                            if let asset = document.game.assetFolder.current {
                                asset.data.remove(at: Int(imageIndex))
                            }
                        })
                        {
                            Label("Remove Image", systemImage: "minus.circle")
                        }
                        .disabled(document.game.assetFolder.isImage(asset) == false || document.game.assetFolder.current == nil || document.game.assetFolder.current!.data.count < 2)
                    }
                    
                //}
            }
        }
        
        .alert(isPresented: $showDeleteAssetAlert) {
            Alert(
                title: Text(document.game.assetFolder.current != nil && document.game.assetFolder.current!.type != .Folder ? "Do you want to remove the file '\(document.game.assetFolder.current!.name)' ?" : "Do you want to remove the folder '\(document.game.assetFolder.current!.name)' and all of it's contents ?"),
                message: Text("This action cannot be undone!"),
                primaryButton: .destructive(Text("Yes"), action: {
                    if let asset = document.game.assetFolder.current {
                        document.game.assetFolder.removeAsset(asset, stopTimer: true)
                        for a in document.game.assetFolder.assets {
                            if a.type != .Folder {
                                document.game.assetFolder.select(a.id)
                            }
                        }
                    }
                }),
                secondaryButton: .cancel(Text("No"), action: {})
            )
        }
        
        // Rename
        .popover(isPresented: self.$showAssetNamePopover,
                 arrowEdge: .top
        ) {
            VStack(alignment: .leading) {
                Text("Name:")
                TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                    if let asset = document.game.assetFolder.current {
                        selection = nil
                        asset.name = assetName
                        document.game.assetFolder.sort()
                        selection = asset.id
                    }
                })
                .frame(minWidth: 200)
            }.padding()
        }
        
        // Import Images
        .fileImporter(
            isPresented: $isImportingImages,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            do {
                let selectedFiles = try result.get()
                if selectedFiles.count > 0 {
                    document.game.assetFolder.addImages(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles)
                    assetName = document.game.assetFolder.current!.name
                    showAssetNamePopover = true
                    document.game.contentChanged.send()
                }
            } catch {
                // Handle failure.
            }
        }

        
        // Selection handling
        .onChange(of: selection) { newState in
            if let id = newState {
                document.game.assetFolder.select(id)
                if let asset = document.game.assetFolder.getAssetById(id) {
                    document.game.createPreview(asset)
                }
                //updateView.toggle()
            }
        }
        .onAppear {
            if let asset = document.game.assetFolder.getAsset("Game") {
                document.game.assetFolder.select(asset.id)
                selection = asset.id
            }
        }
    }
}
