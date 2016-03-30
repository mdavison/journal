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
    
    func requestTweets() {
        if let userID = Twitter.sharedInstance().sessionStore.session()?.userID {
            print("request tweets from JOurnalTwitter class")
            //Twitter.sharedInstance().sessionStore.logOutUserID(userID)
            
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
                            print("Error: \(connectionError)")
                        }
                    }
                }
            })
        } else {
            print("No Twitter userID")
        }
    }
    
    
    // MARK: - Notification Handling
    
    @objc func hasLoggedIn(notification: NSNotification) {
        print("User has logged into Twitter")
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
        print("TwitterDidRefresh notification sent")
    }
    
}