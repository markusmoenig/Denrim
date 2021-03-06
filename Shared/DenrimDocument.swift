//
//  DenrimDocument.swift
//  Shared
//
//  Created by Markus Moenig on 30/8/20.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var denrimGame: UTType {
        UTType(exportedAs: "com.Denrim.game")
    }
}

struct DenrimDocument: FileDocument {
    
    var game        = Game()
    var updated     = false
    
    init() {
    }

    static var readableContentTypes: [UTType] { [.denrimGame] }

    /*
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }*/
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
                let folder = try? JSONDecoder().decode(AssetFolder.self, from: data)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        if data.isEmpty == false {
            game.assetFolder = folder
            game.assetFolder.game = game
            
            // Make sure there is a selected asset
            if game.assetFolder.assets.count > 0 {
                game.assetFolder.current = game.assetFolder.assets[0]
            }
        }
    }
    
    /*
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }*/
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        var data = Data()
        let encodedData = try? JSONEncoder().encode(game.assetFolder)
        if let json = String(data: encodedData!, encoding: .utf8) {
            data = json.data(using: .utf8)!
        }
        
        return .init(regularFileWithContents: data)
    }
}
