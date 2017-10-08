//
//  messageItem.swift
//  AntiChatHackaton
//
//  Created by Aivars Meijers on 10.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//

import Foundation

struct MessageItem {
    var senderId: String
    var username: String
    var message: String
    var media: String
}

///////////// functions used for JSQMessage procesing //////////////////////
func dictToJSQMessage (dictionary: Dictionary<String, Any>) -> JSQMessage{
    var parsedMessage = "Incorect message format"
    var parsedUsername = "Anonymos"
    var parsedMediaUrl = ""
    
    for each in dictionary {
        if each.key == "message" || each.key == "text" || each.key == "chatMsg"  {
            parsedMessage = each.value as! String
        }
        if each.key == "username" || each.key == "sender" || each.key == "name" || each.key == "senderName" {
            parsedUsername = each.value as! String
        }
        if each.key == "media" || each.key == "stickers"{
            parsedMediaUrl = each.value as! String
        }
    }
    if parsedMediaUrl != ""{
        let photo = JSQPhotoMediaItem(image: nil)
                    let fileUrl = parsedMediaUrl
                    let downloader = SDWebImageDownloader.shared()
        downloader?.downloadImage(with: URL(string: fileUrl)!, options: [], progress: nil, completed: { (image, data, error, finished) in
                        DispatchQueue.main.async(execute: {
                            photo?.image = image
                        })
                    })
        let message = JSQMessage(senderId: parsedUsername, displayName: parsedUsername, media: photo)
        //print("JSQMessage madia message: \(message)")
        return message!
    } else {
        let message = JSQMessage(senderId: parsedUsername, displayName: parsedUsername, text: parsedMessage)
        //print("JSQMessage: \(message)")
        return message!
    }
    
}
