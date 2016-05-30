//
//  DetailViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/23.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Accounts
import Social

class DetailViewController: UIViewController {
    
    @IBOutlet weak var userIcon: UIImageView!
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var tweetTextView: UITextView!
    @IBOutlet weak var nameView: UITextView!
    @IBOutlet weak var destroyButton: UIButton!
    @IBOutlet weak var retweetButton: UIButton!
    
  
    
    var profileImage = UIImage()
    var screenName = ""
    var text = ""
    var idStr = ""
    var favorited = false
    var retweeted = false
    var protected = false
    var twitterAccount = ACAccount()
    private let mainQueue = dispatch_get_main_queue()



    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.navigationController = navigationController!
        
        profileImageView.image = profileImage
        nameView.text = screenName
        tweetTextView.text = text
        print("a" + twitterAccount.username)
        print("b\(screenName)")
        if screenName != twitterAccount.username {
            self.destroyButton.enabled = false
            //self.retweetButton.enabled = true
            destroyButton.alpha = 0.2
            retweetButton.alpha = 1
                if protected == true {
                self.retweetButton.enabled = false
                retweetButton.alpha = 0.2
                    print("a")
                } else {
                self.retweetButton.enabled = true
                retweetButton.alpha = 1
                    print("b")
            }
        } else {
            self.destroyButton.enabled = true
            self.retweetButton.enabled = false
            retweetButton.alpha = 0.2
            destroyButton.alpha = 1
        }
                // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    @IBAction func retweet() {
        //**
        //** リツイート手順
        //** 1. リクエスト用のパラメタを設定し、それを使ってリクエストオブジェクトを初期化
        //** 2. リクエストハンドラを作成
        //** 3. リクエストにアカウント情報をセット
        //** 4. リクエストハンドラを使ってリクエスト実行
        //**
        
        if retweeted == false {
            //** リクエスト生成
            let request = generateRequest()
            
            //** リクエストハンドラ作成
            let handler = generateRequestHandler()
            
            //** アカウント情報セット
            request.account = twitterAccount
            
            //** インジケータ開始
            startProcessing()
            
            //** リクエスト実行
            request.performRequestWithHandler(handler)


        } else {
            //** リクエスト生成
            let request = generateRetweetDestroyRequest()
            
            //** リクエストハンドラ作成
            let handler = generateRequestHandler()
            
            //** アカウント情報セット
            request.account = twitterAccount
            
            //** インジケータ開始
            startProcessing()
            
            //** リクエスト実行
            request.performRequestWithHandler(handler)
        }

    }
    
    //**
    //** リクエスト生成メソッド
    //**
    private func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/retweet/\(idStr).json")
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: nil) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }
    
    private func generateRetweetDestroyRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/unretweet/\(idStr).json")
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: nil) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }
    
    //**
    //** リクエストハンドラ作成メソッド
    //**
    private func generateRequestHandler() -> SLRequestHandler {
        // リクエストハンドラ作成
        let handler: SLRequestHandler = { postResponseData, urlResponse, error in
            
            // リクエスト送信エラー発生時
            if let requestError = error {
                print("Request Error: An error occurred while requesting: \(requestError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // httpエラー発生時（ステータスコードが200番台以外ならエラー）
            if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // JSONシリアライズ
            let objectFromJSON: AnyObject
            do {
                objectFromJSON = try NSJSONSerialization.JSONObjectWithData(
                    postResponseData,
                    options: NSJSONReadingOptions.MutableContainers)
                
                // JSONシリアライズエラー発生時
            } catch (let jsonError) {
                print("JSON Error: \(jsonError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // リツイート成功
            print("SUCCESS! Created Retweet with ID: \(objectFromJSON["id_str"] as! String)")
            // インジケータ停止
            self.stopProcessing()
        }
        return handler
    }
    
    //**
    //** インジケータ開始メソッド
    //**
    private func startProcessing() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    //**
    //** インジケータ停止メソッド
    //**
    private func stopProcessing() {
        dispatch_async(self.mainQueue, {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func favoriteRequest() {
        if favorited == false {
            //** リクエスト生成
            let request = generateFavoriteRequest()
            
            //** リクエストハンドラ作成
            let handler = generateRequestHandler()
            
            //** アカウント情報セット
            request.account = twitterAccount
            
            //** インジケータ開始
            startProcessing()
            
            //** リクエスト実行
            request.performRequestWithHandler(handler)
        }else {
      
            //** リクエスト生成
            let request = generateDestroyFavoriteRequest()
            
            //** リクエストハンドラ作成
            let handler = generateRequestHandler()
            
            //** アカウント情報セット
            request.account = twitterAccount
            
            //** インジケータ開始
            startProcessing()
            
            //** リクエスト実行
            request.performRequestWithHandler(handler)
           
        }
//        //** リクエスト生成
//        let request = generatefavoriteRequest()
//        
//        //** リクエストハンドラ作成
//        let handler = generateRequestHandler()
//        
//        //** アカウント情報セット
//        request.account = twitterAccount
//        
//        //** インジケータ開始
//        startProcessing()
//        
//        //** リクエスト実行
//        request.performRequestWithHandler(handler)

    }
    
    private func generateFavoriteRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/create.json")
        let params = ["id" : self.idStr, "include_entities" : "true"]

        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }

    private func generateDestroyFavoriteRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/destroy.json")
        let params = ["id" : self.idStr, "include_entities" : "true"]
        
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }
    
    
    @IBAction func destroyTweet() {
        //** リクエスト生成
        let request = generateDestroyRequest()
        
        //** リクエストハンドラ作成
        let handler = generateRequestHandler()
        
        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
    }
    
    private func generateDestroyRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/destroy/\(idStr).json")
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: nil) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }

    @IBAction func friendships() {
        
        //** リクエスト生成
        let request = generateFriendshipsRequest()
        
        //** リクエストハンドラ作成
        let handler = generateRequestHandler()
        
        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
        
    }
    
    private func generateFriendshipsRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/create.json")
        let params = ["id" : self.idStr, "screen_name" : self.screenName]
        
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }

    
    @IBAction func FriendshipsDestroy() {
        
        //** リクエスト生成
        let request = generateFriendshipsDestroyRequest()
        
        //** リクエストハンドラ作成
        let handler = generateRequestHandler()
        
        //** アカウント情報セット
        request.account = twitterAccount
        
        //** インジケータ開始
        startProcessing()
        
        //** リクエスト実行
        request.performRequestWithHandler(handler)
    }
    
    private func generateFriendshipsDestroyRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/destroy.json")
        let params = ["id" : self.idStr, "screen_name" : self.screenName]
        
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.POST,
                                URL: url,
                                parameters: params) // 今回はURLにidStrを含めるのでparametersは不要
        
        return request
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "rTweetSegue" {
            let rTweetSheetVC = segue.destinationViewController as! ReplyViewController
            rTweetSheetVC.twitterAccount = twitterAccount // 次のVCへTwitterアカウントを引き渡す
            rTweetSheetVC.screenName = screenName
            print(twitterAccount.username)
        }
    }
    
}
