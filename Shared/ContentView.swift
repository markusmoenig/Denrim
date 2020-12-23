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

/*
struct GroupView: View {
    @State var document                 : DenrimDocument
    @State var group                    : AssetGroup
    @Binding var updateView             : Bool

    @Binding var showAssetNamePopover   : Bool
    @Binding var assetName              : String
    @Binding var assetGroup             : AssetGroup?
    
    @Binding var showDeleteAssetAlert   : Bool

    @Binding var isAddingImages         : Bool
    @Binding var imageIndex             : Double
        
    @State private var isExpanded       : Bool = false

    var body: some View {
        DisclosureGroup(group.name, isExpanded: $isExpanded) {
            ForEach(document.game.assetFolder.assets, id: \.id) { asset in
                if asset.groupId == group.id {
                    Button(action: {
                        document.game.assetFolder.select(asset.id)
                        document.game.createPreview(asset)
                        updateView.toggle()
                    })
                    {
                        Label(asset.name, systemImage: document.game.assetFolder.getSystemName(asset.id))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .contextMenu {
                        Section(header: Text("Move to Folder")) {
                            Button(action: {
                                asset.groupId = nil
                                updateView.toggle()
                            }) {
                                Text("Root")
                            }
                            ForEach(document.game.assetFolder.groups, id: \.id) { group in
                                Button(action: {
                                    asset.groupId = group.id
                                    updateView.toggle()
                                }) {
                                    Text(group.name)
                                    if asset.groupId == group.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        Section(header: Text("Edit")) {
                            Button(action: {
                                assetName = asset.name
                                assetGroup = nil
                                showAssetNamePopover = true
                            })
                            {
                                Text("Rename")//, systemImage: "pencil")
                            }
                            .disabled(asset.name == "Game" && asset.type == .Behavior)
                            
                            Button(action: {
                                showDeleteAssetAlert = true
                            })
                            {
                                Label("Remove", systemImage: "minus")
                            }
                            .disabled(asset.name == "Game" && asset.type == .Behavior)
                            
                            Button(action: {
                                for asset in document.game.assetFolder.assets {
                                    if asset.groupId == group.id {
                                        asset.groupId = nil
                                    }
                                }
                                
                                document.game.assetFolder.groups.removeAll{$0.id == group.id}
                                updateView.toggle()
                            })
                            {
                                Text("Collapse Folder")
                            }
                        }
                        if asset.type == .Image {
                            Section(header: Text("Image Group")) {
                                Button(action: {
                                    isAddingImages = true
                                })
                                {
                                    Label("Add to Group", systemImage: "plus")
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
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Group {
                        if document.game.assetFolder.current!.id == asset.id {
                            Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                        } else { Color.clear }
                    })
                }
            }
            // delete action
            .onDelete { indexSet in
                for index in indexSet {
                    if document.game.assetFolder.assets[index].name != "Game" {
                        document.game.assetFolder.assets.remove(at: index)
                    }
                }
            }
            // move action
            .onMove { indexSet, newOffset in
                document.game.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
                updateView.toggle()
            }
        }
    }
}

struct RootView: View {
    @State var document                 : DenrimDocument
    @Binding var updateView             : Bool
    
    @Binding var showAssetNamePopover   : Bool
    @Binding var assetName              : String
    @Binding var assetGroup             : AssetGroup?

    @Binding var showDeleteAssetAlert   : Bool

    @Binding var isAddingImages         : Bool
    @Binding var imageIndex             : Double

    var body: some View {
        
        ForEach(document.game.assetFolder.assets, id: \.id) { asset in
            if asset.groupId == nil {
                Button(action: {
                    document.game.assetFolder.select(asset.id)
                    document.game.createPreview(asset)
                    
                    updateView.toggle()
                })
                {
                    Label(asset.name, systemImage: document.game.assetFolder.getSystemName(asset.id))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .contextMenu {
                    Section(header: Text("Move to Folder")) {
                        ForEach(document.game.assetFolder.groups, id: \.id) { group in
                            Button(action: {
                                asset.groupId = group.id
                                updateView.toggle()
                            }) {
                                Text(group.name)
                            }
                            .disabled(asset.name == "Game" && asset.type == .Behavior)
                        }
                    }
                    Section(header: Text("Edit")) {
                        Button(action: {
                            assetName = asset.name
                            assetGroup = nil
                            showAssetNamePopover = true
                        })
                        {
                            Label("Rename", systemImage: "pencil")
                        }
                        .disabled(asset.name == "Game" && asset.type == .Behavior)
                        
                        Button(action: {
                            showDeleteAssetAlert = true
                        })
                        {
                            Label("Remove", systemImage: "minus")
                        }
                        .disabled(asset.name == "Game" && asset.type == .Behavior)
                    }
                    
                    if asset.type == .Image {
                        Section(header: Text("Image Group")) {
                            Button(action: {
                                isAddingImages = true
                            })
                            {
                                Label("Add to Group", systemImage: "plus")
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
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Group {
                    if document.game.assetFolder.current!.id == asset.id {
                        Color.gray.mask(RoundedRectangle(cornerRadius: 4))
                    } else { Color.clear }
                })
            }
        }
        // delete action
        .onDelete { indexSet in
            for index in indexSet {
                if document.game.assetFolder.assets[index].name != "Game" {
                    document.game.assetFolder.assets.remove(at: index)
                }
            }
        }
        // move action
        .onMove { indexSet, newOffset in
            document.game.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
            updateView.toggle()
        }
    }
}
*/

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

