//
//  SettingsTableViewController.swift
//  Journal
//
//  Created by Morgan Davison on 4/4/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    struct Storyboard {
        static var SetPasswordSegueIdentifier = "SetPassword"
        static var ChangePasswordSegueIdentifier = "ChangePassword"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Remove duplicate nav controller
        tabBarController?.navigationController?.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Actions
    
    @IBAction func requirePasswordSwitchChanged(sender: UISwitch) {
        print("require password: \(sender.on)")
        // TODO: warning message to user that data cannot be recovered if password lost
        if sender.on {
            // check if password is set
                // if password not set, segue to setPasswordView
            performSegueWithIdentifier(Storyboard.SetPasswordSegueIdentifier, sender: nil)
        }
    }
    

}
