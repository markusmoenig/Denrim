//
//  Parma.swift
//  Denrim
//
//  Created by Markus Moenig on 29/10/20.
//

import SwiftUI
import Parma

struct ParmaView: View {
    @Binding var text: String
    var body: some View {
        Parma(text)
    }
}
