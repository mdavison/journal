//
//  JournalTwitter.swift
//  Journal
//
//  Created by Morgan Davison on 3/28/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import Foundation
import TwitterKit
import CoreData

let TwitterDidRefreshNotificationKey = "com.morgandavison.twitterDidRefreshNotificationKey"

class JournalTwitter {
    
    var coreDataStack: CoreDataStack!
 
    init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(JournalTwitter.hasLoggedIn(_:)), name: TwitterHasLoggedInNotificationKey, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Tweets from Network
    func requestTweets() {
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            //Twitter.sharedInstance().sessionStore.logOutUserID(userID)
            JournalVariables.loggedInTwitter = true
            
            let client = TWTRAPIClient(userID: userID)
            client.loadUserWithID(userID, completion: { (user, error) in
                guard let screenName = user?.screenName else {
                    NSLog("Unable to obtain user screen name")
                    return
                }
                
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    let url = "https://api.twitter.com/1.1/statuses/user_timeline.json"
                    let params = ["screen_name": screenName]
                    var clientError : NSError?
                    
                    let request = client.URLRequestWithMethod("GET", URL: url, parameters: params, error: &clientError)
                    
                    // Show network activity in status bar
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    
                    client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                        // Remove network activity indicator in status bar
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        
                        if (connectionError == nil) {
                            do {
                                if let data = data {
                                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers)
                                    let tweets = TWTRTweet.tweetsWithJSONArray(json as? [AnyObject]) as! [TWTRTweet]
                                    
                                    self.refreshTweets(tweets)
                                }
                            } catch let error as NSError? {
                                print(error?.localizedDescription)
                            }
                        }
                        else {
                            NSLog("Error: \(connectionError)")
                        }
                    }
                }
            })
        } else {
            NSLog("No Twitter userID")
            JournalVariables.loggedInTwitter = false
        }
    }
    
    // Tweets from DB
    func fetchTweets(forEntry entry: Entry) -> [TWTRTweet]? {
        let tweetFetch = NSFetchRequest(entityName: "Tweet")
        
        let sortDescriptor = NSSortDescriptor(key: "created_at_timestamp", ascending: false)
        tweetFetch.sortDescriptors = [sortDescriptor]
        
        if let timestamps = JournalVariables.entryTimestamps {
            if let since = timestamps["since"], let until = timestamps["until"] {
                tweetFetch.predicate = NSPredicate(format: "(created_at_timestamp >= %d) AND (created_at_timestamp <= %d)", since, until)
                
                do {
                    if let results = try coreDataStack.managedObjectContext.executeFetchRequest(tweetFetch) as? [Tweet] {
                        var twtrtweets = [TWTRTweet]()
                        
                        for tweet in results {
                            if let twtrtweet = tweet.twtrtweet {
                                twtrtweets.append(twtrtweet)
                            }
                        }
                        
                        return twtrtweets
                    }
                } catch let error as NSError {
                    NSLog("Error: \(error) " + "description \(error.localizedDescription)")
                }
            }
        }
        
        return nil
    }
    
    // For Development
    func logout() {
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            Twitter.sharedInstance().sessionStore.logOutUserID(userID)
        }
    }
    
    
    // MARK: - Notification Handling
    
    @objc func hasLoggedIn(notification: NSNotification) {
        requestTweets()
    }
    
    
    
    // MARK: - Helper Methods
    
    private func refreshTweets(tweets: [TWTRTweet]) {
        // Delete all existing first so don't duplicate
        let tweetRequest = NSFetchRequest(entityName: "Tweet")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: tweetRequest)
        
        do {
            try coreDataStack.managedObjectContext.executeRequest(deleteRequest) // Not sure what the difference between these two is
            //try coreDataStack.persistentStoreCoordinator.executeRequest(deleteRequest, withContext: coreDataStack.managedObjectContext)
            
            saveNewTweets(tweets)
        } catch let error as NSError {
            print("Error: \(error) " + "description \(error.localizedDescription)")
        }
    }
    
    private func saveNewTweets(tweets: [TWTRTweet]) {
        for tweet in tweets {
            let tweetEntity = NSEntityDescription.entityForName("Tweet", inManagedObjectContext: coreDataStack.managedObjectContext)
            let twt = Tweet(entity: tweetEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            twt.twtrtweet = tweet
            
            // Convert created_at to local time
            let secondsFromGMT = NSTimeZone.localTimeZone().secondsFromGMT
            twt.created_at_timestamp = Int(tweet.createdAt.timeIntervalSince1970) + (secondsFromGMT)
            
            coreDataStack.saveContext()
        }
        NSNotificationCenter.defaultCenter().postNotificationName(TwitterDidRefreshNotificationKey, object: nil)
    }

    
}