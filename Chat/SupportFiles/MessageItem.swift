//
//  messageItem.swift
//  AntiChatHackaton
//
//  Created by Aivars Meijers on 10.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//

import Foundation

//Struct is depricated as JSQMessages are used
struct ParsedMessageItem {
    var senderId: String
    var username: String
    var message: String
    var media: String
}

///////////// functions used for JSQMessage procesing //////////////////////
func dictToMessage (dictionary: Dictionary<String, Any>) -> ParsedMessageItem{ //JSQMessage{
    var parsedMessage = "Incorect message format"
    //var parsedSenderId = "Anonymos"
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
    let message = ParsedMessageItem(senderId: parsedUsername, username: parsedUsername, message: parsedMessage, media: parsedMediaUrl)
    return message
}
