//
//  JournalFacebook.swift
//  Journal
//
//  Created by Morgan Davison on 3/30/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import Foundation
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit

class JournalFacebook {
    
    var coreDataStack: CoreDataStack!
    let formatter = NSDateFormatter()
    
    // Get all posts from network and save to DB
    func requestPosts() {
        if FBSDKAccessToken.currentAccessToken() != nil {
    //        let parameters = ["fields": "id, name, email, posts.since(\(sinceTimestamp!)).until(\(untilTimestamp!)){story,created_time,id,message,picture,likes}"]
            let parameters = ["fields": "id, name, email, posts{story,created_time,id,message,picture,likes}"]
            
            let request = FBSDKGraphRequest(graphPath: "me", parameters: parameters)
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            request.startWithCompletionHandler({ (connection, result, error) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if error != nil {
                    print(error)
                } else {
                    guard let posts = result["posts"],
                        let unwrappedPosts = posts,
                        let data = unwrappedPosts["data"] as? NSMutableArray else { return }
                    
                    var facebookPosts = [AnyObject]()
                    
                    for i in 0..<data.count {
                        //print(data[i])
                        //print("================= separator ===================")
                        facebookPosts.append(data[i])
                    }
                    
                    self.refreshPosts(facebookPosts)
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Back on main thread
                    //print("back on main thread")
                })
            })
        } else {
            // Need to login to facebook
            print("Need to login to Facebook")
        }
    }
    
    // Get posts from DB - not network
    func fetchPosts(forEntry entry: Entry) -> [FBPost]? {
        let fbFetch = NSFetchRequest(entityName: "FBPost")
        
        let sortDescriptor = NSSortDescriptor(key: "created_at_timestamp", ascending: true)
        fbFetch.sortDescriptors = [sortDescriptor]
        
        if let timestamps = JournalVariables.entryTimestamps {
            if let since = timestamps["since"], let until = timestamps["until"] {
                fbFetch.predicate = NSPredicate(format: "(created_at_timestamp >= %d) AND (created_at_timestamp <= %d)", since, until)
                
                do {
                    if let results = try coreDataStack.managedObjectContext.executeFetchRequest(fbFetch) as? [FBPost] {
                        return results
                    }
                } catch let error as NSError {
                    print("Error: \(error) " + "description \(error.localizedDescription)")
                }
            }
        }
    
        return nil
    }
    
    func logout() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            FBSDKLoginManager().logOut()
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func refreshPosts(posts: [AnyObject]) { 
        // Delete all existing first so don't duplicate
        let fbRequest = NSFetchRequest(entityName: "FBPost")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fbRequest)
        
        do {
            try coreDataStack.managedObjectContext.executeRequest(deleteRequest)
            
            saveNewPosts(posts)
        } catch let error as NSError {
            print("Error: \(error) " + "description \(error.localizedDescription)")
        }
    }
    
    private func saveNewPosts(posts: [AnyObject]) {
        for post in posts {
            let postEntity = NSEntityDescription.entityForName("FBPost", inManagedObjectContext: coreDataStack.managedObjectContext)
            let pst = FBPost(entity: postEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            
            if let message = post["message"] as? String {
                pst.message = message
            }
            
            // Convert created_time to local time
            if let created_time = post["created_time"] {
                if let createdTime = created_time { // 2010-12-25T20:00:00+0000
                    let timeString = "\(createdTime)"
                    if let timestamp = getTimestamp(forTime: timeString) {
                        
                        // Convert to local time
                        let secondsFromGMT = NSTimeZone.localTimeZone().secondsFromGMT
                        let localTimestamp = Int(timestamp) + (secondsFromGMT)
                        pst.created_at_timestamp = localTimestamp
                    }
                }
            }
            
            if let picture = post["picture"] as? String {
                if let urlString = NSURL(string: picture) {
                    if let imageData = NSData(contentsOfURL: urlString) {
                        pst.picture = imageData
                    }
                }
            }
            
            coreDataStack.saveContext()
        }
    }
    
    private func getTimestamp(forTime time: String) -> Int? {
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH:mm:ssZ"
        if let date = formatter.dateFromString(time) {
            return Int(date.timeIntervalSince1970)
        }
        
        return nil
    }

    
}
