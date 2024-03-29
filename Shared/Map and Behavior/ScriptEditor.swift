//
//  WebEditor.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

#if !os(tvOS)

import SwiftUI
import WebKit
import Combine

class ScriptEditor
{
    var webView             : WKWebView
    var game                : Game
    var sessions            : Int = 0
    var colorScheme         : ColorScheme
    
    var mapHelpIndex        : [String] = []
    var mapHelp             : [String:String] = [:]
    var mapHelpText         : String = "## Available:\n\n"
    
    var behaviorHelpIndex   : [String] = []
    var behaviorHelp        : [String:String] = [:]
    var behaviorHelpText    : String = "## Available:\n\n"
    
    init(_ view: WKWebView, _ game: Game,_ colorScheme: ColorScheme)
    {
        self.webView = view
        self.game = game
        self.colorScheme = colorScheme
        
        if let asset = game.assetFolder.getAsset("Game") {
            game.assetFolder.select(asset.id)
            createSession(asset)
            setTheme(colorScheme)
        }
        
        // Read out the map context help
        var docsPath = Bundle.main.resourcePath! + "/Files/Help/MapHelp"
        let fileManager = FileManager.default

        do {
            mapHelpIndex = try fileManager.contentsOfDirectory(atPath: docsPath).sorted()
            for h in mapHelpIndex {
                mapHelpText += h + "\n"
            }
        } catch {
        }
        
        // Read out the behavior context help
        docsPath = Bundle.main.resourcePath! + "/Files/Help/BehaviorHelp"

        do {
            behaviorHelpIndex = try fileManager.contentsOfDirectory(atPath: docsPath).sorted()
            for h in behaviorHelpIndex {
                behaviorHelpText += h + "\n"
            }
        } catch {
        }
        
        createDebugSession()
    }
    
