//
//  Entry+CoreDataProperties.swift
//  Journal
//
//  Created by Morgan Davison on 3/28/16.
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
    //@NSManaged var tweet: NSSet?
    @NSManaged var tweet: Set<Tweet>?

}
