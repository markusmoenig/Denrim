//
//  ContentView.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: DenrimDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: .constant(DenrimDocument()))
    }
}