    // Get help for a map keyword
    func getMapHelpForKey(_ key: String) -> String?
    {
        if let help = mapHelp[key] {
            return help
        }

        if mapHelpIndex.contains(key) {
            guard let path = Bundle.main.path(forResource: key, ofType: "", inDirectory: "Files/Help/MapHelp") else {
                return nil
            }
            
            if let help = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                mapHelp[key] = help
                return help
            }
        }
        return nil
    }
    
    // Get help for a behavior keyword
    func getBehaviorHelpForKey(_ key: String) -> String?
    {
        if let help = behaviorHelp[key] {
            return help
        }

        if behaviorHelpIndex.contains(key) {
            guard let path = Bundle.main.path(forResource: key, ofType: "", inDirectory: "Files/Help/BehaviorHelp") else {
                return nil
            }
            
            if let help = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) {
                behaviorHelp[key] = help
                return help
            }
        }
        return nil
    }
    
    func setTheme(_ colorScheme: ColorScheme)
    {
        let theme: String
        if colorScheme == .light {
            theme = "tomorrow"
        } else {
            theme = "tomorrow_night"
        }
        webView.evaluateJavaScript(
            """
            editor.setTheme("ace/theme/\(theme)");
            """, completionHandler: { (value, error ) in
         })
    }
    
    func createDebugSession()
    {
        webView.evaluateJavaScript(
            """
            var debugSession = ace.createEditSession(``)
            debugSession.setMode("ace/mode/text");
            """, completionHandler: { (value, error ) in
         })
    }
    
    func activateDebugSession()
    {
        game.showingDebugInfo = true
        let text =
        """
        The game engine will display debug information during runtime here.
        """
        webView.evaluateJavaScript(
            """
            debugSession.setValue(`\(text)`)
            editor.setSession(debugSession)
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setDebugText(text: String)
    {
        let cmd = """
        debugSession.setValue(`\(text)`)
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func createSession(_ asset: Asset,_ cb: (()->())? = nil)
    {
        if asset.scriptName.isEmpty {
            asset.scriptName = "session" + String(sessions)
            sessions += 1
        }
        
        if asset.type == .Behavior || asset.type == .Shape {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/denrim");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        } else
        if asset.type == .Shader {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/c_cpp");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        } else
        if asset.type == .Map {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/denrim");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        } else
        if asset.type == .Image || asset.type == .Audio {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/text");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        } else
        if asset.type == .Lua {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/lua");
                """, completionHandler: { (value, error ) in
                    if let cb = cb {
                        cb()
                    }
             })
        }
    }
    
    func setReadOnly(_ readOnly: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setReadOnly(\(readOnly));
            """, completionHandler: { (value, error) in
         })
    }
    
    func getAssetValue(_ asset: Asset,_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            \(asset.scriptName).getValue()
            """, completionHandler: { (value, error) in
                if let value = value as? String {
                    cb(value)
                }
         })
    }
    
    func setAssetValue(_ asset: Asset, value: String)
    {
        let cmd = """
        \(asset.scriptName).setValue(`\(value)`)
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setAssetSession(_ asset: Asset)
    {
        game.showingDebugInfo = false
        func setSession()
        {
            let cmd = """
            editor.setSession(\(asset.scriptName))
            """
            webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
            })
        }
        
        if asset.scriptName.isEmpty == true {
            createSession(asset, { () in
                setSession()
            })
        } else {
            setSession()
        }

    }
    
    func goto(line: Int32, column: Int32 = 0) {
        webView.evaluateJavaScript(
            """
            editor.getSession().scrollToLine(\(line), true, true, function () {});"
            editor.getSession().gotoLine(\(line), \(column), true);

            """, completionHandler: { (value, error ) in
         })
    }
    
    func select(lineS: Int32, columnS: Int32, lineE: Int32, columnE: Int32) {
        webView.evaluateJavaScript(
            """

            editor.getSession().selection.setRange(new ace.Range(\(lineS), \(columnS), \(lineE), \(columnE)), true);

            """, completionHandler: { (value, error ) in
         })
    }
    
    func selectAndReplace(lineS: Int32, columnS: Int32, lineE: Int32, columnE: Int32, replaceWith: String) {
        webView.evaluateJavaScript(
            """
            
            editor.getSession().replace(new ace.Range(\(lineS), \(columnS), \(lineE), \(columnE)), \"\(replaceWith)\");

            editor.getSession().selection.setRange(new ace.Range(\(lineS), \(columnS), \(lineE), \(columnE)), true);

            """, completionHandler: { (value, error ) in
         })
    }
    
    func replaceSelection(_ text: String) {
        
        print("herere")
        webView.evaluateJavaScript(
            """
            
            editor.getSession().replace(editor.getRange(), \(text));

            """, completionHandler: { (value, error ) in
         })
    }

    func setError(_ error: CompileError, scrollToError: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations([{
            row: \(error.line!-1),
            column: \(error.column!),
            text: "\(error.error!)",
            type: "error" // also warning and information
            }]);

            \(scrollToError == true ? "editor.scrollToLine(\(error.line!-1), true, true, function () {});" : "")

            """, completionHandler: { (value, error ) in
         })
    }
    
    func setErrors(_ errors: [CompileError])
    {
        var str = "["
        for error in errors {
            str +=
            """
            {
                row: \(error.line!),
                column: \(error.column!),
                text: \"\(error.error!)\",
                type: \"\(error.type)\"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setFailures(_ lines: [Int32])
    {
        var str = "["
        for line in lines {
            str +=
            """
            {
                row: \(line),
                column: 0,
                text: "Failed",
                type: "error"
            },
            """
        }
        str += "]"
        
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations(\(str));
            """, completionHandler: { (value, error ) in
         })
    }
    
    func getSessionCursor(_ cb: @escaping (Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            editor.getCursorPosition()
            """, completionHandler: { (value, error ) in
                //if let v = value as? Int32 {
                //    cb(v)
                //}
                
                //print(value)
                if let map = value as? [String:Any] {
                    var row      : Int32 = -1
                    var column   : Int32 = -1
                    if let r = map["row"] as? Int32 {
                        row = r
                    }
                    if let c = map["column"] as? Int32 {
                        column = c
                    }

                    cb(row, column)
                }
         })
    }
    
    func getSelectedRange(_ cb: @escaping (Int32, Int32, Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            editor.selection.getRange()
            """, completionHandler: { (value, error ) in
                if let map = value as? [String:Any] {
                    var sline       : Int32 = -1
                    var scolumn     : Int32 = -1
                    var eline       : Int32 = -1
                    var ecolumn     : Int32 = -1
                    if let f = map["start"] as? [String:Any] {
                        if let ff = f["row"] as? Int32 {
                            sline = ff
                        }
                        if let ff = f["column"] as? Int32 {
                            scolumn = ff
                        }
                    }
                    if let t = map["end"] as? [String:Any] {
                        if let ff = t["row"] as? Int32 {
                            eline = ff
                        }
                        if let ff = t["column"] as? Int32 {
                            ecolumn = ff
                        }
                    }
                    cb(sline, scolumn, eline, ecolumn)
                }
         })
    }
    
    func getSelectedText(_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            editor.getSelectedText()
            """, completionHandler: { (value, error ) in
                if let text = value as? String {
                    cb(text)
                }
         })
    }
    
    func getChangeDelta(_ cb: @escaping (Int32, Int32)->() )
    {
        webView.evaluateJavaScript(
            """
            delta
            """, completionHandler: { (value, error ) in
                //print(value)
                if let map = value as? [String:Any] {
                    var from : Int32 = -1
                    var to   : Int32 = -1
                    if let f = map["start"] as? [String:Any] {
                        if let ff = f["row"] as? Int32 {
                            from = ff
                        }
                    }
                    if let t = map["end"] as? [String:Any] {
                        if let tt = t["row"] as? Int32 {
                            to = tt
                        }
                    }
                    cb(from, to)
                }
         })
    }
    
    func clearAnnotations()
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().clearAnnotations()
            """, completionHandler: { (value, error ) in
         })
    }
    
    func updated()
    {
        if let asset = game.assetFolder.current {
            getAssetValue(asset, { (value) in
                self.game.assetFolder.assetUpdated(id: asset.id, value: value)
                //self.getChangeDelta({ (from, to) in
                //    self.game.assetFolder.assetUpdated(id: asset.id, value: value, deltaStart: from, deltaEnd: to)
                //})
            })
        }
    }
}

class WebViewModel: ObservableObject {
    @Published var didFinishLoading: Bool = false
    
    init () {
    }
}

#if os(OSX)
struct SwiftUIWebView: NSViewRepresentable {
    public typealias NSViewType = WKWebView
    var game        : Game!
    var colorScheme : ColorScheme

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            
            webView.isHidden = true
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(game, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var game        : Game
        private var colorScheme : ColorScheme

        init(_ game: Game,_ colorScheme: ColorScheme) {
            self.game = game
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = game.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            game.scriptEditor = ScriptEditor(web, game, colorScheme)
            web.isHidden = false
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
#else
struct SwiftUIWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    var game        : Game!
    var colorScheme : ColorScheme
    
    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Files") {
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(game, colorScheme)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var game        : Game
        private var colorScheme : ColorScheme
        
        init(_ game: Game,_ colorScheme: ColorScheme) {
            self.game = game
            self.colorScheme = colorScheme
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "jsHandler" {
                if let scriptEditor = game.scriptEditor {
                    scriptEditor.updated()
                }
            }
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            game.scriptEditor = ScriptEditor(web, game, colorScheme)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct WebView  : View {
    var game        : Game
    var colorScheme : ColorScheme

    init(_ game: Game,_ colorScheme: ColorScheme) {
        self.game = game
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        SwiftUIWebView(game: game, colorScheme: colorScheme)
    }
}

#else

class ScriptEditor
{
    var mapHelpText     : String = "## Available:\n\n"
    var behaviorHelpText: String = "## Available:\n\n"
    
    func createSession(_ asset: Asset,_ cb: (()->())? = nil) {}
    
    func setAssetValue(_ asset: Asset, value: String) {}
    func setAssetSession(_ asset: Asset) {}
    
    func setError(_ error: CompileError, scrollToError: Bool = false) {}
    func setErrors(_ errors: [CompileError]) {}
    func clearAnnotations() {}
    
    func getSessionCursor(_ cb: @escaping (Int32, Int32)->() ) {}
    
    func setReadOnly(_ readOnly: Bool = false) {}
    func setDebugText(text: String) {}
    
    func setFailures(_ lines: [Int32]) {}
    
    func getBehaviorHelpForKey(_ key: String) -> String? { return nil }
    func getMapHelpForKey(_ key: String) -> String? { return nil }
}

#endif
