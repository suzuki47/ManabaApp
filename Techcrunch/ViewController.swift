// ViewController.swift
import UIKit
import WebKit

class LoginViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string: "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=list")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString, url == "https://ct.ritsumei.ac.jp/ct/home_course?chglistformat=list" {
            // WebViewのクッキーを取得してUserDefaultsに保存する処理を実行
            saveWebViewCookies()
        }
    }
    
    func saveWebViewCookies() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                // ここでUserDefaultsにクッキーを保存する
                // UserDefaultsはクッキーのオブジェクトを直接保存できないため、
                // クッキーのプロパティを辞書などの形に変換して保存する必要がある
                print(cookie) // 実際のアプリでは、この行は削除
                // 例: UserDefaultsにクッキーのnameとvalueを保存（デモ用に簡略化）
                UserDefaults.standard.setValue(cookie.value, forKey: cookie.name)
            }
            UserDefaults.standard.synchronize()
            
            // すべてのクッキーを保存した後、モーダルを閉じる
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
            print("UserDefaultsに保存しました")
        }
    }
}
