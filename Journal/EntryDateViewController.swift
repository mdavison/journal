//
//  EntryDateViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/24/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

protocol EntryDateViewControllerDelegate: class {
    func entryDateViewController(_ controller: EntryDateViewController, didSaveDate date: Date)
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
        entryDatePicker.maximumDate = Date()
        
        if showMessageLabel {
            messageLabel.isHidden = false
            saveButton.isEnabled = false
        }
        
        // Theme
        Theme.setup(withNavigationController: navigationController)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        validateSelectedDate(sender.date)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        delegate?.entryDateViewController(self, didSaveDate: entryDatePicker.date)
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Helper Methods
    
    fileprivate func validateSelectedDate(_ date: Date) {
        let entryExists = Entry.entryExists(forDate: date, coreDataStack: coreDataStack)
        
        saveButton.isEnabled = !entryExists
        messageLabel.isHidden = !entryExists
    }

}
