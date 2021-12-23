//
//  ProjectView.swift
//  Denrim
//
//  Created by Markus Moenig on 23/12/21.
//

import SwiftUI

// https://stackoverflow.com/questions/61386877/in-swiftui-is-it-possible-to-use-a-modifier-only-for-a-certain-os-target
enum OperatingSystem {
    case macOS
    case iOS
    case tvOS
    case watchOS

    #if os(macOS)
    static let current = macOS
    #elseif os(iOS)
    static let current = iOS
    #elseif os(tvOS)
    static let current = tvOS
    #elseif os(watchOS)
    static let current = watchOS
    #else
    #error("Unsupported platform")
    #endif
}

extension View {
    @ViewBuilder
    func ifOS<Content: View>(
        _ operatingSystems: OperatingSystem...,
        modifier: @escaping (Self) -> Content
    ) -> some View {
        if operatingSystems.contains(OperatingSystem.current) {
            modifier(self)
        } else {
            self
        }
    }
}

struct ProjectView: View {
    
    @State var document                                 : DenrimDocument
    @Binding var updateView                             : Bool

    @State private var selection                        : UUID? = nil

    @State private var showAssetNamePopover             : Bool = false
    @State private var assetName                        = ""

    @State private var showDeleteAssetAlert             : Bool = false

    @State private var isAddingImages                   : Bool = false
    @State private var isImportingImages                : Bool = false
    @State private var isImportingAudio                 : Bool = false
    
    @State private var imageIndex                       : Double = 0

    var body: some View {
        List(document.game.assetFolder.assets, id: \.id, children: \.children, selection: $selection) { asset in
            
            Label(asset.name, systemImage: document.game.assetFolder.getSystemName(asset.id))
            .ifOS(.iOS) {
                $0.foregroundColor(asset === document.game.assetFolder.current ? Color.accentColor : Color.white)
            }
            .onTapGesture {
                selection = asset.id
                document.game.assetFolder.select(asset.id)
                document.game.createPreview(asset)
            }
            
            .contextMenu {
                
                if document.game.assetFolder.isFolder(asset) == false {
                    Section(header: Text("Move to Folder")) {
                        
                        Button(action: {
                            selection = asset.id
                            document.game.assetFolder.select(asset.id)
                            
                            document.game.assetFolder.moveToFolder(folderName: nil, asset: asset)
                            updateView.toggle()
                        }) {
                            Text("Root")
                            if document.game.assetFolder.isInsideRoot(asset) {
                                Image(systemName: "checkmark")
                            }
                        }
                        
                        ForEach(document.game.assetFolder.assets, id: \.id) { folder in
                            if folder.type == .Folder {
                                Button(action: {
                                    selection = asset.id
                                    document.game.assetFolder.select(asset.id)
                                    
                                    document.game.assetFolder.moveToFolder(folderName: folder.name, asset: asset)
                                    updateView.toggle()
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
                }
                
                Section(header: Text("Edit")) {
                    
                    Button(action: {
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
                        
                        Button(action: {
                            selection = asset.id
                            document.game.assetFolder.select(asset.id)
                            
                            if let asset = document.game.assetFolder.current {
                                asset.data.remove(at: Int(imageIndex))
                            }
                            updateView.toggle()
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
                        self.updateView.toggle()
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
                Text("Name:")
                TextField("Name", text: $assetName, onEditingChanged: { (changed) in
                    if let asset = document.game.assetFolder.current {
                        asset.name = assetName
                        document.game.assetFolder.sort()
                        self.updateView.toggle()
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
                    updateView.toggle()
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
