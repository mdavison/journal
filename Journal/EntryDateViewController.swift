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
    
    var delegate: EntryDateViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Actions
    
    @IBAction func dateChanged(sender: UIDatePicker) {
        // TODO: prevent future date
    }
    
    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save(sender: UIBarButtonItem) {
        delegate?.entryDateViewController(self, didSaveDate: entryDatePicker.date)
        dismissViewControllerAnimated(true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
