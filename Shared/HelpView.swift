//
//  DocView.swift
//  Metal-Z
//
//  Created by Markus Moenig on 25/8/20.
//

import SwiftUI
import WebKit
import Combine

#if os(OSX)
struct DocWebView: NSViewRepresentable {
    
    public typealias NSViewType = WKWebView

    private let webView: WKWebView = WKWebView()
    public func makeNSView(context: NSViewRepresentableContext<DocWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        
        if let url = Bundle.main.url(forResource: "doc.md", withExtension: "html", subdirectory: "Resources") {
            
            webView.isHidden = true
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: NSViewRepresentableContext<DocWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            web.isHidden = false
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}
#else
struct DocWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView

    private let webView: WKWebView = WKWebView()
    public func makeUIView(context: UIViewRepresentableContext<DocWebView>) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator as? WKUIDelegate
        
        if let url = Bundle.main.url(forResource: "doc.md", withExtension: "html", subdirectory: "Resources") {
            
            webView.isHidden = true
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<DocWebView>) { }

    public func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        }
        
        public func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) { }

        public func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) { }

        //After the webpage is loaded, assign the data in WebViewModel class
        public func webView(_ web: WKWebView, didFinish: WKNavigation!) {
            //game.scriptEditor = ScriptEditor(web, game)
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { }

        public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

    }
}

#endif

struct HelpWebView  : View {

    init() {
    }
    
    var body: some View {
        DocWebView()
    }
}
