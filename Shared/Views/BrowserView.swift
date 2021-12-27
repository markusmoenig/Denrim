//
//  Browser.swift
//  Denrim
//
//  Created by Markus Moenig on 25/12/20.
//

import SwiftUI

class BrowserItem {
    
    let id          = UUID()
    let name        : String
    let path        : String
    let description : String

    init(_ name: String, path: String, description: String = "")
    {
        self.name = name
        self.path = path
        self.description = description
    }
}

struct BrowserView: View {
    
    let game                        : Game
    
    var items                       : [BrowserItem] = []
    @State var selected             : BrowserItem? = nil
    @State var selectedText         : String = ""

    @Binding var updateView         : Bool
    @Binding var selection          : UUID?

    let columns = [
        GridItem(.fixed(140)),
        GridItem(.fixed(140)),
        GridItem(.fixed(140)),
    ]
    
    @State var text: String = "Hallo"
        
    init(_ game: Game, updateView: Binding<Bool>, selection: Binding<UUID?>)
    {
        self.game = game
        self._updateView = updateView
        self._selection = selection

        let item1 = BrowserItem("Simple Physics", path: "Simple Physics", description: "A simple physics example using instantiated, plain shapes")
        let item2 = BrowserItem("Space Shooter", path: "SpaceShooter", description: "A more complex space shooter using texturized shapes and physics")
        let item3 = BrowserItem("Jump And Run", path: "JumpAndRun", description: "A jump and run concept game demonstrating how to build the world from aliases")
        let item4 = BrowserItem("Bricks", path: "Bricks", description: "An arcade game build without physics and a shader based background")

        items.append(item1)
        items.append(item2)
        items.append(item3)
        items.append(item4)
        
        //_selected = State(initialValue: item1)
        _selectedText = State(initialValue: item1.description)
    }
    
    func load() {
        
        if selected == nil {
            selected = items[0]
        }
        
        if let selected = selected {
            if let json = game.file?.loadTemplate(selected.path) {
                if let jsonData = json.data(using: .utf8) {
                    if let assetFolder = try? JSONDecoder().decode(AssetFolder.self, from: jsonData) {
                        game.assetFolder = assetFolder
                        game.assetFolder.game = game
                        game.assetFolder.isNewProject = false
                        if let gameAsset = game.assetFolder.getAsset("Game", .Behavior) {
                            game.assetFolder.select(gameAsset.id)
                            selection = gameAsset.id
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        
        VStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(items, id: \.id) { item in
                        VStack{
                            Image("Logo")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .aspectRatio(contentMode: .fit)
                            Text(item.name)
                                .foregroundColor(item === selected || (selected == nil && item === items[0]) ? Color.accentColor : Color.primary)
                            
                        }
                        .onTapGesture(count: 2) {
                            load()
                            updateView.toggle()
                            //print("Double tapped!")
                        }
                        .onTapGesture(count: 1) {
                            selected = item
                            selectedText = item.description
                            //print("Single tapped!")
                        }

                    }
                }
                .padding(.horizontal)
                .padding(.top, 30)
                .onAppear {
                    //selected = items[0]
                }
            }

            Text(selectedText)
            
            Button(action: {
                load()
                updateView.toggle()
                game.projectLoaded.send()
            })
            {
                Text("  Load Project...  ")
                    .font(.system(size: 24))
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                    .frame(minWidth: 300)
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            .padding(.bottom, 30)
        }
    }
}