struct ListView: View {
    @State var document                 : DenrimDocument
    
    @Binding var selection              : UUID?
    @Binding var updateView             : Bool
    
    @Binding var showAssetNamePopover   : Bool
    @Binding var assetName              : String

    @Binding var showDeleteAssetAlert   : Bool

    @Binding var isAddingImages         : Bool
    @Binding var imageIndex             : Double

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
        // Selection handling
        .onChange(of: selection) { newState in
            if let id = newState {
                document.game.assetFolder.select(id)
                if let asset = document.game.assetFolder.getAssetById(id) {
                    document.game.createPreview(asset)
                }
                updateView.toggle()
            }
        }
        .onAppear {
            if let asset = document.game.assetFolder.getAsset("Game") {
                document.game.assetFolder.select(asset.id)
                selection = asset.id
            }
        }
        /*
        // delete action
        .onDelete { indexSet in
            for index in indexSet {
                if document.game.assetFolder.assets[index].name != "Game" {
                    document.game.assetFolder.assets.remove(at: index)
                }
            }
        }
        // move action
        .onMove { indexSet, newOffset in
            document.game.assetFolder.assets.move(fromOffsets: indexSet, toOffset: newOffset)
            updateView.toggle()
        }
        */
    }
}

struct ContentView: View {
    @Binding var document: DenrimDocument
    
    @State private var showAssetNamePopover : Bool = false
    @State private var assetName: String    = ""

    @State private var updateView           : Bool = false

    @State private var helpIsVisible        : Bool = false
    @State private var helpText             : String = ""

    @State private var imageIndex           : Double = 0
    @State private var imageScale           : Double = 1

    @State private var showDeleteAssetAlert : Bool = false

    @State private var rightSideBarIsVisible: Bool = true

    @State private var isImportingImages    : Bool = false
    @State private var isImportingAudio     : Bool = false
    @State private var isAddingImages       : Bool = false
    
    @State private var showTemplates        : Bool = true

    @State private var contextText          : String = ""
    
    @State private var tempText             : String = ""

    @Environment(\.colorScheme) var deviceColorScheme: ColorScheme
    
    @State private var selection            : UUID? = nil
    
    #if os(macOS)
    let leftPanelWidth                      : CGFloat = 200
    let toolBarIconSize                     : CGFloat = 13
    let toolBarTopPadding                   : CGFloat = 0
    let toolBarSpacing                      : CGFloat = 4
    #else
    let leftPanelWidth                      : CGFloat = 250
    let toolBarIconSize                     : CGFloat = 16
    let toolBarTopPadding                   : CGFloat = 8
    let toolBarSpacing                      : CGFloat = 6
    #endif

