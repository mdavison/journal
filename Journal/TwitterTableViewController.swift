//
//  TwitterTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/8/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import TwitterKit

class TwitterTableViewController: UITableViewController, TWTRTweetViewDelegate {

    @IBOutlet weak var noDataLabel: UILabel!
    
    let journalTwitter = (UIApplication.sharedApplication().delegate as? AppDelegate)?.twitter
    var twitterTweets: [TWTRTweet] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var loginButton: TWTRLogInButton?
    
    struct Storyboard {
        static var TwitterTweetCellReuseIdentifier = "TwitterTweetCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        NSNotificationCenter.defaultCenter().addObserverForName(TwitterDidRefreshNotificationKey, object: nil, queue: nil) { (notification) in
            self.twitterHasRefreshed(notification)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let _ = Twitter.sharedInstance().sessionStore.session()?.userID {
            setTweets()
        }
        
        setNoDataLabel()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tabBarController?.navigationItem.title = "Twitter"
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
        return twitterTweets.count 
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.TwitterTweetCellReuseIdentifier, forIndexPath: indexPath) as! TWTRTweetTableViewCell
        
        let tweet = twitterTweets[indexPath.row]
        
        cell.configureWithTweet(tweet)
        cell.tweetView.delegate = self
        
        return cell
    }



    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Notification Handling
    
    func twitterHasRefreshed(notification: NSNotification) {
        setTweets()
    }
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
//        tabBarController?.navigationItem.title = "Twitter"
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    private func setTweets() {
        guard let journalTwitter = journalTwitter else { return }
        
        if let entry = JournalVariables.entry {
            if let tweets = journalTwitter.fetchTweets(forEntry: entry) {
                twitterTweets = tweets
            }
        } else { // If no entry but we still have tweets (e.g. entry was deleted), clear the tweets
            if !twitterTweets.isEmpty {
                twitterTweets = []
            }
        }
    }
    
    private func setNoDataLabel() {
        if JournalVariables.entry == nil {
            noDataLabel.text = "Jounal Entry has not been saved"
            noDataLabel.hidden = false
        } else {
            if twitterTweets.isEmpty {
                noDataLabel.text = "No tweets on this day :("
                noDataLabel.hidden = false
            } else {
                noDataLabel.hidden = true
            }
        }
    }
    
    private func setRefreshButton() {
        let refreshButton = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: #selector(TwitterTableViewController.refresh))
        tabBarController?.navigationItem.rightBarButtonItem = refreshButton
        
        refreshButton.enabled = JournalVariables.entry != nil
    }
    
    @objc private func refresh() {
        if JournalVariables.loggedInTwitter {
            // Fetch from network
            journalTwitter?.requestTweets()
        } else {
            loginButton = TWTRLogInButton(logInCompletion: { session, error in
                if let _ = session {
                    //print("signed in as \(session.userName)")
                    JournalVariables.loggedInTwitter = true
                    self.journalTwitter?.requestTweets()
                    self.removeLoginButton()
                }
                if let error = error {
                    NSLog("Error logging into Twitter: \(error.localizedDescription)")
                }
            })
            
            if let loginButton = self.loginButton {
                loginButton.center = self.view.center
                
                view.addSubview(loginButton)
            }
        }
    }
    
    private func removeLoginButton() {
        loginButton?.removeFromSuperview()
        tableView.reloadData()
    }

}
