//
//  DetailViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData 

class DetailViewController: UIViewController {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!

    var managedObjectContext: NSManagedObjectContext? = nil
    var entry: Entry?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    @IBAction func save(sender: UIBarButtonItem) {
        print("save")
    }
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
        if let entry = entry {
            dateLabel.text = "\(entry.created_at)"
            entryTextView.text = entry.text
        } else {
            dateLabel.text = "\(NSDate())"
        }
    }

}

