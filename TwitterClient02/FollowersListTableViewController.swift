//
//  FollowersListTableViewController.swift
//  TwitterClient02
//
//  Created by guest on 2016/06/03.
//  Copyright © 2016年 JEC. All rights reserved.
//

import UIKit
import Accounts
import Social

class FollowersListTableViewController: UITableViewController {

    var twitterAccount = ACAccount() // 選択されたTwitterタイプのアカウント
    private var timeLineArray: [AnyObject] = [] // タイムライン行の配列
    private var statusArray: [Status] = [] // パース済みの配列
    private var httpMessage = "" // 接続待ち時及び接続エラー時のメッセージ
    private let mainQueue = dispatch_get_main_queue() // メインキュー
    private let imageQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0) // グローバルキュー
    
    var screenName = ""
    var text = ""
    var idStr = ""
    
    //**
    //** タイムラインリクエストメソッド
    //**
    private func requestTimeLine() {
        //**
        //** ホームタイムライン取得手順
        //** 1. リクエスト用のパラメタを設定し、それを使ってリクエストオブジェクトを初期化
        //** 2. リクエストハンドラを作成
        //** 3. リクエストにアカウント情報をセット
        //** 4. リクエストハンドラを使ってリクエスト実行
        //**
        
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
    }
    
    //**
    //** リフレッシュコントロール表示メソッド
    //**
    @objc private func refreshTableView() {
        // リフレッシュ開始　インジケータ開始
        refreshControl?.beginRefreshing()
        
        // タイムラインリクエスト
        requestTimeLine()
        
        // リフレッシュ終了　インジケータ停止
        // 通常以下の処理はこのメソッド内で良いが、今回の更新処理は非同期なので
        // dispatch_async()のメインキュー処理ブロック内に記述する必要がある。
        // if self.refreshControl!.refreshing {
        //     self.refreshControl?.endRefreshing()
        // }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // リフレッシュコントロールの初期化
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(FollowersListTableViewController.refreshTableView), forControlEvents: UIControlEvents.ValueChanged)
        
        // tableViewの中身が空の場合でもリフレッシュコントロールを使えるようにする
        tableView.alwaysBounceVertical = true
        
        
        requestTimeLine()
        //
        //        //**
        //        //** ホームタイムライン取得手順
        //        //** 1. リクエスト用のパラメタを設定し、それを使ってリクエストオブジェクトを初期化
        //        //** 2. リクエストハンドラを作成
        //        //** 3. リクエストにアカウント情報をセット
        //        //** 4. リクエストハンドラを使ってリクエスト実行
        //        //**
        //
        //        //** リクエスト生成
        //        let request = generateRequest()
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
    
    
    
    //**
    //** リクエスト生成メソッド
    //**
    private func generateRequest() -> SLRequest {
        // リクエストに必要なパラメタを用意
        
        let url = NSURL(string: "https://api.twitter.com/1.1/followers/list.json")
        let params = ["include_rts" : "0",
                      "trim_user" : "0",
                      "count" : "30",
                      "id" : self.idStr,
                      "screen_name" : self.screenName]
        
        // リクエスト初期化
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: SLRequestMethod.GET,
                                URL: url,
                                parameters: params)
        return request
        
    }
    
    //**
    //** リクエストハンドラ作成メソッド
    //**
    private func generateRequestHandler() -> SLRequestHandler {
        // リクエストハンドラ作成
        let handler: SLRequestHandler = { getResponseData, urlResponse, error in
            
            // リクエスト送信エラー発生時
            if let requestError = error {
                print("Request Error: An error occurred while requesting: \(requestError)")
                self.httpMessage = "HTTPエラー発生"
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // httpエラー発生時（ステータスコードが200番台以外ならエラー）
            if urlResponse.statusCode < 200 || urlResponse.statusCode >= 300 {
                print("HTTP Error: The response status code is \(urlResponse.statusCode)")
                self.httpMessage = "HTTPエラー発生"
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // JSONシリアライズ
            do {
                self.timeLineArray = try NSJSONSerialization.JSONObjectWithData(
                    getResponseData,
                    options: NSJSONReadingOptions.AllowFragments) as! [AnyObject]
                
                // JSONシリアライズエラー発生時
            } catch (let jsonError) {
                print("JSON Error: \(jsonError)")
                // インジケータ停止
                self.stopProcessing()
                return
            }
            
            // TimeLine出力
            print("TimeLine Response: \(self.timeLineArray)")
            
            // TimeLineの配列のパース
            self.statusArray = self.parseJSON(self.timeLineArray)
            
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
            
            // 接続後テーブルビューの再描画をしないとセルのメッセージが書き変わらない。
            self.tableView.reloadData() // テーブルビューの再描画
            
            // refreshTableViewの終了処理をこちらに移動
            // リフレッシュ終了　インジケータ停止
            if self.refreshControl!.refreshing {
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if timeLineArray.count == 0 {
            return 1
        } else {
            return timeLineArray.count
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TimeLineCell
        
        
        // Configure the cell...
        
        var cellText = ""
        var cellUserName = ""
        var cellImageViewImage = UIImage()
        var cellProtected = false
        
        if timeLineArray.count == 0 { // タイムラインが返ってこない時
            if httpMessage != "" { // HTTPエラーがあれば
                cellText = httpMessage
            } else { // まだ通信中なら
                cellText = "Loading..."
            }
        } else { // タイムラインが返っていれば
            // パース済みのデータをセットする
            let status = statusArray[indexPath.row]
            cellText = status.screenName
            cellUserName = status.screenName
            cellProtected = status.protected
            idStr = status.idStr
            screenName = status.screenName
            
            //　ユーザ画像の取得処理（グローバルキューで並列処理）
            dispatch_async(self.imageQueue, {
                // パース済みデータから画像URLを生成
                guard let imageUrl = NSURL(string: status.profileImageUrlHttps) else {
                    fatalError("URL error!")
                }
                // 画像URLを利用してアイコン画像取得
                do {
                    let imageData = try NSData(
                        contentsOfURL: imageUrl,
                        options:NSDataReadingOptions.DataReadingMappedIfSafe)
                    cellImageViewImage = UIImage(data: imageData)!
                } catch (let imageError) {
                    print("Image loading error: (\(imageError))")
                }
                // 画像を取得できたらセルにセットしてセルの再描画
                dispatch_async(self.mainQueue, {
                    cell.profileImageView?.image = cellImageViewImage
                    cell.setNeedsLayout() // セルのみ再描画
                })
            })
        }
        
        cell.tweetTextLabel?.text = cellText
        if cellProtected == true {
            cell.nameLabel?.text = cellUserName
        } else {
            cell.nameLabel?.text = cellUserName
        }
        cell.profileImageView?.image = UIImage(named:"blank1.png") // デフォルトは空白画像
        
        // UITableViewCellのstyleを「subtitle」にした場合
        // textLabelとdetailTextLabelが上下に並ぶ
        cell.tweetTextLabel?.font = UIFont.systemFontOfSize(14)
        cell.nameLabel?.font = UIFont.systemFontOfSize(12)
        cell.tweetTextLabel?.numberOfLines = 0 // UILabelの行数を文字数によって変える
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    //        return 140.0 // セルの高さを140ピクセルに固定する
    //    }
    
    //**
    //** タイムラインJSONパースメソッド
    //** （タイムライン配列をパースして必要なデータのみ返す）
    //** （パースに失敗したらfatal error）
    //**
    private func parseJSON(json: [AnyObject]) -> [Status] {
        return json.map { result in
            guard let text = result["text"] as? String else { fatalError("Parse error!") }
            guard let user = result["user"] as? NSDictionary else { fatalError("Parse error!") }
            guard let screenName = user["screen_name"] as? String else { fatalError("Parse error!") }
            guard let profileImageUrlHttps = user["profile_image_url_https"] as? String else { fatalError("Prase error!") }
            guard let idStr = result["id_str"] as? String else { fatalError("Prase error!") }
            guard let favorited = result["favorited"] as? Bool else { fatalError("Prase error!") }
            guard let retweeted = result["retweeted"] as? Bool else { fatalError("Prase error!")}
            guard let protected = user["protected"] as? Bool else { fatalError("Prase error!")}
            
            return Status(
                text: text,
                screenName: screenName,
                profileImageUrlHttps: profileImageUrlHttps,
                idStr: idStr,
                favorited: favorited,
                retweeted: retweeted,
                protected: protected
            )
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        switch segue.destinationViewController { // パターンマッチングでセグエ処理を分ける
        case let detailVC as DetailViewController:
            let indexPath = tableView.indexPathForSelectedRow // 選択されたセルの行番号を得る
            let status = statusArray[indexPath!.row] // パース済みデータから該当セル分を得る
            
            // セルの内容を次のVCへ引き渡す
            detailVC.text = status.text
            detailVC.screenName = status.screenName
            detailVC.idStr = status.idStr
            detailVC.twitterAccount = twitterAccount
            detailVC.favorited = status.favorited
            detailVC.retweeted = status.retweeted
            detailVC.protected = status.protected
            
            // ユーザアイコン画像はStatus構造体に含まれないので、該当セルの画像を使う
            print("indexPath.row = \(indexPath!.row)")
            let cell = tableView.cellForRowAtIndexPath(indexPath!) as! TimeLineCell
            detailVC.profileImage = cell.profileImageView.image!
            print("\(detailVC.profileImage) + aiueo")
            
        default:
            print("Segue has no parameters.")
        }
    }

}
