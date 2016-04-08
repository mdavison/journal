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
    
    struct Storyboard {
        static var TwitterTweetCellReuseIdentifier = "TwitterTweetCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
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
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
//        tabBarController?.navigationItem.title = "Twitter"
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    private func setTweets() {
        guard let entry = JournalVariables.entry, let journalTwitter = journalTwitter else { return }
        
        if let tweets = journalTwitter.fetchTweets(forEntry: entry) {
            twitterTweets = tweets
        }
    }
    
    private func setNoDataLabel() {
        if twitterTweets.isEmpty {
            noDataLabel.hidden = false 
        }
    }
    
    private func setRefreshButton() {
        let refreshButton = UIBarButtonItem(title: "Refresh!", style: .Plain, target: self, action: #selector(TwitterTableViewController.refresh))
        tabBarController?.navigationItem.rightBarButtonItem = refreshButton
        
    }
    
    @objc private func refresh() {
        // TODO: if not logged in, showLogin(), else fetch from network
    }

}
