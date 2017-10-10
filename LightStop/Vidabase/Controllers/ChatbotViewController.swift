//
//  ChatbotViewController.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/8/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import MapKit
import Photos

// MARK: - Implementation
class ChatbotViewController: JSQMessagesViewController {
    
    // MARK: Properties
    var loggedUser:User?
    var contactUser:[String:AnyObject]?
    var locationManager = CLLocationManager()   // Property for Location Manager Object
    var currentLocation: CLLocation?            // Property to store current found location or default location
    var currentPlacemark: CLPlacemark?          // Property to store found Placemark
    var locationMedia: JSQLocationMediaItem?
    private let imageURLNotSetKey = "NOTSET"
    var base64String:NSString!
    var imageToPresent:UIImage?
    
    let rootRef = Firebase(url: "https://vidabase.firebaseio.com/") // Set the Firebase base URL
    var messages = [JSQMessage]()                           // Initialize Messages Class
    var outgoingBubbleImageView: JSQMessagesBubbleImage!    // Property for Out Bubbles Images
    var incomingBubbleImageView: JSQMessagesBubbleImage!    // Property for In Bubbles Images
    var outgoingAvatarImageView: JSQMessagesAvatarImage!    // Property for Out Avatar Images
    var incomingAvatarImageView: JSQMessagesAvatarImage!    // Property for In Avatar Images
    var messageRef: Firebase!                               // Property to hold a reference to the Messages Directory in the URL
    var userIsTypingRef: Firebase!                          // Create a reference that tracks whether the local user is typing.
    fileprivate var localTyping = false                         // Store whether the local user is typing (Private Property)
    var usersTypingQuery: FQuery!                           // Property to get all users that are typing

    var isTyping: Bool {                                    // computed property, to update userIsTypingRef each time you update this property.
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }

    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set controller Title
        title = self.contactUser!["firstName"] as? String
        
        // Set ourself as delegate for JSQMessagesComposerTextViewPasteDelegate
        self.inputToolbar.contentView.textView.pasteDelegate = self

        // Specifies whether or not the view controller should show the "load earlier messages" header view
        self.showLoadEarlierMessagesHeader = true
        
        // Set a maximum height for the input toolbar
        self.inputToolbar.maximumHeight = 150

        
        // Method to setup Bubble and Avatar factory and bubble colors
        setupBubbles()
        //setupAvatar()
        
