//
//  MessagesViewController.swift
//  Chat
//
//  Created by Aivars Meijers on 30.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//

import UIKit
import Firebase

class MessagesViewController: JSQMessagesViewController, PNObjectEventListener, STKStickerControllerDelegate {
    
    var messagesArray = [JSQMessage]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    var client: PubNub?
    var channelName = "antichat_hackathon" // <<-- Hardcoded chat channel used for hackaton
    var userName = "Aivars" // <<-- hardcoded user name will be overvrited on login
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://socialnetwork-1dded.appspot.com")
    //private let imageURLNotSet = "NOTSET"
    var statisticLabel = UILabel(frame: CGRect(x: 10, y: 35, width: 300, height: 16))
    var stickerController: STKStickerController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initiation()
        chanelHistory()
        updateUI()
        initStickers()
    }
    
    func updateUI() {
        senderId = userName //Auth.auth().currentUser?.uid
        senderDisplayName = userName
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        automaticallyScrollsToMostRecentMessage = true
        collectionView.backgroundColor = UIColor.black
        //   self.collectionView?.collectionViewLayout.sectionInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        // Add view on top for custome labels
        let selectableView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 60))
        selectableView.backgroundColor = .black
        statisticLabel.textColor = UIColor.white
        statisticLabel.text = "Users on channel: 0"
        selectableView.addSubview(statisticLabel)
        view.addSubview(selectableView)
    
    }

    
    
    // MARK: - PubNub
    func initiation()  {
        let configuration = PNConfiguration(publishKey: "pub-c-8ecaf827-b81c-4d89-abf0-d669cf6da672", subscribeKey: "sub-c-a11d1bc0-ce50-11e5-bcee-0619f8945a4f")
        self.client = PubNub.clientWithConfiguration(configuration)
        configuration.uuid = userName
        configuration.presenceHeartbeatValue = 30
        configuration.presenceHeartbeatInterval = 10
        self.client?.addListener(self)
        self.client?.subscribeToChannels([channelName], withPresence: false)
        self.client?.subscribeToPresenceChannels([channelName])
        getStatistisc()
    }
    //fetch channel history
    func chanelHistory(){
        client?.historyForChannel(channelName, withCompletion: { (result, status) in
            if status == nil {
                //print(result?.data.messages as Any)
                for message in (result?.data.messages)! {
                    do {
                        let messageDictionary = try message as? Dictionary<String, Any>
                        if messageDictionary != nil {
                            self.parseAndDisplayMessages(message: messageDictionary!)
                            
                        }
                    } catch {
                       print("error in mesage parsing for: \(message)")
                    }
                }
//                self.finishReceivingMessage()
//                self.collectionView.reloadData()
            }
            else {
                print(status?.errorData as Any)
            }
        })
    }
    // Update active users value on join,leave, etc events
    func client(_ client: PubNub, didReceivePresenceEvent event: PNPresenceEventResult) {
        getStatistisc() // Occupancy also can be used as value, could be tested later
        // refresh frequency limit can be used for production, not actual for such quite channel
    }

    func getStatistisc() {
        // With .UUID client will pull out list of unique identifiers and occupancy information.
        self.client?.hereNowForChannel(channelName, withVerbosity: .UUID,
           completion: { (result, status) in
            if status == nil {
                if let users = result?.data.occupancy {
                    self.statisticLabel.text = "Users on channel: \(String(describing: users))"
                }
            } else {
                status?.retry()
            }
        })
    }
    
    // Handle new message from one of channels on which client has been subscribed.
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        guard let receivedMessage = message.data.message else {
            print("No payload received")
            return
        }
        parseAndDisplayMessages(message: receivedMessage as! Dictionary<String, Any>)

        self.collectionView.reloadData()
        self.finishReceivingMessage()
        print(receivedMessage)
    }
    
    func parseAndDisplayMessages( message: Dictionary<String, Any>) {
        let parsedMesage = dictToMessage(dictionary: message )
        print(parsedMesage)
        if parsedMesage.media != "" { //This is media message
            let fileUrl = parsedMesage.media
            let downloader = SDWebImageDownloader.shared()
//             print("parsedMesage for proesing ================= \(parsedMesage)")
            downloader?.downloadImage(with: URL(string: fileUrl)!, options: [], progress: nil, completed: { (downloadedImage, data, error, finished) in
                DispatchQueue.main.async(execute: {
                    let isImageDonwloaded = downloadedImage != nil
                    if isImageDonwloaded {
                        let mediaData = ConvertMediaItem(image: downloadedImage!)
                        if let imageView = mediaData?.mediaView() as? UIImageView {
                            imageView.contentMode = .scaleAspectFit
                        }
                        let message = JSQMessage(senderId: parsedMesage.senderId, displayName: parsedMesage.username, media: mediaData)!
//                        print(message)
                        self.messagesArray.append(message)
                        self.finishSendingMessage(animated: true)
                        
                    }
                })
            })
        } else if parsedMesage.message != "Incorect message format" {
                // This is correctly parsed text message and worth displaying
                let message = JSQMessage(senderId: parsedMesage.senderId, displayName: parsedMesage.username, text: parsedMesage.message)!
//                print(message)
                self.messagesArray.append(message)
                self.finishSendingMessage(animated: true)
            
        }
         print(messagesArray)        

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private class ConvertMediaItem: JSQPhotoMediaItem {
        override func mediaView() -> UIView! {
            let view = super.mediaView()
            view?.contentMode = .scaleAspectFit
            return view
        }
    }

    
    // MARK: - Configure collectionView for message displaying
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.brown)
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.purple)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messagesArray[indexPath.item] //mesage retrieved
        if message.senderId == senderId { // local user message
            return outgoingBubbleImageView
        } else { // income message
            return incomingBubbleImageView
        }
    }
    
    //remove avatars
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messagesArray[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messagesArray.count
    }
    // mesage pushing to the chanel
    func publishMessage(message: Dictionary<String, Any>) {
        self.client?.publish(message, toChannel: channelName,
                             compressed: false, withCompletion: { (status) in
                                if !status.isError {
                                    // Message successfully published to specified channel.
                                    JSQSystemSoundPlayer.jsq_playMessageSentSound() // message sent sound
                                    //print("Sucessfully published message")
                                }
                                else{
                                    print("ERROR - SENDING MESSAGE FAILED")
                                    print(status)
                                }
        })
        finishSendingMessage(animated: true)
    }
    
    // MARK : Message procesing
    // publish on send button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let messageItem = [ // dictionary for message presenting
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,]
        publishMessage(message: messageItem)
    }
    
    // Open image picker
    override func didPressAccessoryButton (_ sender: UIButton){
        print("acessory Button presed")
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    // Send media messages
    func sendMedia(_ picture: UIImage?, video: URL?) {
        if let picture = picture {
            let filePath = "\(String(describing: Auth.auth().currentUser))/\(Date.timeIntervalSinceReferenceDate)"
            print("filePath: \(filePath)")
            let data = UIImageJPEGRepresentation(picture, 0.1)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpg"
            Storage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error)
                in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                let fileUrl = metadata!.downloadURLs![0].absoluteString
                print("File url: \(fileUrl)")
                // push media to channel
                let messageItem = [ // dictionary for message presenting
                    "senderId": self.senderId!,
                    "senderName": self.senderDisplayName!,
                    "media": fileUrl]
                self.publishMessage(message: messageItem)
            }
            // TODO - finalise function for video handling
        }
    }
    
    //Add black bacgroud to the image
    func makeSticker(_ result: UIImage) -> UIImage? {
        let newSize = CGSize(width: 400, height: 300)
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIColor.black.setFill()
        UIRectFill(rect)
        let giftSizeH: CGFloat = newSize.height*0.85
        let giftSizeW: CGFloat = result.size.width/result.size.height*giftSizeH
        let xGiftPos = (newSize.width - giftSizeW) / 2
        let yGiftPos = (newSize.height - giftSizeH) / 2
        result.draw(in: CGRect(x: xGiftPos,y: yGiftPos,width: giftSizeW,height: giftSizeH), blendMode: CGBlendMode.normal, alpha:1.0)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // MARK: Stickers
    func initStickers () {
        STKStickersManager.initWithApiKey("a575ae0e0b50ccc8ced80cabb9e20984")  //("6b5d54b800f7abd411523a7634e4a581")
        STKStickersManager.setStartTimeInterval()
        STKStickersManager.setUserKey(userName)
        stickerController = STKStickerController()
        stickerController.delegate = self
        stickerController.textInputView = keyboardController.textView
    }
    
    func stickerController(_ stickerController: STKStickerController!, didSelectStickerWithMessage message: String!) {
        stickerController.imageManager.getImageForStickerMessage(message, withProgress: nil) {
            (error: Error?, image: UIImage?) in
            self.sendMedia(self.makeSticker(image!), video: nil) // <-- Sticker gets black bacground and is sent to the server
            stickerController.hideStickersView()
        }
    }
    func stickerControllerViewControllerForPresentingModalView() -> UIViewController! {
        return self
    }

}

// MARK: Image Picker Delegate
extension MessagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print(info)
        print("did finish picking image")
        // get the image
        print(info)
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendMedia(picture, video: nil)
        }
        self.dismiss(animated: true, completion: nil)
    }
}
