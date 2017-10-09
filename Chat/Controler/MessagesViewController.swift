//
//  MessagesViewController.swift
//  Chat
//
//  Created by Aivars Meijers on 30.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//




import UIKit
import Firebase
//import Photos

class MessagesViewController: JSQMessagesViewController, PNObjectEventListener, STKStickerControllerDelegate {
    
    var messagesArray = [JSQMessage]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    var client: PubNub?
    var channelName = "antichat_hackathon" // <<-- Hardcoded chat channel used for hackaton
    var userName = "Aivars" // <<-- hardcoded user name will be overvrited on login
    lazy var storageRef: StorageReference = Storage.storage().reference(forURL: "gs://socialnetwork-1dded.appspot.com")
    private let imageURLNotSet = "NOTSET"
    var statisticLabel = UILabel(frame: CGRect(x: 10, y: 35, width: 300, height: 16))
    var stickerController: STKStickerController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initiation()
        
        senderId = userName //Auth.auth().currentUser?.uid
        senderDisplayName = userName
        
        // === UI changes ===
        // remove image posting button
        //inputToolbar.contentView.leftBarButtonItem = nil
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        automaticallyScrollsToMostRecentMessage = true
        self.collectionView.backgroundColor = UIColor.black
        self.collectionView?.collectionViewLayout.sectionInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        // Add view on top for custome labels
        let selectableView = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 60))
        selectableView.backgroundColor = .black
        statisticLabel.textColor = UIColor.white
        statisticLabel.text = "Users on channel: 0"
        selectableView.addSubview(statisticLabel)
        view.addSubview(selectableView)
        
        //Stickers
        initStickers()
        
        // Layout improvements for iPhone X design
        print(" // Layout improvements for iPhone X design")
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraintEqualToSystemSpacingBelow(guide.topAnchor, multiplier: 1.0),
                guide.bottomAnchor.constraintEqualToSystemSpacingBelow(inputToolbar.bottomAnchor, multiplier: 1.0)
                ])
            }
        print(" // Layout improvements for iPhone X design")
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        chanelHistory()
        finishReceivingMessage()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
                print(result?.data.messages as Any)
                for message in (result?.data.messages)! {
                    do {
                        let messageDictionary = try message as? Dictionary<String, Any>
                        if messageDictionary != nil {
                            self.messagesArray.append(dictToJSQMessage(dictionary : messageDictionary!))
                            self.finishReceivingMessage()
                            self.collectionView.reloadData()
                        }
                    } catch {
                       print("error in mesage parsing for: \(message)")
                    }
                }
            }
            else {
                print(status?.errorData as Any)
            }
        })
        //self.finishReceivingMessage()
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
        messagesArray.append((dictToJSQMessage(dictionary: receivedMessage as! Dictionary<String, String>)))
        self.finishReceivingMessage()
    }
    
    // MARK: - Configure collectionView for message displaying
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.purple)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messagesArray[indexPath.item] //mesage retrieved
        if message.senderId == senderId { // locel user message
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
    
    // MARK : Message procesing
    // publish on send button
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let messageItem = [ // dictionary for message presenting
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,]
        self.client?.publish(messageItem, toChannel: channelName,
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
        finishSendingMessage()
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
                    //"text": text!,
                    "media": fileUrl]
                self.client?.publish(messageItem, toChannel: self.channelName,
                                     compressed: false, withCompletion: { (status) in
                                        if !status.isError {
                                            // Message successfully published to specified channel.
                                            JSQSystemSoundPlayer.jsq_playMessageSentSound() // message sent sound
                                            print("Sucessfully published message")
                                            print(messageItem)
                                        }
                                        else{
                                            print("ERROR - SENDING MESSAGE FAILED")
                                            print(status)
                                        }
                })
                self.finishSendingMessage()
            }
            // TODO - implement video sending
        }
    }
    
    // MARK: Stickers
    func initStickers () {
        STKStickersManager.initWithApiKey("6b5d54b800f7abd411523a7634e4a581")
        STKStickersManager.setStartTimeInterval()
        STKStickersManager.setUserKey(userName)
        stickerController = STKStickerController()
        stickerController.delegate = self
        stickerController.textInputView = keyboardController.textView
    }
    
    func stickerController(_ stickerController: STKStickerController!, didSelectStickerWithMessage message: String!) {
        stickerController.imageManager.getImageForStickerMessage(message, withProgress: nil) {
            (error: Error?, image: UIImage?) in
            self.sendMedia(image, video: nil)
            stickerController.hideStickersView()
            //self.dismiss(animated: true, completion: nil)
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

