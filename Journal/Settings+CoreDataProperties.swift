//
//  Settings+CoreDataProperties.swift
//  Journal
//
//  Created by Morgan Davison on 4/5/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Settings {

    @NSManaged var password_required: NSNumber?
    @NSManaged var password: String?

}
