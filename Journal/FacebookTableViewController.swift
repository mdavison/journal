//
//  FacebookTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/7/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit

class FacebookTableViewController: UITableViewController {

    @IBOutlet weak var noDataLabel: UILabel!
    
    var facebookPosts: [FBPost] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    let journalFacebook = (UIApplication.sharedApplication().delegate as? AppDelegate)?.facebook
    var loginButton: FBSDKLoginButton?
    
    struct Storyboard {
        static var FacebookPostCellReuseIdentifier = "FacebookPostCell"
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FacebookTableViewController.facebookDidRefresh(_:)), name: FacebookDidRefreshNotificationKey, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loginButton?.removeFromSuperview()
        setFacebookPosts()
        setNoDataLabel()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.navigationItem.title = "Facebook"
        setRefreshButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return facebookPosts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.FacebookPostCellReuseIdentifier, forIndexPath: indexPath) as! FacebookPostTableViewCell
        
        let post = facebookPosts[indexPath.row]
        
        configureCell(cell, facebookPost: post)
        
        return cell
    }
    
    
    // MARK: - Notification Handling
    
    func facebookDidRefresh(notification: NSNotification) {
        print("facebookDidRefresh notification handling method")
        setFacebookPosts()
        setNoDataLabel()
    }
    
    
    // MARK: - Helper Methods
    
    private func setFacebookPosts() {
        guard let journalFacebook = journalFacebook else { return }
        
        if let entry = JournalVariables.entry {
            if let posts = journalFacebook.fetchPosts(forEntry: entry) {
                facebookPosts = posts
            }
        } else {
            // No entry but still have posts (e.g., entry was deleted while it was still being viewed in detail view)
            if !facebookPosts.isEmpty {
                facebookPosts = []
            }
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
    
    private func setNoDataLabel() {
        if JournalVariables.entry == nil {
            noDataLabel.text = NSLocalizedString("Jounal Entry has not been saved", comment: "")
            noDataLabel.hidden = false
        } else {
            if facebookPosts.isEmpty {
                noDataLabel.text = NSLocalizedString("No posts on this day :(", comment: "")
                noDataLabel.hidden = false
            } else {
                noDataLabel.hidden = true 
            }
        }
    }
    
    private func setRefreshButton() {
        let refreshButton = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: #selector(FacebookTableViewController.refresh))
        tabBarController?.navigationItem.rightBarButtonItem = refreshButton

    }
    
    @objc private func refresh() {        
        if FBSDKAccessToken.currentAccessToken() != nil {
            journalFacebook?.requestPosts()
        } else {
            toggleLoginButton()
        }
    }
    
    private func toggleLoginButton() {
        if FBSDKAccessToken.currentAccessToken() == nil {
            loginButton = FBSDKLoginButton()
            loginButton?.center = view.center
            view.addSubview(loginButton!)
            loginButton?.delegate = self
        } else {
            loginButton?.removeFromSuperview()
        }
    }

}


extension FacebookTableViewController: FBSDKLoginButtonDelegate {
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("facebook did log in")
        refresh()
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("facebook did log out")
    }
}
