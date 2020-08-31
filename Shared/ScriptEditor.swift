//
//  WebEditor.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import SwiftUI
import WebKit
import Combine

class ScriptEditor
{
    var webView     : WKWebView
    var game        : Game
    var sessions    : Int = 0
    
    init(_ view: WKWebView, _ game: Game)
    {
        self.webView = view
        self.game = game
        
        if let asset = game.assetFolder.getAsset("Game.js") {
            //setValue(value: asset.value)
            createSession(asset)
        }
    }
    
    func createSession(_ asset: Asset)
    {
        if asset.scriptName.isEmpty {
            asset.scriptName = "session" + String(sessions)
            sessions += 1
        }
        
        if asset.type == .JavaScript || asset.type == .Image {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/javascript");
                """, completionHandler: { (value, error ) in
             })
        } else
        if asset.type == .Shader {
            webView.evaluateJavaScript(
                """
                var \(asset.scriptName) = ace.createEditSession(`\(asset.value)`)
                editor.setSession(\(asset.scriptName))
                editor.session.setMode("ace/mode/metal");
                """, completionHandler: { (value, error ) in
             })
        }
    }
    
    func getAssetValue(_ asset: Asset,_ cb: @escaping (String)->() )
    {
        webView.evaluateJavaScript(
            """
            \(asset.scriptName).getValue()
            """, completionHandler: { (value, error ) in
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
        let cmd = """
        editor.setSession(\(asset.scriptName))
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setAnnotation(lineNumber: Int32, text: String )
    {
        webView.evaluateJavaScript(
            """
            editor.getSession().setAnnotations([{
            row: \(lineNumber-1),
            column: 0,
            text: "\(text)",
            type: "error" // also warning and information
            }])
            """, completionHandler: { (value, error ) in
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
                self.game.assetFolder.assetUpdated(name: asset.name, value: value)
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
    var game: Game!

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            
            webView.isHidden = true
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(game)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var game: Game

        init(_ game: Game) {
           //Initialise the WebViewModel
           self.game = game
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
            game.scriptEditor = ScriptEditor(web, game)
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
    var game: Game!

    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        webView.configuration.userContentController.add(context.coordinator, name: "jsHandler")
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources") {
            
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(game)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        private var game: Game

        init(_ game: Game) {
           //Initialise the WebViewModel
           self.game = game
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
            game.scriptEditor = ScriptEditor(web, game)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct WebView  : View {
    var game    : Game

    init(_ game: Game) {
        self.game = game
    }
    
    var body: some View {
        SwiftUIWebView(game: game)
    }
}