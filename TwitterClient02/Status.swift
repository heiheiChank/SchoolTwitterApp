//
//  Status.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/20.
//  Copyright © 2016年 JEC. All rights reserved.
//

import Foundation

struct Status {
    var text: String
    var screenName: String
    var profileImageUrlHttps: String
    var idStr: String
    var favorited: Bool
    var retweeted: Bool
    var protected: Bool
}