        // Set Size of the Avatar Images
        self.collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 35, height: 35)
        self.collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 35, height: 35)
        
        // Initialize reference to Messages Directory
        let charUrl = self.contactUser!["chatUrl"] as! String
        messageRef = rootRef?.child(byAppendingPath: "chats/" + charUrl + "/messages")

        
        print(self.senderId)
        print(self.senderDisplayName)
        
        //initialize locationManager, set desired accuracy, distance filter in meters, location manager delegate to self
        self.locationManager = CLLocationManager.init()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //self.locationManager.distanceFilter = 5.0f
        self.locationManager.delegate = self
        
        
        // user activated automatic authorization info mode
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined || status == .denied || status == .authorizedWhenInUse {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            // UIApplication -openUrl: and UIApplicationOpenSettingsURLString
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingHeading()
        self.locationManager.startUpdatingLocation()
        
        
        
        //        // Call Method to Observe Messages.
                observeMessages()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        // Call Method to Observe Messages.
//        observeMessages()
        
        // Call Method to Observe Typing.
        observeTyping()
        
        /**
         *  Enable/disable springy bubbles, default is NO.
         *  You must set this from `viewDidAppear:`
         *  Note: this feature is mostly stable, but still experimental
         */
        self.collectionView.collectionViewLayout.springinessEnabled = false

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Hide Status Bar
    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    // MARK: - Segue Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
            if segue.identifier == "chatToImageSegue" {
                
                guard let imageViewController = segue.destination as? ImageViewController else { return }
                imageViewController.imageToPresent = imageToPresent
            }

    }

    // MARK: - JSQMessagesViewController Data Source Methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // Get Cell for Messages
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        // Get Next Message to inspect who is owner
        let message = messages[indexPath.item]
        
        if !message.isMediaMessage {
            
            // Set colors for incoming and outgoing messages
            if message.senderId == senderId {
                cell.textView!.textColor = UIColor.white
            } else {
                cell.textView!.textColor = UIColor.black
            }
            
            cell.textView.linkTextAttributes = [NSForegroundColorAttributeName : cell.textView.textColor!, NSUnderlineStyleAttributeName : NSUnderlineStyle.styleSingle.rawValue]
        }
        
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        if action == Selector("customAction:") {
            return true
        }
        
        return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?){
        
        if action == Selector("customAction:") {
            customAction(sender! as AnyObject)
            return
        }
        
        super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
    }
    
    //Mark: - Methods for Adjusting cell label heights
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        /**
         *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
         */
        
        /**
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         *  The other label height delegate methods should follow similarly
         *
         *  Show a timestamp for every 3rd message
         */
        if (indexPath.item % 3 == 0) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault;
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        /**
         *  iOS7-style sender name labels
         */
        
        let currentMessage = self.messages[indexPath.item]
        
        if currentMessage.senderId == self.senderId {
            return 0.0
        }
        
        if (indexPath.item - 1 > 0) {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, heightForCellBottomLabelAt indexPath: IndexPath) -> CGFloat {

        return 0.0

    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("Code to Load Earlier Messages")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        print("Code to execute when Avatar Tapped")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("Tapped message bubble!")
        let message = messages[indexPath.item]
        
        if message.isMediaMessage {
            if message.media.isKind(of: JSQPhotoMediaItem.self) {
                let messageMedia = message.media as! JSQPhotoMediaItem
                imageToPresent = messageMedia.image
                performSegue(withIdentifier: "chatToImageSegue", sender: self)

            } else {
            
                let messageJS2 = message.media as! JSQLocationMediaItem
                let messageDest = messageJS2.location.coordinate
                
                let destPlacemart = MKPlacemark(coordinate:messageDest)
                let destination = MKMapItem(placemark: destPlacemart )
                
                let currentPlacemart = MKPlacemark(coordinate:(currentLocation?.coordinate)!)
                let source = MKMapItem(placemark: currentPlacemart )
                
                let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                MKMapItem.openMaps(with: [source, destination],launchOptions: launchOptions)
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapCellAt indexPath: IndexPath!, touchLocation: CGPoint) {
        print("Tapped cell at \(NSStringFromCGPoint(touchLocation))")
    }
    
// MARK: - Other Method Override
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        // Get Next Message to inspect who is owner
        let message = messages[indexPath.item]
        
        // If message is from current logged User = Outgoing
        if message.senderId == senderId {
            return self.outgoingBubbleImageView
        } else {
            return self.incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        // Get Next Message to inspect who is owner
        let message = messages[indexPath.item]
        
        // If message is from current logged User = Outgoing
        if message.senderId == senderId {
            
            if (message.avatar != nil){
                self.outgoingAvatarImageView = JSQMessagesAvatarImageFactory.avatarImage(with: message.avatar, diameter: 35)
            } else {
                self.outgoingAvatarImageView = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: Helper.getInitialsFromFullName(self.senderDisplayName), backgroundColor: Helper.UIColorFromHex(0x5CB85C), textColor: UIColor.white, font: UIFont.boldSystemFont(ofSize: 12), diameter: 35)
            }
            return self.outgoingAvatarImageView
            
        } else {
            
            if (message.avatar != nil){
                self.incomingAvatarImageView = JSQMessagesAvatarImageFactory.avatarImage(with: message.avatar, diameter: 35)
            } else {
                var name = self.contactUser!["firstName"] as? String
                self.incomingAvatarImageView = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: Helper.getInitialsFromFullName(name!), backgroundColor: UIColor.blue, textColor: UIColor.white, font: UIFont.boldSystemFont(ofSize: 12), diameter: 35)
            }
            return self.incomingAvatarImageView
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        // Generate new Child Location with unique key from Firebase
        let itemRef = messageRef.childByAutoId()
        
        // Construct a Message JSON / Dictionary to send to Firebase
        let messageItem = [
            "text": text,
            "senderId": senderId,
            "senderDisplayName":senderDisplayName,
            "date":date.timeIntervalSince1970
        ] as [String : Any]
        
        /* Save value of new message to the new Child Location
         An observer in the Firebase database notifies the app, which then add message to data store */
        itemRef?.setValue(messageItem)
        
        // Play Outgoing / Sent Sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        // Animates the sending of a new Message
        finishSendingMessage(animated: true)
        
        // Clear flag after sending message
        isTyping = false
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        // Release TextField
        self.inputToolbar.contentView.textView.resignFirstResponder()
        
        let alertController = UIAlertController(title: "Share Media", message: "Select Media Type to Share", preferredStyle: .actionSheet)
        
        let sendPhotoAction = UIAlertAction(title: "Send photo", style: .default) { (_) in
            
            let picker = UIImagePickerController()
            picker.delegate = self
            if (UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
                picker.sourceType = UIImagePickerControllerSourceType.camera
            } else {
                picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            }
            
            self.present(picker, animated: true, completion:nil)
            
        
        }
        let sendLocationAction = UIAlertAction(title: "Send location", style: .default) { (_) in self.sendLocationPressed() }
        let sendVideoAction = UIAlertAction(title: "Send video", style: .default) { (_) in self.sendVideoPressed() }
        let sendAudioAction = UIAlertAction(title: "Send audio", style: .default) { (_) in self.sendAudioPressed() }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(sendPhotoAction)
        alertController.addAction(sendLocationAction)
        alertController.addAction(sendVideoAction)
        alertController.addAction(sendAudioAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true) {
            // Additional code after presenting view controller
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        /**
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         *  The other label text delegate methods should follow a similar pattern.
         *
         *  Show a timestamp for every 3rd message
         */
        if (indexPath.item % 3 == 0) {
            
            let message = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        /**
         *  iOS7-style sender name labels
         */
        let message = self.messages[indexPath.item]
        
        if message.senderId == self.senderId {
            return nil
        }
        
        if (indexPath.item - 1 > 0 ) {
            let previousMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == self.senderId {
                return nil
            }
        }
        
        /**
         *  Don't specify attributes to use the defaults.
         */
        return NSAttributedString.init(string: message.senderDisplayName)
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {

        return nil
        
    }
    
    // MARK: - Custom Methods
    fileprivate func customAction(_ sender:AnyObject){
        
    }

    
    fileprivate func sendLocationPressed(){
        

        // Code to send user location
        if(currentLocation != nil){

            // Generate new Child Location with unique key from Firebase
            let itemRef = messageRef.childByAutoId()            

            let coordDic = ["latitude":currentLocation?.coordinate.latitude,"longitude":currentLocation?.coordinate.longitude]
            
            // Construct a Message JSON / Dictionary to send to Firebase
            let messageItem = [
                "location": coordDic,
                "senderId": senderId,
                "senderDisplayName":senderDisplayName,
                "date":Date().timeIntervalSince1970
                ] as [String : Any]
            
            
            itemRef?.setValue(messageItem)
            
            JSQSystemSoundPlayer.jsq_playMessageSentSound()

            // Animates the sending of a new Message
            finishSendingMessage(animated: true)

        }
    }
    
    fileprivate func sendVideoPressed(){
        // Code to send video
    }
    
    fileprivate func sendAudioPressed(){
        // Code so send audio
    }
    
    fileprivate func setupBubbles() {
        
        // Initialize the Bubble Factory!
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        // Set color for outgoing and incoming messages
        self.outgoingBubbleImageView = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        self.incomingBubbleImageView = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        
    }
    
    fileprivate func setupAvatar() {
        
        // Get user image
        let loggedUserImage = UIImage.init(named:"dummyUser")
        let vibot = UIImage.init(named:"Vibot")
        
        // Set color for outgoing and incoming messages
        self.outgoingAvatarImageView = JSQMessagesAvatarImageFactory.avatarImage(with: loggedUserImage, diameter: 35)
        self.incomingAvatarImageView = JSQMessagesAvatarImageFactory.avatarImage(with: vibot, diameter: 35)
        
    }
    
    func addMessage(_ id: String, text: String) {
        let message = JSQMessage(senderId: id, displayName: self.senderDisplayName, text: text)
        messages.append(message!)
    }
    
    func addMessage(withMedia media:JSQMessageMediaData) {
        let message = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: media)
        messages.append(message!)
    }
    
    func addMessage(withLocation location:JSQLocationMediaItem) {
        //let message2 = JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: media)
        let message = JSQMessage.init(senderId: self.senderId, displayName: self.senderDisplayName, media: location)
        messages.append(message!)
    }
    
    fileprivate func observeMessages() {
        
        // Limit the retrieved messages to the last 25
        let messagesQuery = messageRef.queryLimited(toLast: 25)!
        
        // Set an Event observer in the database
        messagesQuery.observe(.childAdded, with: { (snapshot: FDataSnapshot?) in
            // Get data from snapshot sent; convert to dictionary
            let value = snapshot!.value as! NSDictionary
            
            /* IF TEXT MESSAGE
            ===================*/
            if value["text"] != nil {
                
                let id = value["senderId"]
                let text = value["text"]
                
                // Call AddMessage Method to Add Message
                self.addMessage(id as! String, text: text as! String)
                
            }
            else if value["image"] != nil {
                print("Image Found")
                var imageDic = value["image"] as! [String:String]
                let base64String = imageDic["string"]! as String
                let decodedData = NSData(base64Encoded: base64String, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
                let decodedImage = UIImage(data: decodedData as! Data)
                let photo = JSQPhotoMediaItem(image: decodedImage)
                
                //let media = JSQMessage.init(senderId: self.senderId, displayName: self.senderDisplayName, media: photo)
                // Call AddMessage Method to Add Message
                self.addMessage(withMedia: photo!)
                
            } else if value["location"] != nil {
                var locationDic = value["location"] as! [String:Double]
                
                let location = CLLocation.init(latitude: locationDic["latitude"]!, longitude: locationDic["longitude"]!)
                let loc: JSQLocationMediaItem = JSQLocationMediaItem(location: location)
                
                self.addMessage(withLocation: loc)
            }
            
            /* IF IMAGE MESSAGE
             ===================*/
            
            
            // Animates de Receiving of new Messages
            self.finishReceivingMessage()
        })

    }
    
    fileprivate func observeTyping() {
        
        // Initialize reference to typingIndicator Directory
        let charUrl = self.contactUser!["chatUrl"] as! String
        let typingIndicatorRef = rootRef?.child(byAppendingPath: "chats/" + charUrl + "/typingIndicator")
        
        // Initialize reference to senderId Directory
        userIsTypingRef = typingIndicatorRef?.child(byAppendingPath: senderId)
        
        // Ensure the data at this location is removed when the client is disconnected
        userIsTypingRef.onDisconnectRemoveValue()
        
        // retrieving all users who are typing
        usersTypingQuery = typingIndicatorRef?.queryOrderedByValue().queryEqual(toValue: true)
        
        // Observe for changes using .Value; this will give you an update anytime anything changes.
        usersTypingQuery.observe(.value, with: { (data: FDataSnapshot?) in
            
            // You're the only typing, don't show the indicator
            if data?.childrenCount == 1 && self.isTyping {
                return
            }
            
            // Are there others typing?
            self.showTypingIndicator = data!.childrenCount > 0
            self.scrollToBottom(animated: true)
        })
    }
    
    // Mark: - UITextViewDelegate Methods
    override func textViewDidChange(_ textView: UITextView) {
        
        super.textViewDidChange(textView)
        
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = messageRef.child(byAppendingPath: key)
        itemRef?.updateChildValues(["photoURL": url])
    }
}

// MARK: - Extension JSQMessagesComposerTextViewPasteDelegate
extension ChatbotViewController: JSQMessagesComposerTextViewPasteDelegate {

    func composerTextView(_ textView: JSQMessagesComposerTextView!, shouldPasteWithSender sender: Any!) -> Bool {
        
        // Verify if an image is in the Pastboard
        if (UIPasteboard.general.image != nil) {
            
            // If there's an image in the pasteboard, construct a media item with that image and `send` it.
            let mediaItem = JSQPhotoMediaItem.init(image: UIPasteboard.general.image)
            
            // Construct a message with media Item
            let message = JSQMessage.init(senderId: self.senderId, senderDisplayName: self.senderDisplayName, date: Date(), media: mediaItem)
            
            // Add message to messages data source
            messages.append(message!)
            
            // Finishe sending and return
            finishSendingMessage(animated: true)
            return false
        }
        return true
    }
}

extension ChatbotViewController:CLLocationManagerDelegate{
    // MARK: - Location Methods
    func checkLocationAuthorizationStatus() {
        // Check if authorization to get user location was granted; if not, then ask
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // If location is enabled, setup accuracy and request user location.
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //location value to save in DB periodically
        currentLocation = locations.last!
        
        locationManager.stopUpdatingLocation()

    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // If there is an error we will fail silently, since this will not affect the user experience or UI
        // functionallity
        print("Error: \(error)")
    }

}

// MARK: Image Picker Delegate
extension ChatbotViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        let picture = info[UIImagePickerControllerOriginalImage] as? UIImage
        let imageData: NSData = UIImageJPEGRepresentation(picture!, 0.5)! as NSData
        
        // Generate new Child Location with unique key from Firebase
        let itemRef = messageRef.childByAutoId()
        
        self.base64String = imageData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters) as NSString!
        let quoteString = ["string":self.base64String]
        
        // Construct a Message JSON / Dictionary to send to Firebase
        let messageItem = [
            "image": quoteString,
            "senderId": senderId,
            "senderDisplayName":senderDisplayName,
            "date":Date().timeIntervalSince1970
            ] as [String : Any]
        
        
        itemRef?.setValue(messageItem)


        // Animates the sending of a new Message
//        finishSendingMessage(animated: true)
        picker.dismiss(animated: true, completion:nil)

        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}
