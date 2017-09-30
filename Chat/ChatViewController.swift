//
//  ChatViewController.swift
//  AntiChatHackaton
//
//  Created by Aivars Meijers on 09.09.17.
//  Copyright © 2017. g. Aivars Meijers. All rights reserved.
//

import UIKit
//import PubNub <- bridge header is used for iOS7 support



class ChatViewController: UIViewController, PNObjectEventListener, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var client: PubNub?
    var localMesageStorage: [MessageItem] = []
    
    var userName = "Aivars 💻" // <<-- hardcoded user name, replace with "" if you like to be anonymous
    var channelName = "antichat_hackathon" // <<-- Hardcoded chat channel used for hackaton
    
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var userCount: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Connection to the chat cahnel, UI update
        initiation()
        getStatistisc()
        
        //Fetch and print in log channel history
        chanelHistory()
        
        //keyboard handling
        view.bindtoKeyboard()
        chatTextField.delegate = self
        
        //Screen taping recognizing
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
        sendButton.isEnabled = false
        
        //Autosize table view cells for iOS 8
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 44.0
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableViewUpdateAndScroll()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func initiation()  {
        // welcome message
        localMesageStorage.append(MessageItem(username: "🤖", message: "Hi there, this is test message from the chat bot. Nice to meet you here. You can see active user count on the top of the screen, if you see more than zero you are lucky and can talk with real person"))
        // Initialize and configure PubNub client instance to acess antichat_hackathon channel
        let configuration = PNConfiguration(publishKey: "pub-c-8ecaf827-b81c-4d89-abf0-d669cf6da672", subscribeKey: "sub-c-a11d1bc0-ce50-11e5-bcee-0619f8945a4f")
        self.client = PubNub.clientWithConfiguration(configuration)
        configuration.uuid = userName
        configuration.presenceHeartbeatValue = 30
        configuration.presenceHeartbeatInterval = 10
        
        self.client?.addListener(self)
        self.client?.subscribeToChannels([channelName], withPresence: false)
    }
    
    func getStatistisc() {
        // With .UUID client will pull out list of unique identifiers and occupancy information.
        self.client?.hereNowForChannel(channelName, withVerbosity: .UUID,
                                       completion: { (result, status) in
                                        if status == nil {
                                            if let users = result?.data.occupancy {
                                                self.userCount.text = String(describing: users)
                                            }
                                        }
                                        else {
                                            status?.retry()
                                        }
        })
    }
    
    //fetch channel history
    func chanelHistory(){
        
        client?.historyForChannel(channelName, withCompletion: { (result, status) in
            if status == nil {
                // #To-Do parse and display chanel history
                print(result?.data.messages as Any)
                
            }
            else {
                print(status?.errorData as Any)
            }
        })
    }
    
    // Handle new message from one of channels on which client has been subscribed.
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        guard let receivedMessage = message.data.message else {
            print("No payload received")
            return
        }
        //print mesages
        print("Received message: \(receivedMessage) on channel " +
            "\((message.data.subscription ?? message.data.channel)!) at time: " +
            "\(message.data.timetoken)")
        
        //parse  and save messages
        localMesageStorage.append((dictToMessage(dictionary: receivedMessage as! Dictionary<String, NSString>)))
        
        //Update message list on the screen
        tableViewUpdateAndScroll()
    }
    
    @objc func handleScreenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        sendButton.isEnabled = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    
    @IBAction func onSendButton(_ sender: UIButton) {
        if chatTextField.text != "" {
            let messagePost = MessageItem(username: userName, message: chatTextField.text!)
            let newDict = messageItemToDictionary(messagePost)
            print(newDict)
            self.client?.publish(newDict, toChannel: channelName,
                                 compressed: false, withCompletion: { (status) in
                                    if !status.isError {
                                        // Message successfully published to specified channel.
                                        print("Sucessfully published message")
                                        self.chatTextField.text = ""
                                        //hide keyboard, disable send button
                                        self.chatTextField.resignFirstResponder()
                                        self.sendButton.isEnabled = false
                                        
                                    }
                                    else{
                                        print("ERROR - SENDING MESSAGE FAILED")
                                        print(status)
                                    }
            })
        }
    }
    
    
    //MARK: - TableView
    
    // func for table view update and automatically scroling
    func tableViewUpdateAndScroll(){
        self.tableView.reloadData()
        print("In table view update \(localMesageStorage)")
        let numberOfSections = self.tableView.numberOfSections
        let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections - 1)
        
        let indexPath = IndexPath(row: numberOfRows - 1 , section: numberOfSections - 1)
        self.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.bottom, animated: true)
        
        //update statistics after each post/refresh
        getStatistisc()
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return localMesageStorage.count
    }
    
    // There is just one row in every section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Set the spacing between sections
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MessageTableViewCell
        let message = localMesageStorage[indexPath.section]
        cell.messageLabel.text = message.message
        cell.messageLabel.textColor = UIColor.white
        cell.userNameLabel.text = "\(message.username): "
        cell.userNameLabel.textColor = UIColor.gray
        
        cell.backgroundColor = UIColor.purple
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 20
        cell.clipsToBounds = true
        
        return cell
    }
}
