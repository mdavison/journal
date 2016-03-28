//
//  EntryViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit
import TwitterKit

class EntryViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var entryItemsTabBar: UITabBar!
    @IBOutlet weak var facebookView: UIView!
    @IBOutlet weak var facebookTableView: UITableView!
    @IBOutlet weak var twitterView: UIView!
    @IBOutlet weak var twitterTableView: UITableView!
    @IBOutlet weak var noDataFacebookLabel: UILabel!
    @IBOutlet weak var noDataTwitterLabel: UILabel!
    @IBOutlet weak var twitterActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var facebookActivityIndicator: UIActivityIndicatorView!
    
    var coreDataStack: CoreDataStack!
    var entry: Entry?
    var facebookPosts = [AnyObject]()
    var twitterTweets: [TWTRTweet] = [] {
        didSet {
            twitterTableView.reloadData()
        }
    }
    
    struct Storyboard {
        static var FacebookViewIdentifier = "FacebookView"
        static var EntryDateSegueIdentifier = "EntryDate"
        static var FacebookPostCellReuseIdentifier = "FacebookPostCell"
        static var TwitterTweetCellReuseIdentifier = "TwitterTweetCell"
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        entryTextView.delegate = self
        setupView()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(EntryViewController.entryWasDeleted(_:)), name: EntryWasDeletedNotificationKey, object: entry)
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            // User already has access token
            getFacebookPosts()
            
        } else {
            //showLoginButton()
            // TODO: Show exclamation badge on Facebook tab
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITextViewDelegate Methods
    
    func textViewDidChange(textView: UITextView) {
        saveButton.enabled = true
        saveButton.title = "Save"
    }


    
    // MARK: - Actions
    
    @IBAction func save(sender: UIBarButtonItem) {
        if let entry = entry {
            // Save existing
            entry.created_at = getButtonDate()
            entry.updated_at = NSDate()
            entry.text = entryTextView.text
            
            coreDataStack.saveContext()
        } else {
            // Create new
            let entryEntity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: coreDataStack.managedObjectContext)
            entry = Entry(entity: entryEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            entry?.created_at = getButtonDate()
            entry?.text = entryTextView.text
            
            coreDataStack.saveContext()
        }
        
        saveButton.enabled = false
        saveButton.title = "Saved"
        setDateButton(withEntry: entry)
        title = "Journal Entry"
    }
    
    
    // MARK: - Notification Handling
    
    func entryWasDeleted(notification: NSNotification) {
        if let notificationEntry = notification.object as? Entry {
            if notificationEntry == entry {
                entry = nil
                setupView()
            }
        }
    }
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EntryDateSegueIdentifier:
                guard let navController = segue.destinationViewController as? UINavigationController,
                    let controller = navController.topViewController as? EntryDateViewController else { return }
                
                controller.delegate = self
                
            default:
                return 
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
        entryItemsTabBar.selectedItem = entryItemsTabBar.items![0]
        
        if let entry = entry {
            setDateButton(withEntry: entry)
            entryTextView.text = entry.text
        } else {
            saveButton.enabled = false
            setDateButton(withEntry: nil)
            entryTextView.text = ""
            title = "New Entry"
        }
        
        twitterTableView.estimatedRowHeight = 150
        twitterTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    private func setDateButton(withEntry entry: Entry?) {
        if let entry = entry {
            let formatter = getFormatter()
            dateButton.setTitle(formatter.stringFromDate(entry.created_at!), forState: .Normal)
        } else {
            let formatter = getFormatter()
            dateButton.setTitle(formatter.stringFromDate(NSDate()), forState: .Normal)
        }
    }
    
    private func setDateButton(withDate date: NSDate) {
        let formatter = getFormatter()
        
        dateButton.setTitle(formatter.stringFromDate(date), forState: .Normal)
    }
    
    private func getButtonDate() -> NSDate {
        let formatter = getFormatter()
        let buttonDate = formatter.dateFromString(dateButton.currentTitle!)
        if let date = buttonDate {
            return date
        }
        
        return NSDate()
    }
    
    private func getFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter
    }
    
    
    // MARK: - Facebook
    
    private func showFBLoginButton() {
        let loginButton = FBSDKLoginButton()
        loginButton.center = view.center
        loginButton.readPermissions = ["email", "user_posts"]
        view.addSubview(loginButton)
        loginButton.delegate = self
    }
    
    private func getFacebookPosts() {
        let timestamps = getEntryTimestamps()
        
        let parameters = ["fields": "id, name, email, posts.since(\(timestamps["since"]!)).until(\(timestamps["until"]!)){story,created_time,id,message,picture,likes}"]
        let request = FBSDKGraphRequest(graphPath: "me", parameters: parameters)
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        // TODO: I think this needs to be put on a background thread
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            request.startWithCompletionHandler({ (connection, result, error) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if error != nil {
                    print(error)
                } else {
                    guard let posts = result["posts"],
                        let unwrappedPosts = posts,
                        let data = unwrappedPosts["data"] as? NSMutableArray else { return }
                    
                    for i in 0..<data.count {
                        //                    print(data[i])
                        //                    print("================= separator ===================")
                        self.facebookPosts.append(data[i])
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Back on main thread
                    print("back on main thread")
                    
                    self.facebookActivityIndicator.stopAnimating()
                    
                    if self.facebookPosts.isEmpty {
                        self.noDataFacebookLabel.hidden = false
                    } else {
                        self.facebookTableView.hidden = false
                        self.facebookTableView.reloadData()
                    }
                })
            })
            
        
        //}
        
//        request.startWithCompletionHandler({ (connection, result, error) -> Void in
//            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//            if error != nil {
//                print(error)
//            } else {
//                guard let posts = result["posts"],
//                    let unwrappedPosts = posts,
//                    let data = unwrappedPosts["data"] as? NSMutableArray else { return }
//
//                for i in 0..<data.count {
////                    print(data[i])
////                    print("================= separator ===================")
//                    self.facebookPosts.append(data[i])
//                }
//            }
//        })

    }
    
    private func displayFacebookPosts() {
        facebookTableView.reloadData()
    }
    
    private func getEntryTimestamps() -> [String: Int] {
        let calendar = NSCalendar.currentCalendar()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var since = NSDate()
        var until = NSDate()
        
        if let entry = entry {
            if let createdAt = entry.created_at {
                // get date portion only of createdAt
                let entryDateComponents = calendar.components([.Day, .Month, .Year], fromDate: createdAt)
                
                // set the time to midnight and the last second
                let entryDateBegin = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 00:00:00"
                let entryDateEnd = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 23:59:59"
                
                since = formatter.dateFromString(entryDateBegin)!
                until = formatter.dateFromString(entryDateEnd)!
            }
        } else {
            let currentDateComponents = calendar.components([.Day, .Month, .Year], fromDate: NSDate())
            let currentDateBegin = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 00:00:00"
            let currentDateEnd = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 23:59:59"
            
            since = formatter.dateFromString(currentDateBegin)!
            until = formatter.dateFromString(currentDateEnd)!
        }
        
        let sinceTimestamp = Int(since.timeIntervalSince1970)
        let untilTimestamp = Int(until.timeIntervalSince1970)

        return ["since": sinceTimestamp, "until": untilTimestamp]
    }
    
    
    // MARK: - Twitter
    
    private func showTwitterLoginButton() {
        Twitter.sharedInstance().logInWithCompletion {(session, error) in
            if let _ = session {
                self.getTweets()
            } else {
                let logInButton = TWTRLogInButton { (session, error) in
                    if let _ = session {
                        print("logged into Twitter")
                        // TODO: Remove login button - Or could put login button on its own view
                        self.getTweets()
                    } else {
                        NSLog("Login error: %@", error!.localizedDescription);
                    }
                }
                
                logInButton.center = self.twitterView.center
                self.twitterView.addSubview(logInButton)
            }
        }
    }
    
    private func getTweets() {
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            let client = TWTRAPIClient(userID: userID)
            
            let url = "https://api.twitter.com/1.1/statuses/user_timeline.json"
            let params = ["screen_name": "_morgandavison"]
            var clientError : NSError?
            
            let request = client.URLRequestWithMethod("GET", URL: url, parameters: params, error: &clientError)
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if (connectionError == nil) {
                    do {
                        if let data = data {
                            let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
                            self.twitterTweets = TWTRTweet.tweetsWithJSONArray(json as? [AnyObject]) as! [TWTRTweet]
                        }
                    } catch let error as NSError? {
                        print(error?.localizedDescription)
                    }
                }
                else {
                    print("Error: \(connectionError)")
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                // Get just tweets for date of this journal entry
                self.onlyTweetsForThisEntry()
                
                self.displayTweets()
            }
        }
        
    }
    
    private func onlyTweetsForThisEntry() {
        var tweetsForThisEntry = [TWTRTweet]()
        let timestamps = self.getEntryTimestamps()
        let secondsFromGMT = NSTimeZone.localTimeZone().secondsFromGMT // -25200
        
        for tweet in twitterTweets {
            // Convert tweet created_at to timestamp in local time
            let tweetTimestamp = Int(tweet.createdAt.timeIntervalSince1970) + (secondsFromGMT)
            
            if (timestamps["since"] <= tweetTimestamp) && (tweetTimestamp <= timestamps["until"]) {
                tweetsForThisEntry.append(tweet)
            }
        }
        
        twitterTweets = tweetsForThisEntry
    }
    
    private func displayTweets() {
        if twitterTweets.isEmpty {
            noDataTwitterLabel.hidden = false
            twitterActivityIndicator.stopAnimating()
        } else {
            twitterTableView.hidden = false
        }
    }

}


