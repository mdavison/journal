//
//  Tweet+CoreDataProperties.swift
//  Journal
//
//  Created by Morgan Davison on 3/30/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import TwitterKit 

extension Tweet {

    @NSManaged var created_at_timestamp: NSNumber?
    //@NSManaged var twtrtweet: NSObject?
    @NSManaged var twtrtweet: TWTRTweet?
//    @NSManaged var entries: NSSet?
    @NSManaged var entry: Entry?

}
