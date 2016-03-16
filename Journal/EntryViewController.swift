//
//  EntryViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

class EntryViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    var coreDataStack: CoreDataStack!
    var entry: Entry?
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        entryTextView.delegate = self
        setupView()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "entryWasDeleted:", name: EntryWasDeletedNotificationKey, object: entry)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITextViewDelegate Methods
    
    func textViewDidChange(textView: UITextView) {
        saveButton.enabled = true
        saveButton.title = "Save"
    }


    
    // MARK: - Actions
    
    @IBAction func save(sender: UIBarButtonItem) {
        if let entry = entry {
            // Save existing
            entry.updated_at = NSDate()
            entry.text = entryTextView.text
            
            coreDataStack.saveContext()
        } else {
            // Create new
            let entryEntity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: coreDataStack.managedObjectContext)
            entry = Entry(entity: entryEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            entry?.created_at = NSDate()
            entry?.text = entryTextView.text
            
            coreDataStack.saveContext()
        }
        
        saveButton.enabled = false
        saveButton.title = "Saved"
        setDateLabel(withEntry: entry)
        title = "Journal Entry"
    }
    
    
    // MARK: - Notification Handling
    
    func entryWasDeleted(notification: NSNotification) {
        if let notificationEntry = notification.object as? Entry {
            if notificationEntry == entry {
                entry = nil
                setupView()
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
        if let entry = entry {
            setDateLabel(withEntry: entry)
            entryTextView.text = entry.text
        } else {
            saveButton.enabled = false
            setDateLabel(withEntry: nil)
            entryTextView.text = ""
            title = "New Entry"
        }
    }
    
    private func setDateLabel(withEntry entry: Entry?) {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        if let entry = entry {
            dateLabel.text = formatter.stringFromDate(entry.created_at!)
        } else {
            formatter.timeStyle = .NoStyle
            dateLabel.text = formatter.stringFromDate(NSDate())
        }

    }

}