extension EntryViewController: UITabBarDelegate {
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        switch item.tag {
        case 1:
            showTab(byTag: 1)
        case 2:
            if FBSDKAccessToken.currentAccessToken() != nil {
                // User already has access token
                displayFacebookPosts()
            } else {
                showFBLoginButton()
            }
            showTab(byTag: 2)
        case 3:
            showTab(byTag: 3)
            showTwitterLoginButton()
        default: return
        }
    }
    
    private func showTab(byTag tag: Int) {
        switch tag {
        case 1: // Entry
            title = "Journal Entry"
            entryTextView.hidden = false
            hideTabsExcept(1)
        case 2: // Facebook
            title = "Facebook"
            facebookView.hidden = false
            if !facebookPosts.isEmpty {
                facebookTableView.hidden = false
            }
            hideTabsExcept(2)
        case 3: // Twitter
            title = "Twitter"
            twitterView.hidden = false
            hideTabsExcept(3)
        default: return
        }
    }
    
    private func hideTabsExcept(tag: Int) {
        func hideEntry() {
            entryTextView.hidden = true
        }
        
        func hideFacebook() {
            facebookView.hidden = true
            facebookTableView.hidden = true
        }
        
        func hideTwitter() {
            twitterView.hidden = true
            twitterTableView.hidden = true
        }
        
        switch tag {
        case 1: // Entry
            // hide 2 & 3
            hideFacebook()
            hideTwitter()
        case 2: // Facebook
            // hide 1 & 3
            hideEntry()
            hideTwitter()
        case 3: // Twitter
            // hide 1 & 2
            hideEntry()
            hideFacebook()
        default: return
        }
        
        
        
    }
}


