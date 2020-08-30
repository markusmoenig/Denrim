//
//  DenrimApp.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

@main
struct DenrimApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: DenrimDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
