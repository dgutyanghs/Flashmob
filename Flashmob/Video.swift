//
//  Video.swift
//  Flashmob
//
//  Created by  BlueYang on 2017/6/27.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Video {
    let cover:String
    let desc:String
    let index:Int
    let title:String
    let mp4_url: String
    var  progress: Float = 0
    
    
     static func generateModel(with json:JSON) -> [Video] {
        let items = json["flashmobinfolist"]
        var info:[Video] = []
        
        for (_, subjson):(String, JSON) in items {
            
            let cover:String    = subjson["cover"].stringValue
            let desc:String     = subjson["desc"].stringValue
            let index:Int       = subjson["index"].intValue
            let title:String    = subjson["title"].stringValue
            let mp4_url:String  = subjson["mp4_url"].stringValue
            
            
            let videoItem = Video(cover: cover, desc: desc, index: index, title: title, mp4_url:mp4_url,  progress: 0)
            
            info.append(videoItem)
        }
        
        return info
    }
    
    mutating func setProgress(value: Float) {
        self.progress = value
    }
}


/// Struct 数据存储Plist
protocol PropertyListReadable {
    func propertyListRepresentation() -> NSDictionary
    
    init?(propertyListRepresentation:NSDictionary?)
    
}


extension Video: PropertyListReadable {
    
    func propertyListRepresentation() -> NSDictionary {
        let representation: [String: AnyObject] = ["index": self.index as AnyObject,
                                                   "cover": self.cover as AnyObject,
                                                   "desc":  self.desc  as AnyObject,
                                                   "title": self.title as AnyObject,
                                                   "mp4_url":self.mp4_url as AnyObject,
                                                   "progress":self.progress as AnyObject
                                                   ]
       return representation as NSDictionary
    }
    
    init?(propertyListRepresentation: NSDictionary?) {
        guard let values = propertyListRepresentation else { return nil }
        
        if let index = values["index"] as? Int ,
            let title = values["title"] as? String,
            let cover = values["cover"] as? String,
            let desc = values["desc"] as? String,
            let mp4_url = values["mp4_url"] as? String,
            let progress = values["progress"] as? Float   {
                
                self.index = index
                self.title = title
                self.cover = cover
                self.desc =  desc
                self.mp4_url = mp4_url
                self.progress = progress
        } else {
            return nil
        }
    }
    
    
    static func extractValuesFromPropertyListArray<T:PropertyListReadable>(propertyListArray:[AnyObject]?) -> [T] {
        guard let encodedArray = propertyListArray else { return [] }
        return encodedArray.map{ $0 as? NSDictionary }.flatMap{ T(propertyListRepresentation:$0) }
    }

    static func saveValuesToDefaults<T:PropertyListReadable>(newValues:[T], key:String) {
        let encodedValues = newValues.map{ $0.propertyListRepresentation() }
        UserDefaults.standard.set(encodedValues, forKey: key)
    }
}

