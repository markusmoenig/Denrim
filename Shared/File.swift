//
//  File.swift
//  Denrim
//
//  Created by Markus Moenig on 18/9/20.
//

import Foundation

class File : NSObject
{
    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: /*"<G6R6L3VH62>.<iCloud.com.moenig.Denrim>"*/ nil)?.appendingPathComponent("Documents")
    }
    
    override init()
    {
        super.init()
        
        //print(containerUrl)
        // --- Check for iCloud container existence
        if let url = self.containerUrl, !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        //checkIfExamplesExist()
    }
    
    func checkIfExamplesExist()
    {
        let url = containerUrl?.appendingPathComponent("Examples")
        var isDir : ObjCBool = false
        if let url = url {
            
            print(url.path)
            do {
                let mapHelpIndex = try FileManager.default.contentsOfDirectory(atPath: containerUrl!.path)
                print(mapHelpIndex)
            } catch {
            }

            
            if FileManager.default.fileExists(atPath: url.path, isDirectory:&isDir) == false {
                print("Examples do not exist")
                
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    
                    print("created examples folder")
                    
                    //copyTemplateToExamples("BricksGame", url)
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func copyTemplateToExamples(_ name: String,_ url: URL)
    {
        guard let path = Bundle.main.path(forResource: name, ofType: "denrim", inDirectory: "Files/Templates") else {
            return
        }
        
        print("0")
        if let str = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
            print("1")

            let fileURL = url.appendingPathComponent(name + ".denrim")
            do {
                try str.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
                print("2")

            } catch {
            }
        }
    }
}
