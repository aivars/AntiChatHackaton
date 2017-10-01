//
//  messageItem.swift
//  AntiChatHackaton
//
//  Created by Aivars Meijers on 10.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//

import Foundation

struct MessageItem {
    var username: String
    var message: String
    
}

func messageItemToDictionary(_ chatmessage : MessageItem) -> [String : NSString]{
    return [
        //"uuid": NSString(string: chatmessage.uuid),
        "username": NSString(string: chatmessage.username),
        "message": NSString(string: chatmessage.message)
    ]
}

func dictToMessage (dictionary: Dictionary<String, NSString>) -> MessageItem {
    var parsedMessage = ""
    var parsedUsername = "Anonymos"
    for each in dictionary {
        if each.key == "message" || each.key == "text" || each.key == "chatMsg"  {
            parsedMessage = each.value as String
        } else {
            parsedMessage = "Incorect message format"
        }
        if each.key == "username" || each.key == "sender" || each.key == "author" || each.key == "name" || each.key == "senderName" {
            parsedUsername = each.value as String
        }
    }
    
    
    return MessageItem(username: parsedUsername, message: parsedMessage)
   
}

func dictToJSQMessage (dictionary: Dictionary<String, NSString>) -> JSQMessage{
    var parsedMessage = ""
    var parsedUsername = "Anonymos"
    for each in dictionary {
        if each.key == "message" || each.key == "text" || each.key == "chatMsg"  {
            parsedMessage = each.value as String
        } else {
            parsedMessage = "Incorect message format"
        }
        if each.key == "username" || each.key == "sender" || each.key == "author" || each.key == "name" || each.key == "senderName" {
            parsedUsername = each.value as String
        }
    }
    let message = JSQMessage(senderId: parsedUsername, displayName: parsedUsername, text: parsedMessage)
    return message!
    
}