extension EntryViewController: FBSDKLoginButtonDelegate {
    
    // MARK: - FBSDKLoginButtonDelegate methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("logged in")
        getFacebookPosts()
        displayFacebookPosts()
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("logged out")
        showFBLoginButton()
    }

}


extension EntryViewController: UITableViewDelegate, UITableViewDataSource, TWTRTweetViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == facebookTableView {
            return facebookPosts.count
        } else {
            return twitterTweets.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView == facebookTableView {
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.FacebookPostCellReuseIdentifier, forIndexPath: indexPath) as! FacebookPostTableViewCell
            
            let post = facebookPosts[indexPath.row]
            
            configureCell(cell, facebookPost: post)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TwitterTweetCellReuseIdentifier, forIndexPath: indexPath) as! TWTRTweetTableViewCell
            
            let tweet = twitterTweets[indexPath.row]
            
            cell.configureWithTweet(tweet)
            cell.tweetView.delegate = self
            
            return cell
        }
    }
    
    
    private func configureCell(cell: FacebookPostTableViewCell, facebookPost post: AnyObject) {
        if let picture = post["picture"] as? String {
            if let urlString = NSURL(string: picture) {
                if let imageData = NSData(contentsOfURL: urlString) {
                    cell.postImageView.image = UIImage(data: imageData)
                }
            }
        } else {
            cell.postImageView.image = nil
        }
        if let message = post["message"] as? String {
            cell.postTextView.text = message
        } else {
            cell.postTextView.text = ""
        }
    }

    
}


extension EntryViewController: EntryDateViewControllerDelegate {
    func entryDateViewController(controller: EntryDateViewController, didSaveDate date: NSDate) {
        setDateButton(withDate: date)
    }
}