    var body: some View {
        HStack {
        NavigationView() {
            VStack {
                HStack(spacing: toolBarSpacing) {
                    Button(action: {
                        document.game.assetFolder.addFolder("New Folder")
                        assetName = document.game.assetFolder.current!.name
                        showAssetNamePopover = true
                        updateView.toggle()
                    })
                    {
                        Label("", systemImage: "folder")
                            .font(.system(size: toolBarIconSize))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        document.game.assetFolder.addBehavior("New Behavior", path: document.game.assetFolder.genDestinationPath())
                        assetName = document.game.assetFolder.current!.name
                        showAssetNamePopover = true
                        updateView.toggle()
                    })
                    {
                        Label("", systemImage: "lightbulb")
                            .font(.system(size: toolBarIconSize))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        document.game.assetFolder.addMap("New Map", path: document.game.assetFolder.genDestinationPath())
                        assetName = document.game.assetFolder.current!.name
                        showAssetNamePopover = true
                        updateView.toggle()
                    })
                    {
                        Label("", systemImage: "list.and.film")
                            .font(.system(size: toolBarIconSize))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        document.game.assetFolder.addShader("New Shader", path: document.game.assetFolder.genDestinationPath())
                        if let asset = document.game.assetFolder.current {
                            assetName = document.game.assetFolder.current!.name
                            showAssetNamePopover = true
                            document.game.createPreview(asset)
                        }
                        updateView.toggle()
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
                }
                .padding(.top, toolBarTopPadding)
                .padding(.bottom, 2)
                Divider()
                ListView(document: document, selection: $selection, updateView: $updateView, showAssetNamePopover: $showAssetNamePopover, assetName: $assetName, showDeleteAssetAlert: $showDeleteAssetAlert, isAddingImages: $isAddingImages, imageIndex: $imageIndex )
            }
            .frame(minWidth: leftPanelWidth, idealWidth: leftPanelWidth, maxWidth: leftPanelWidth)
            .layoutPriority(0)
            // Asset deletion
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
                    }
                } catch {
                    // Handle failure.
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    ScrollView {

                        WebView(document.game, deviceColorScheme).tabItem {
                        }
                            .frame(height: geometry.size.height)
                            .tag(1)
                            .onChange(of: deviceColorScheme) { newValue in
                                document.game.scriptEditor?.setTheme(newValue)
                            }
                            .opacity(helpIsVisible ? 0 : 1)
                    }
                        .zIndex(0)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(2)
                    MetalView(document.game)
                        .zIndex(2)
                        .frame(minWidth: 0,
                               maxWidth: geometry.size.width / document.game.previewFactor,
                               minHeight: 0,
                               maxHeight: geometry.size.height / document.game.previewFactor,
                               alignment: .topTrailing)
                        .opacity(helpIsVisible || document.game.assetFolder.isPreviewVisible() == false ? 0 : (document.game.state == .Running ? 1 : document.game.previewOpacity))
                        .animation(.default)
                        //.allowsHitTesting(document.game.state == .Running)
                    
                    Text(tempText)
                        .zIndex(3)
                        .frame( minWidth: 0,
                                maxWidth: .infinity,
                                minHeight: 0,
                                maxHeight: geometry.size.height,
                                alignment: .bottomTrailing)
                        .opacity(tempText.count == 0 ? 0 : 1)
                        .onReceive(self.document.game.tempTextChanged) { state in
                            tempText = self.document.game.tempText
                        }
                    
                    ScrollView {
                        ParmaView(text: $helpText)
                            .frame(minWidth: 0,
                                   maxWidth: .infinity,
                                   minHeight: 0,
                                   maxHeight: .infinity,
                                   alignment: .topLeading)
                            .padding(4)
                            .animation(.default)
                            .onReceive(self.document.game.helpTextChanged) { state in
                                helpText = self.document.game.helpText
                            }
                    }
                    .zIndex(4)//helpIsVisible ? 4 : -1)
                    .opacity(helpIsVisible ? 1 : 0)
                    .animation(.default)
                }
            }
            .layoutPriority(2)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            .toolbar {
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
                        if let scriptEditor = document.game.scriptEditor {
                            scriptEditor.activateDebugSession()
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

                    Button(action: {
                        helpIsVisible.toggle()
                    }) {
                        Label("Help", systemImage: "questionmark")
                    }
                    .keyboardShortcut("h")
                    
                    Button(action: { rightSideBarIsVisible.toggle() }, label: {
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
            // Adding Images
            .fileImporter(
                isPresented: $isAddingImages,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                do {
                    let selectedFiles = try result.get()
                    if selectedFiles.count > 0 {
                        document.game.assetFolder.addImages(selectedFiles[0].deletingPathExtension().lastPathComponent, selectedFiles, existingAsset: document.game.assetFolder.current)

                        updateView.toggle()
                    }
                } catch {
                    // Handle failure.
                }
            }
        }
        if rightSideBarIsVisible == true {
            if helpIsVisible == true {
                HelpIndexView(document.game)
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                    .layoutPriority(0)
                    .animation(.easeInOut)
            } else
            if let asset = document.game.assetFolder.current {
                ScrollView {
                    if asset.type == .Image {
                        VStack {
                            if document.game.assetFolder.current!.data.count > 1 {
                                Text("Index \(Int(imageIndex))")
                                Slider(value: $imageIndex, in: 0...Double(document.game.assetFolder.current!.data.count-1), step: 1) { pressed in
                                    asset.dataIndex = Int(imageIndex)
                                    document.game.assetFolder.createPreview()
                                }
                                .padding(.horizontal)
                            }
                            Text("Scale \(String(format: "%.02f", imageScale))")
                            Slider(value: $imageScale, in: 0.25...4, step: 0.25) { pressed in
                                asset.dataScale = imageScale
                                document.game.assetFolder.createPreview()
                            }
                            .padding(.horizontal)
                        }
                        .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                        .layoutPriority(0)
                        .animation(.easeInOut)
                    } else {
                        ParmaView(text: $contextText)
                            .frame(minWidth: 0,
                                   maxWidth: .infinity,
                                   minHeight: 0,
                                   maxHeight: .infinity,
                                   alignment: .bottomLeading)
                            .padding(4)
                            .onReceive(self.document.game.contextTextChanged) { text in
                                contextText = text//self.document.game.contextText
                            }
                            .foregroundColor(Color.gray)
                            .font(.system(size: 12))
                            .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                            .layoutPriority(0)
                            .animation(.easeInOut)
                    }
                }
                .animation(.easeInOut)
            }
        }
        }
        // For Mac Screenshots, 1440x900
        //.frame(minWidth: 1440, minHeight: 806)
        //.frame(maxWidth: 1440, maxHeight: 806)
        // For Mac App Previews 1920x1080
        //.frame(minWidth: 1920, minHeight: 978)
        //.frame(maxWidth: 1920, maxHeight: 978)
        // Import Audio
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
                    updateView.toggle()
                }
            } catch {
                // Handle failure.
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(DenrimDocument()))
    }
}
