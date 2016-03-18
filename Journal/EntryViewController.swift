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

class EntryViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var entryItemsTabBar: UITabBar!
    @IBOutlet weak var facebookView: UIView!
    @IBOutlet weak var facebookTableView: UITableView!

    
    var coreDataStack: CoreDataStack!
    var entry: Entry?
    var facebookPosts = [AnyObject]()
    
    struct Storyboard {
        static var FacebookViewIdentifier = "FacebookView"
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        entryTextView.delegate = self
        setupView()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "entryWasDeleted:", name: EntryWasDeletedNotificationKey, object: entry)
        
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
            entry.updated_at = NSDate()
            entry.text = entryTextView.text
            
            coreDataStack.saveContext()
        } else {
            // Create new
            let entryEntity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: coreDataStack.managedObjectContext)
            entry = Entry(entity: entryEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            entry?.created_at = NSDate()
            entry?.text = entryTextView.text
            
            coreDataStack.saveContext()
        }
        
        saveButton.enabled = false
        saveButton.title = "Saved"
        setDateLabel(withEntry: entry)
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
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
        entryItemsTabBar.selectedItem = entryItemsTabBar.items![0]
        
        if let entry = entry {
            setDateLabel(withEntry: entry)
            entryTextView.text = entry.text
        } else {
            saveButton.enabled = false
            setDateLabel(withEntry: nil)
            entryTextView.text = ""
            title = "New Entry"
        }
        
    }
    
    private func setDateLabel(withEntry entry: Entry?) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        if let entry = entry {
            dateLabel.text = formatter.stringFromDate(entry.created_at!)
        } else {
            formatter.timeStyle = .NoStyle
            dateLabel.text = formatter.stringFromDate(NSDate())
        }

    }
    
    private func showLoginButton() {
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
        
        request.startWithCompletionHandler({ (connection, result, error) -> Void in
            if error != nil {
                print(error)
            } else {
                let resultDict = result as! NSDictionary
                
                if let posts = resultDict["posts"] {
                    if let data = posts["data"] {
                        if let data = data {
                            for i in 0..<data.count {
                                
                                print(data[i]["message"])
                                print(data[i]["picture"])
                                print(data[i]["story"])
                                print(data[i]["likes"])
                                print("=============================")
                                
                                self.facebookPosts.append(data[i])
                            }
                        }
                    }
                }
            }
        })

    }
    
    private func displayFacebookPosts() {
        facebookTableView.reloadData()
    }
    
    private func getEntryTimestamps() -> [String: Int] {
        let calendar = NSCalendar.currentCalendar()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let currentDateComponents = calendar.components([.Day, .Month, .Year], fromDate: NSDate())
        let currentDateBegin = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 00:00:00"
        let currentDateEnd = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 23:59:59"
        
        var since = formatter.dateFromString(currentDateBegin)
        var until = formatter.dateFromString(currentDateEnd)
        
        if let entry = entry {
            if let createdAt = entry.created_at {
                // get date portion only of createdAt
                let entryDateComponents = calendar.components([.Day, .Month, .Year], fromDate: createdAt)
                
                // set the time to midnight and the last second
                let entryDateBegin = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 00:00:00"
                let entryDateEnd = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 23:59:59"
                
                since = formatter.dateFromString(entryDateBegin)
                until = formatter.dateFromString(entryDateEnd)
            }
        }
        
        let sinceTimestamp = Int(since!.timeIntervalSince1970)
        let untilTimestamp = Int(until!.timeIntervalSince1970)

        return ["since": sinceTimestamp, "until": untilTimestamp]
    }

}


extension EntryViewController: UITabBarDelegate {
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        switch item.tag {
        case 1:
            title = "Journal Entry"
            entryTextView.hidden = false
            facebookView.hidden = true 
            facebookTableView.hidden = true
        case 2:
            facebookView.hidden = false
            facebookTableView.hidden = false
            title = "Facebook"
            entryTextView.hidden = true
            
            if FBSDKAccessToken.currentAccessToken() != nil {
                // User already has access token
                displayFacebookPosts()
                
            } else {
                showLoginButton()
            }
            
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
        showLoginButton()
    }

}


extension EntryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return facebookPosts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FacebookPostCell", forIndexPath: indexPath) as! FacebookPostTableViewCell
        
        let post = facebookPosts[indexPath.row]
        
        configureCell(cell, facebookPost: post)
        
        return cell

    }
    
    
    private func configureCell(cell: FacebookPostTableViewCell, facebookPost post: AnyObject) {
        if let picture = post["picture"] as? String {
            let imageData = NSData(contentsOfURL: NSURL(string: picture)!)
            cell.postImageView.image = UIImage(data: imageData!)
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

