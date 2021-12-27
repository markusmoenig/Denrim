//
//  SideBarView.swift
//  Denrim
//
//  Created by Markus Moenig on 27/12/21.
//

import SwiftUI

struct SideBarView: View {
    
    @State var game                         : Game

    @State private var helpIsVisible        : Bool = false
    @State private var helpText             : String = ""
    
    @State private var contextText          : String = ""

    var body: some View {
        
        if helpIsVisible == true {
            HelpIndexView(game)
                .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                .layoutPriority(0)
                //.animation(.easeInOut)
        } else {
            ScrollView {
                Text(getAttributedString(markdown: contextText))
                //ParmaView(text: $contextText)
                    .frame(minWidth: 0,
                           maxWidth: .infinity,
                           minHeight: 0,
                           maxHeight: .infinity,
                           alignment: .bottomLeading)
                    .padding(4)
                    .onReceive(game.contextTextChanged) { text in
                        contextText = text//self.document.game.contextText
                    }
                    .foregroundColor(Color.gray)
                    .font(.system(size: 12))
                    .frame(minWidth: 160, idealWidth: 160, maxWidth: 160)
                    .layoutPriority(0)
                    //.animation(.easeInOut)
        
            }
            //.animation(.easeInOut)
        }
    }
    
    /// String to AttributedString
    func getAttributedString(markdown: String) -> AttributedString {
        do {
            return try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString()
        }
    }
}
