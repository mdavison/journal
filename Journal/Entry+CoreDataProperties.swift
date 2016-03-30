//
//  Entry+CoreDataProperties.swift
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

extension Entry {

    @NSManaged var created_at: NSDate?
    @NSManaged var text: String?
    @NSManaged var updated_at: NSDate?
    //@NSManaged var tweets: NSSet?
    @NSManaged var tweets: Set<Tweet>?
//    @NSManaged var fbposts: NSSet?
    @NSManaged var fbposts: Set<FBPost>?
    
}
