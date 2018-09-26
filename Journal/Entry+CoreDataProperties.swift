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

    @NSManaged var created_at: Date?
    //@NSManaged var text: String?
    @NSManaged var attributed_text: NSAttributedString?
    @NSManaged var updated_at: Date?
    
}
