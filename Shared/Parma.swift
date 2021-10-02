//
//  Parma.swift
//  Denrim
//
//  Created by Markus Moenig on 29/10/20.
//

import SwiftUI
import MarkdownUI

struct HelpItem: Identifiable {
    var id          : String { name }

    let name        : String
    var children    : [HelpItem]?
    var image       : String? = nil
    var md          : String = ""
}

struct HelpIndexView: View {
    
    let game        : Game
    var helpItems   : [HelpItem] = []
    
    init(_ game: Game)
    {
        self.game = game
        let fileManager = FileManager.default

        var rootItem = HelpItem(name: "Introduction")
        rootItem.children = []
        rootItem.md = loadHelpKey("Introduction")
        var examplesItem = HelpItem(name: "Examples")
        examplesItem.md = loadHelpKey("Examples")
        rootItem.children!.append(examplesItem)
        helpItems.append(rootItem)

        // Behavior Files
        var behaviorItem = HelpItem(name: "Behavior Files")
        behaviorItem.children = []
        behaviorItem.md = loadHelpKey("Behavior Files")
        
        do {
            let mapHelpIndex = try fileManager.contentsOfDirectory(atPath: Bundle.main.resourcePath! + "/Files/Help/BehaviorHelp").sorted()
            for h in mapHelpIndex {
                
                guard let path = Bundle.main.path(forResource: h, ofType: "", inDirectory: "Files/Help/BehaviorHelp") else {
                    return
                }
                
                if let help = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    var item = HelpItem(name: h)
                    item.md += help
                    behaviorItem.children!.append(item)
                }
            }
        } catch {
        }
        helpItems.append(behaviorItem)
        
        // Map Files
        var mapItem = HelpItem(name: "Map Files")
        mapItem.children = []
        mapItem.md = loadHelpKey("Map Files")
        
        do {
            let mapHelpIndex = try fileManager.contentsOfDirectory(atPath: Bundle.main.resourcePath! + "/Files/Help/MapHelp").sorted()
            for h in mapHelpIndex {
                
                guard let path = Bundle.main.path(forResource: h, ofType: "", inDirectory: "Files/Help/MapHelp") else {
                    return
                }
                
                if let help = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                    var item = HelpItem(name: h)
                    item.md += help
                    mapItem.children!.append(item)
                }
            }
        } catch {
        }
        helpItems.append(mapItem)
        
        if game.helpText.isEmpty {
            game.helpText = rootItem.md
            game.helpTextChanged.send()
        }
        
        // Shaders
        var shaderItem = HelpItem(name: "Shaders")
        shaderItem.children = []
        shaderItem.md = loadHelpKey("Shaders")
        helpItems.append(shaderItem)
    }
    
    func loadHelpKey(_ key: String) -> String
    {
        guard let path = Bundle.main.path(forResource: key, ofType: "", inDirectory: "Files/Help") else {
            return ""
        }
        
        if let help = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            return help
        }
        
        return ""
    }
    
    var body: some View {
        
        List(helpItems, children: \.children) { item in
            
            Button(action: {
                game.helpText = item.md
                game.helpTextChanged.send()
            })
            {
                Text(item.name)
            }
            .buttonStyle(PlainButtonStyle())
            /*
            HStack {
                
                if let image = item.image {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                }
         
                Text(item.name)
                    .font(.system(.title3, design: .rounded))
                    .bold()
            }*/
        }
        
    }
}

struct ParmaView: View {
    @Binding var text: String
    var body: some View {
        Markdown(Document(text))
    }
}
