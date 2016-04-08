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

let TwitterHasLoggedInNotificationKey = "com.morgandavison.twitterHasLoggedInNotificationKey"

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
    var entryDate: NSDate?
    var facebookPosts = [FBPost]()
    var twitterTweets: [TWTRTweet] = [] {
        didSet {
            twitterTableView.reloadData()
        }
    }
    var sinceTimestamp: Int?
    var untilTimestamp: Int?
    var journalTwitter = JournalTwitter()
    var invalidDate = false
    
    struct Storyboard {
        static var FacebookViewIdentifier = "FacebookView"
        static var EntryDateSegueIdentifier = "EntryDate"
        static var FacebookPostCellReuseIdentifier = "FacebookPostCell"
        static var TwitterTweetCellReuseIdentifier = "TwitterTweetCell"
        static var SignInSegueIdentifier = "SignIn"
    }
    
    deinit {
       NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        JournalVariables.entry = entry
        
        // Check if an entry already exists for this date
        if entryExists() {
            invalidDate = true
            performSegueWithIdentifier(Storyboard.EntryDateSegueIdentifier, sender: nil)
        }
        
        journalTwitter.coreDataStack = coreDataStack
        entryTextView.delegate = self
        setupView()
        setEntryTimestamps()
        
        // Notifications
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(EntryViewController.entryWasDeleted(_:)), name: EntryWasDeletedNotificationKey, object: entry)
        
        //notificationCenter.addObserver(self, selector: #selector(EntryViewController.twitterHasRefreshed(_:)), name: TwitterDidRefreshNotificationKey, object: twitterTweets) // This didn't work
        notificationCenter.addObserverForName(TwitterDidRefreshNotificationKey, object: nil, queue: nil) { (notification) in
            self.twitterHasRefreshed(notification)
        }
        
        
        if FBSDKAccessToken.currentAccessToken() != nil {
            // User already has access token
            getFacebookPosts()
        } else {
            //showLoginButton()
            // TODO: Show exclamation badge on Facebook tab
        }
        
        if let _ = Twitter.sharedInstance().sessionStore.session()?.userID {
            getTweets()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        tabBarController?.navigationItem.leftItemsSupplementBackButton = true
        
        fixNavigation() // Duplicate tabBarController navigation needs to be shown and hidden depending on orientation
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !JournalVariables.userIsAuthenticated {
            performSegueWithIdentifier(Storyboard.SignInSegueIdentifier, sender: nil)
        }
        
        tabBarController?.navigationItem.title = "Journal Entry"
        tabBarController?.navigationItem.rightBarButtonItem = saveButton
        
        // Check if an entry already exists for this date
        if entryExists() {
            saveButton.enabled = false
        }
    }
    

    
    // Redraw view when switches orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            self.fixNavigation()
        }) { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            // complete
        }
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITextViewDelegate Methods
    
    func textViewDidChange(textView: UITextView) {
        saveButton.title = "Save"
        if invalidDate == false {
            saveButton.enabled = true
        }
    }


    
    // MARK: - Actions
    
    @IBAction func save(sender: UIBarButtonItem) {
        // TODO: Restrict so 1 entry per date - this is to make calendar view feasible - can't really show multiple entries on a day and there's no good reason to have multiple entries per day - Probably make DB one to many relationship for Twitter and FB
        if let entry = entry {
            // Save existing
            entry.created_at = getButtonDate()
            entry.updated_at = NSDate()
            entry.text = entryTextView.text
            
            coreDataStack.saveContext()
        } else {
            // TODO: Should send a notification so calendar (and maybe list too?) can be highlighted when new entry created when in split view
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
    
    @IBAction func refreshTwitter(sender: UIButton) {
        journalTwitter.requestTweets()
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
    
    func twitterHasRefreshed(notification: NSNotification) {
        twitterTableView.hidden = true
        twitterTweets.removeAll()
        getTweets()
        twitterTableView.hidden = false
    }

    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EntryDateSegueIdentifier:
                guard let navController = segue.destinationViewController as? UINavigationController,
                    let controller = navController.topViewController as? EntryDateViewController else { return }
                
                controller.delegate = self
                controller.coreDataStack = coreDataStack
                if invalidDate {
                    controller.showMessageLabel = true 
                }
            default:
                return 
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
        entryItemsTabBar.selectedItem = entryItemsTabBar.items![0]
        
        tabBarController?.navigationItem.rightBarButtonItem = saveButton
        
        if let entry = entry {
            setDateButton(withEntry: entry)
            entryTextView.text = entry.text
        } else {
            if let entryDate = entryDate {
                setDateButton(withDate: entryDate)
            } else {
                setDateButton(withEntry: nil)
            }
            saveButton.enabled = false
            entryTextView.text = ""
            title = "New Entry"
        }
        
        twitterTableView.estimatedRowHeight = 150
        twitterTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    private func fixNavigation() {
        if let hidden = tabBarController?.navigationController?.navigationBarHidden {
            if hidden == true {
                tabBarController?.navigationController?.navigationBarHidden = false
            }
        }
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
    
    private func setEntryTimestamps() {
        let timestamps = getEntryTimestamps()
        
        JournalVariables.entryTimestamps = timestamps
        
        sinceTimestamp = timestamps["since"]
        untilTimestamp = timestamps["until"]
    }
    
    private func entryExists() -> Bool {
        if entry == nil { // Adding a new entry
            
            // If a date is set, use that, otherwise use today's date
            var date = NSDate()
            if let entryDate = entryDate {
                date = entryDate
            }

            return Entry.entryExists(forDate: date, coreDataStack: coreDataStack)
        }
        
        return false
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
        let fbFetch = NSFetchRequest(entityName: "FBPost")
        
        let sortDescriptor = NSSortDescriptor(key: "created_at_timestamp", ascending: true)
        fbFetch.sortDescriptors = [sortDescriptor]
        
        if let since = sinceTimestamp, let until = untilTimestamp {
            fbFetch.predicate = NSPredicate(format: "(created_at_timestamp >= %d) AND (created_at_timestamp <= %d)", since, until)
            
            do {
                if let results = try coreDataStack.managedObjectContext.executeFetchRequest(fbFetch) as? [FBPost] {
                    facebookPosts = results
                }
            } catch let error as NSError {
                print("Error: \(error) " + "description \(error.localizedDescription)")
            }
        }
    }
    
    private func displayFacebookPosts() {
        facebookTableView.reloadData()
    }
    
    
    // MARK: - Twitter
    
    private func showTwitterLoginButton() {
        Twitter.sharedInstance().logInWithCompletion {(session, error) in
            if let _ = session {
                NSNotificationCenter.defaultCenter().postNotificationName(TwitterHasLoggedInNotificationKey, object: self)
                self.getTweets()
                self.twitterTableView.reloadData()
            } else {
                let logInButton = TWTRLogInButton { (session, error) in
                    if let _ = session {
                        // TODO: Remove login button - Or could put login button on its own view
                        //twitterLoginButtonView.hidden = true
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(TwitterHasLoggedInNotificationKey, object: self)
                        self.getTweets()
                        self.twitterTableView.reloadData()
                    } else {
                        NSLog("Login error: %@", error!.localizedDescription);
                    }
                }
                
                logInButton.center = self.twitterView.center
                self.twitterView.addSubview(logInButton)
                //self.twitterLoginButtonView.addSubview(logInButton)
            }
        }
    }
    
    private func getTweets() {
        let tweetFetch = NSFetchRequest(entityName: "Tweet")
        
        let sortDescriptor = NSSortDescriptor(key: "created_at_timestamp", ascending: false)
        tweetFetch.sortDescriptors = [sortDescriptor]
        
        if let since = sinceTimestamp, let until = untilTimestamp {
            tweetFetch.predicate = NSPredicate(format: "(created_at_timestamp >= %d) AND (created_at_timestamp <= %d)", since, until)
            
            var results = [Tweet]()
            do {
                results = try coreDataStack.managedObjectContext.executeFetchRequest(tweetFetch) as! [Tweet]
                
                for tweet in results {
                    if let twtrtweet = tweet.twtrtweet {
                        twitterTweets.append(twtrtweet)
                    }
                }
            } catch let error as NSError {
                print("Error: \(error) " + "description \(error.localizedDescription)")
            }
        }
    }

}


extension EntryViewController: UITabBarDelegate {
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        switch item.tag {
        case 1:
            showTab(byTag: 1)
        case 2:
//            if FBSDKAccessToken.currentAccessToken() != nil {
//                // User already has access token
//                displayFacebookPosts()
//            } else {
//                showFBLoginButton()
//            }
            showTab(byTag: 2)
        case 3:
            showTab(byTag: 3)
            //showTwitterLoginButton()
            
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
            } else {
                facebookActivityIndicator.stopAnimating()
                noDataFacebookLabel.hidden = false
            }
            
            if FBSDKAccessToken.currentAccessToken() == nil {
                showFBLoginButton()
            }
            
            hideTabsExcept(2)
        case 3: // Twitter
            title = "Twitter"
            twitterView.hidden = false
            
            if !twitterTweets.isEmpty {
                twitterTableView.hidden = false
            } else {
                twitterActivityIndicator.stopAnimating()
                noDataTwitterLabel.hidden = false
            }
            
            if Twitter.sharedInstance().sessionStore.session()?.userID == nil {
                showTwitterLoginButton()
            } 
            
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
        getFacebookPosts()
        displayFacebookPosts()
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
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
    
    
    private func configureCell(cell: FacebookPostTableViewCell, facebookPost post: FBPost) {
        if let picture = post.picture {
            cell.postImageView.image = UIImage(data: picture)
        } else {
            cell.postImageView.image = nil
        }
        
        if let message = post.message {
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

