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










/*
import UIKit
import WebKit

protocol ClassroomInfoDelegate: AnyObject {
    func didReceiveClassroomInfo(_ info: [String])
}

class ViewController: UIViewController, WKNavigationDelegate, ClassroomInfoDelegate {
    
    var classroomInfo: [(String, String)] = []
    var headers: [(String, String)] = []
    weak var classroomInfoDelegate: ClassroomInfoDelegate?
    //var cookieStore: [String] = []
    
    
    
    //webViewの初期設定
    private let webView: WKWebView = {
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        config.defaultWebpagePreferences = pagePrefs
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.translatesAutoresizingMaskIntoConstraints = false
        return webview
    }()
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toNext" {
            let secondVC = segue.destination as! SecondViewController
            secondVC.headers = self.headers
            secondVC.classroomInfoDelegate = self
        }
    }
    */
    
    
    
    // viewDidLoad()は、UIViewControllerがメモリにロードされた後に呼ばれる
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = URL(string: "https://ct.ritsumei.ac.jp/ct/home_summary_report") else { return }
        // 画面にWebViewを追加
        view.addSubview(webView)
        // WebViewのナビゲーションを制御するために、自分自身（このビューコントローラ）をデリゲートに設定
        webView.navigationDelegate = self
        // 指定したURLからWebコンテンツを読み込む
        webView.load(URLRequest(url: url))
        
        print("0")
        // webViewの画面配置
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            webView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        print("1")
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!){
        print("2222222222222222222")
        let myWebView = WKWebView()
        myWebView.isHidden = true
        print("ggggg")
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        var cookiestring = ""
        
        // 取得したクッキーを「name=value;」に変形する
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookiestring+=cookie.name
                cookiestring+="="
                cookiestring+=cookie.value
                cookiestring+=";"
            }
        }
        var hasCookie = false
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                /*print("クッキー名: \(cookie.name), 値: \(cookie.value)")*/
                if cookie.name == "sessionid" {
                    hasCookie = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // webViewを閉じる
                        webView.removeFromSuperview()
                        let stringValue = cookiestring
                        // HTMLParserクラスのインスタンスを作成し、クッキー文字列として'stringValue'を渡す
                        let htmlParser = ManabaScraper(cookiestring: stringValue)
                        
                        Task {
                            do {
                                let headers = try await htmlParser.parse()
                                self.headers = headers
                                
                                let classroomInfoData = try await htmlParser.fetchClassroomInfo(usingCookie: stringValue)
                                self.classroomInfo = classroomInfoData
                                print("oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
                                print(self.classroomInfo)
                                //let classData = ClassData()
                                /*
                                parseAndStoreClassData(dataList: self.classroomInfo)
                                for (index, day) in ClassData.classData.enumerated() {
                                    let dayName: String
                                    switch index {
                                    case 0: dayName = "月曜日"
                                    case 1: dayName = "火曜日"
                                    case 2: dayName = "水曜日"
                                    case 3: dayName = "木曜日"
                                    case 4: dayName = "金曜日"
                                    case 5: dayName = "土曜日"
                                    case 6: dayName = "日曜日"
                                    default: continue // 土曜日と日曜日は無視する
                                    }
                                    
                                    let classes = day.map { $0.description }
                                    print("\(dayName): \(classes)")
                                }
                                 */
                                /*
                                DispatchQueue.main.async {
                                    let originalString = headers.joined(separator: " ")
                                    let processedString = self.insertNewlinesEvery30Characters(input: originalString)
                                    self.outputLabel.text = processedString
                                    
                                    
                                    let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewControllerID") as! SecondViewController
                                    viewController.modalPresentationStyle = .fullScreen
                                    viewController.headers = self.headers
                                    viewController.classroomInfoData = self.classroomInfo // ここでデータを渡す
                                    self.present(viewController, animated: true, completion: nil)
                                }*/
                            } catch {
                                print("Failed: \(error)")
                            }
                        }
                        
                        
                    }
                    
                }
            }
        }
        
        if !hasCookie {
            doLogin(myWebView)
        }
    }
    
    func doLogin(_ webView: WKWebView) {
        // ページの読み込みが完了した時の処理
        print("ページの読み込みが完了しました。")
        
        // クッキーを取得
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        var cookiestring = ""
        
        // 取得したクッキーを「name=value;」に変形する
        cookieStore.getAllCookies { cookies in
            for cookie in cookies {
                cookiestring += cookie.name + "=" + cookie.value + ";"
            }
            for cookie in cookies {
                if cookie.name == "sessionid" {
                    // webViewを閉じる
                    webView.removeFromSuperview()
                    let stringValue = cookiestring
                    let htmlParser = ManabaScraper(cookiestring: stringValue)
                    
                    Task {
                        do {
                            let headers = try await htmlParser.parse()
                            self.headers = headers
                            
                            let classroomInfoData = try await htmlParser.fetchClassroomInfo(usingCookie: stringValue)
                            self.classroomInfo = classroomInfoData
                            print("oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo")
                            print(self.classroomInfo)
                            /*
                            DispatchQueue.main.async {
                                let originalString = headers.joined(separator: " ")
                                let processedString = self.insertNewlinesEvery30Characters(input: originalString)
                                self.outputLabel.text = processedString
                                
                                let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewControllerID") as! SecondViewController
                                viewController.modalPresentationStyle = .fullScreen
                                viewController.headers = self.headers
                                viewController.classroomInfoData = self.classroomInfo // ここでデータを渡す
                                self.present(viewController, animated: true, completion: nil)
                            }*/
                        } catch {
                            print("Failed: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func insertNewlinesEvery30Characters(input: String) -> String {
        var result = ""
        var count = 0
        for character in input {
            if count == 30 {
                result += "\n"
                count = 0
            }
            result.append(character)
            count += 1
        }
        return result
    }
    
    func didReceiveClassroomInfo(_ info: [String]) {
        // ここで classroomInfo のデータを受け取った後の処理を実装します。
        // 例: print(info)
    }
    
    
    
    @IBOutlet weak var outputLabel: UILabel!
    
    
    
}
*/
