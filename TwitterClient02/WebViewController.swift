//
//  WebViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/23.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import WebKit


class WebViewController: UIViewController, WKNavigationDelegate, UIWebViewDelegate {
    
    var openURL = NSURL()
    private var webView = WKWebView()
    private var progressView = UIProgressView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // WKWebView インスタンスの生成
        webView = WKWebView(frame: view.bounds, configuration: WKWebViewConfiguration())
        
        // デリゲートにこのビューコントローラを設定する
        webView.navigationDelegate = self
        
        // フリップでの戻る・進むを有効にする
        webView.allowsBackForwardNavigationGestures = true
        
        // WKWebView インスタンスを画面に配置する
        view = webView
        
        // DetailViewControllerから引き渡されたURLを開く
        let request = NSURLRequest(URL: openURL)
        webView.loadRequest(request)
        
//        var url = NSURL(string: String(request))
//        var request2 = NSURLRequest(URL: url!)
        
        // リクエストを生成する
        
        // プログレスビューの生成、描画
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Bar)
        progressView.frame = CGRectMake(0, calcBarHeight(), view.bounds.size.width, 2)
        view.addSubview(progressView)
        
        // Webページ読み込みの監視スタート
        webView.addObserver(self, forKeyPath:"estimatedProgress", options:.New, context:nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override func observeValueForKeyPath(keyPath:String?, ofObject object:AnyObject?, change:[String:AnyObject]?, context:UnsafeMutablePointer<Void>) { // 監視対象が変化したら
        switch keyPath! {
        case "estimatedProgress":
            if let progress = change![NSKeyValueChangeNewKey] as? Float {
                progressView.progress = progress
            }
        default:
            break
        }
    }
    
    
    //**
    //** WKNavigationDelegate デリゲートメソッド
    //**
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        startProcessing()
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        progressView.progress = 0.0
        stopProcessing()
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        progressView.progress = 0.0
        stopProcessing()
        print("Request Error: An error occurred while requesting: \(error)")
    }
    
    //**
    //** インジケータ開始メソッド
    //**
    private func startProcessing() { // インジケータ開始
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    //**
    //** インジケータ停止メソッド
    //**
    private func stopProcessing() { // インジケータ停止
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    //**
    //** ステータスバー＆ナビゲーションバー高さ計算メソッド
    //**
    private func calcBarHeight() -> CGFloat {
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let navigationBarHeight = navigationController?.navigationBar.frame.size.height ?? 0
        return statusBarHeight + navigationBarHeight
    }
    
    override func viewWillLayoutSubviews() { // 画面回転時にバーの高さを計算し直す
        progressView.frame = CGRectMake(0, calcBarHeight(), view.bounds.size.width, 2)
    }
    
    
    
    //    override func prefersStatusBarHidden() -> Bool { // 横長表示（Portrait画面）でもステータスバーを表示したい時にfalseを返す
    //        return false
    //    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
