//
//  WebEditor.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import SwiftUI
import WebKit
import Combine

class ContextEditor
{
    var webView         : WKWebView
    var game            : Game
    var sessions        : Int = 0
    var colorScheme     : ColorScheme
    
    init(_ view: WKWebView, _ game: Game,_ colorScheme: ColorScheme)
    {
        self.webView = view
        self.game = game
        self.colorScheme = colorScheme
        
        setTheme(colorScheme)
        setReadOnly(true)
        setShowGutter(false)
    }
    
    func setTheme(_ colorScheme: ColorScheme)
    {
        let theme: String
        if colorScheme == .light {
            theme = "tomorrow"
        } else {
            theme = "tomorrow_night_bright"
        }
        webView.evaluateJavaScript(
            """
            editor.setTheme("ace/theme/\(theme)");
            """, completionHandler: { (value, error ) in
         })
    }
    
    func setValue(_ value: String)
    {
        let cmd = """
        editor.setValue(`\(value)`, -1);
        """
        webView.evaluateJavaScript(cmd, completionHandler: { (value, error ) in
        })
    }
    
    func setReadOnly(_ readOnly: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.setReadOnly(\(readOnly));
            editor.session.setMode("ace/mode/denrim");
            editor.setUseWrapMode(true);
            editor.setOption("indentedSoftWrap", false);
            """, completionHandler: { (value, error) in
         })
    }
    
    func setShowGutter(_ showGutter: Bool = false)
    {
        webView.evaluateJavaScript(
            """
            editor.renderer.setShowGutter(\(showGutter));
            editor.setOptions({readOnly: true, highlightActiveLine: false, highlightGutterLine: false});
            editor.renderer.$cursorLayer.element.style.display = "none"
            """, completionHandler: { (value, error) in
         })
    }
}

#if os(OSX)
struct SwiftUIContextWebView: NSViewRepresentable {
    public typealias NSViewType = WKWebView
    var game        : Game!
    var colorScheme : ColorScheme

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<SwiftUIContextWebView>) -> WKWebView {
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

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<SwiftUIContextWebView>) { }

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
            game.contextEditor = ContextEditor(web, game, colorScheme)
            web.isHidden = false
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
#else
struct SwiftUIContextWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView
    var game        : Game!
    var colorScheme : ColorScheme
    
    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<SwiftUIContextWebView>) -> WKWebView {
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

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<SwiftUIContextWebView>) { }

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
            game.contextEditor = ContextEditor(web, game, colorScheme)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct ContextWebView  : View {
    var game        : Game
    var colorScheme : ColorScheme

    init(_ game: Game,_ colorScheme: ColorScheme) {
        self.game = game
        self.colorScheme = colorScheme
    }
    
    var body: some View {
        SwiftUIContextWebView(game: game, colorScheme: colorScheme)
    }
}
