//
//  MessagesViewController.swift
//  Chat
//
//  Created by Aivars Meijers on 30.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//




import UIKit

class MessagesViewController: JSQMessagesViewController, PNObjectEventListener {
    
    var messagesArray = [JSQMessage]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    var client: PubNub?
    var channelName = "antichat_hackathon" // <<-- Hardcoded chat channel used for hackaton
    var userName = "Aivars" // <<-- hardcoded user name
    var statisticLabel = UILabel(frame: CGRect(x: 10, y: 35, width: 200, height: 16))

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initiation()
        
//        let n = Int(arc4random_uniform(1000))
//        senderId = "Anonymous" + String(n)
        senderId = "Aivars" // <- should be generated and stored for randome value
        senderDisplayName = userName
        
        // === UI changes ===
        // remove image posting button
        inputToolbar.contentView.leftBarButtonItem = nil
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        automaticallyScrollsToMostRecentMessage = true
        self.collectionView.backgroundColor = UIColor.black
        self.collectionView?.collectionViewLayout.sectionInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
        // Add view on top for custome labels
        let selectableView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 60))
        selectableView.backgroundColor = .black
        statisticLabel.textColor = UIColor.white
        statisticLabel.text = "Users on channel: 0"
        selectableView.addSubview(statisticLabel)
        view.addSubview(selectableView)
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
                // #To-Do parse and display chanel history
                //print(result?.data.messages as Any)
                for message in (result?.data.messages)! {
                    print("message in results: \(message)")
                    self.messagesArray.append(dictToJSQMessage(dictionary: message as! Dictionary<String, AnyObject>))
                    self.finishReceivingMessage()

                }
            }
            else {
                print(status?.errorData as Any)
            }
        })
        
    }
    // Update active users value on joi,leave, etc events
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
        print(messageItem)
        self.client?.publish(messageItem, toChannel: channelName,
                             compressed: false, withCompletion: { (status) in
                                if !status.isError {
                                    // Message successfully published to specified channel.
                                    JSQSystemSoundPlayer.jsq_playMessageSentSound() // message sent sound
                                    print("Sucessfully published message")
                                }
                                else{
                                    print("ERROR - SENDING MESSAGE FAILED")
                                    print(status)
                                }
        })
        finishSendingMessage()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}


