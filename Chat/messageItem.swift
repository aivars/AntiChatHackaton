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

///////////// functions used for JSQMessage procesing //////////////////////

func dictToJSQMessage (dictionary: Dictionary<String, Any>) -> JSQMessage{
    var parsedMessage = "Incorect message format"
    var parsedUsername = "Anonymos"
    for each in dictionary {
        if each.key == "message" || each.key == "text" || each.key == "chatMsg"  {
            parsedMessage = each.value as! String
            print("Parsed message in dictionary: \(each.value)")
        }
        if each.key == "username" || each.key == "sender" || each.key == "name" || each.key == "senderName" {
            parsedUsername = each.value as! String
            print("parsed uer name: \(parsedUsername)")
        }

    }
    let message = JSQMessage(senderId: parsedUsername, displayName: parsedUsername, text: parsedMessage)
    print(message as Any)
    return message!
}



///////////////// legacy functions used for custom UI. Can be removed as soon as ChatView is not supported //////////

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


