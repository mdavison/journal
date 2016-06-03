//
//  EntryDateViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/24/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

protocol EntryDateViewControllerDelegate: class {
    func entryDateViewController(controller: EntryDateViewController, didSaveDate date: NSDate)
}

class EntryDateViewController: UIViewController {

    @IBOutlet weak var entryDatePicker: UIDatePicker!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var coreDataStack: CoreDataStack!
    var delegate: EntryDateViewControllerDelegate?
    var showMessageLabel = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent future dates
        entryDatePicker.maximumDate = NSDate()
        
        if showMessageLabel {
            messageLabel.hidden = false
            saveButton.enabled = false
        }
        
        // Theme
        Theme.setup(withNavigationController: navigationController)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func dateChanged(sender: UIDatePicker) {
        validateSelectedDate(sender.date)
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        delegate?.entryDateViewController(self, didSaveDate: entryDatePicker.date)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Helper Methods
    
    private func validateSelectedDate(date: NSDate) {
        let entryExists = Entry.entryExists(forDate: date, coreDataStack: coreDataStack)
        
        saveButton.enabled = !entryExists
        messageLabel.hidden = !entryExists
    }

}
