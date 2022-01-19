//
//  ToolsView.swift
//  Denrim
//
//  Created by Markus Moenig on 19/1/22.
//

import SwiftUI

struct ToolsView: View {
    
    @State var game                     : Game
    
    @State var splitView                = true

    var body: some View {
        
        HStack(spacing: 2) {
            
            Button(action: {
                splitView.toggle()
                game.mapEditor.splitView = splitView
            })
            {
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary, lineWidth: 2)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: splitView ? "square.split.2x1" : "square")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(minWidth: 22, maxWidth: 22, minHeight: 22, maxHeight: 22)
                }
                /*
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(document.core.currentTool == .Select ? Color.primary : Color.secondary, lineWidth: 2)
                        .frame(width: 30, height: 30)
                    Image(systemName: "cursorarrow")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(minWidth: 22, maxWidth: 22, minHeight: 22, maxHeight: 22)
                        .foregroundColor(document.core.currentTool == .Select ? Color.primary : Color.secondary)
                }*/
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(4)
    }
}
