//
//  DenrimApp.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI

@main
struct DenrimApp: App {
        
    @StateObject var appState = AppState()

    var body: some Scene {
        DocumentGroup(newDocument: DenrimDocument()) { file in
            ContentView(document: file.$document)
        }
        .commands {
            
            CommandGroup(replacing: .help) {
                Button(action: {
                    if appState.currentDocument != nil {
                        print("test")
                    }
                }) {
                    Text("Denrim Help")
                }
            }
            CommandMenu("Project") {
                Button(action: {}) {
                    Text("Dark mode")
                }

                Button(action: {}) {
                    Text("Light mode")
                }

                Button(action: {}) {
                    Text("System mode")
                }
            }
        }
    }
    
    private func createView(for file: FileDocumentConfiguration<DenrimDocument>) -> some View {
        appState.currentDocument = file.document
        return ContentView(document: file.$document)
    }
}

class AppState: ObservableObject {
    @Published var currentDocument: DenrimDocument?
}
