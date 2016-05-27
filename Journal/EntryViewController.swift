//
//  EntryViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData

let HasSavedEntryNotificationKey = "com.morgandavison.hasSavedEntryNotificationKey"

class EntryViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var editingToolbar: UIToolbar!
    
    var coreDataStack: CoreDataStack!
    var entry: Entry?
    var entryDate: NSDate?
    //var sinceTimestamp: Int?
    //var untilTimestamp: Int?
    var invalidDate = false
    var styleApplied = ""
    var addEntry = false
    
    struct Storyboard {
        static var EntryDateSegueIdentifier = "EntryDate"
    }
    
    deinit {
       NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if addEntry { // User tapped Add button
            if entryExists() {
                invalidDate = true
                performSegueWithIdentifier(Storyboard.EntryDateSegueIdentifier, sender: nil)
            }
        } else { // App loaded and entry already exists for today
            loadEntryForDateIfExists()
        }
                
        JournalVariables.entry = entry
        
        entryTextView.delegate = self
        setupView()
        //setEntryTimestamps()
        addNotificationObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBarHidden = false
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if an entry already exists for this date
        if entryExists() {
            saveButton.enabled = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITextViewDelegate Methods
    
    func textViewDidChange(textView: UITextView) {
        saveButton.title = "Save"
        if invalidDate == false {
            saveButton.enabled = true
        }
    }

    
    // MARK: - Actions
    
    @IBAction func save(sender: UIBarButtonItem) {
        entry = Entry.save(withEntry: entry, withDate: Entry.getButtonDate(forButton: dateButton), withText: entryTextView.attributedText, withCoreDataStack: coreDataStack)
        
        //setEntryTimestamps()
        
        saveButton.enabled = false
        saveButton.title = "Saved"
        Entry.setDateButton(forDateButton: dateButton, withEntry: entry)
        title = "Journal Entry"
        
        // Post notification that entry was saved - then listen for it in calendar
        NSNotificationCenter.defaultCenter().postNotificationName(HasSavedEntryNotificationKey, object: self)
    }
    
    @IBAction func applyBoldStyle(sender: UIBarButtonItem) {
        
        if let _ = AttributedText.addOrRemoveFontTrait(withName: "bold",
                                                           withTrait: UIFontDescriptorSymbolicTraits.TraitBold,
                                                           withEntryTextView: entryTextView) {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func applyItalicsStyle(sender: UIBarButtonItem) {
        
        if let _ = AttributedText.addOrRemoveFontTrait(withName: "oblique",
                                                       withTrait: UIFontDescriptorSymbolicTraits.TraitItalic,
                                                       withEntryTextView: entryTextView) {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func applyUnderlineStyle(sender: UIBarButtonItem) {
        if let _ = AttributedText.applyUnderlineStyle(withEntryTextView: entryTextView) {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func applySize(sender: UIBarButtonItem) {
        let alertTitle = NSLocalizedString("Select Text Style", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let titleActionTitle = NSLocalizedString("Title", comment: "")
        let titleAction = UIAlertAction(title: titleActionTitle, style: .Default) { (action) in
            AttributedText.applyStyleToSelection(UIFontTextStyleTitle1, withEntryTextView: self.entryTextView)
        }
        let subHeadlineActionTitle = NSLocalizedString("SubHeading", comment: "")
        let subHeadlineAction = UIAlertAction(title: subHeadlineActionTitle, style: .Default) { (action) in
            AttributedText.applyStyleToSelection(UIFontTextStyleSubheadline, withEntryTextView: self.entryTextView)
        }
        let bodyActionTitle = NSLocalizedString("Body", comment: "")
        let bodyAction = UIAlertAction(title: bodyActionTitle, style: .Default) { (action) in
            AttributedText.applyStyleToSelection(UIFontTextStyleBody, withEntryTextView: self.entryTextView)
        }
        let footnoteActionTitle = NSLocalizedString("Footnote", comment: "")
        let footnoteAction = UIAlertAction(title: footnoteActionTitle, style: .Default) { (action) in
            AttributedText.applyStyleToSelection(UIFontTextStyleFootnote, withEntryTextView: self.entryTextView)
        }
        let captionActionTitle = NSLocalizedString("Caption", comment: "")
        let captionAction = UIAlertAction(title: captionActionTitle, style: .Default) { (action) in
            AttributedText.applyStyleToSelection(UIFontTextStyleCaption1, withEntryTextView: self.entryTextView)
        }
        
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        
        alert.addAction(titleAction)
        alert.addAction(subHeadlineAction)
        alert.addAction(bodyAction)
        alert.addAction(footnoteAction)
        alert.addAction(captionAction)
        
        alert.addAction(cancelAction)
        
        // If on iPad, have to attach to toolbar
        alert.popoverPresentationController?.sourceView = editingToolbar
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func alignTextLeft(sender: UIBarButtonItem) { 
        if let _ = AttributedText.setParagraphAlignment(forAlignment: NSTextAlignment.Left, withEntryTextView: entryTextView) {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func alignTextCenter(sender: UIBarButtonItem) {
        if let _ = AttributedText.setParagraphAlignment(forAlignment: NSTextAlignment.Center, withEntryTextView: entryTextView) {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func alignTextRight(sender: UIBarButtonItem) {
        if let _ = AttributedText.setParagraphAlignment(forAlignment: NSTextAlignment.Right, withEntryTextView: entryTextView) {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func changeTextColor(sender: UIBarButtonItem) {        
        let alertTitle = NSLocalizedString("Select Text Color", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let blackActionTitle = NSLocalizedString("Black", comment: "The color black")
        let blackAction = UIAlertAction(title: blackActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.blackColor(), forEntryTextView: self.entryTextView)
        }
        let redActionTitle = NSLocalizedString("Red", comment: "The color red")
        let redAction = UIAlertAction(title: redActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.redColor(), forEntryTextView: self.entryTextView)
        }
        let orangeActionTitle = NSLocalizedString("Orange", comment: "The color orange")
        let orangeAction = UIAlertAction(title: orangeActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.orangeColor(), forEntryTextView: self.entryTextView)
        }
        let yellowActionTitle = NSLocalizedString("Yellow", comment: "The color yellow")
        let yellowAction = UIAlertAction(title: yellowActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.yellowColor(), forEntryTextView: self.entryTextView)
        }
        let greenActionTitle = NSLocalizedString("Green", comment: "The color green")
        let greenAction = UIAlertAction(title: greenActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.greenColor(), forEntryTextView: self.entryTextView)
        }
        let blueActionTitle = NSLocalizedString("Blue", comment: "The color blue")
        let blueAction = UIAlertAction(title: blueActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.blueColor(), forEntryTextView: self.entryTextView)
        }
        let purpleActionTitle = NSLocalizedString("Purple", comment: "The color purple")
        let purpleAction = UIAlertAction(title: purpleActionTitle, style: .Default) { (action) in
            AttributedText.changeTextColor(UIColor.purpleColor(), forEntryTextView: self.entryTextView)
        }
        
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        
        alert.addAction(blackAction)
        alert.addAction(redAction)
        alert.addAction(orangeAction)
        alert.addAction(yellowAction)
        alert.addAction(greenAction)
        alert.addAction(blueAction)
        alert.addAction(purpleAction)
        
        alert.addAction(cancelAction)
        
        // If on iPad, have to attach to toolbar
        alert.popoverPresentationController?.sourceView = editingToolbar
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Notification Handling
    
    func entryWasDeleted(notification: NSNotification) {
        if let notificationEntry = notification.object as? Entry {
            if notificationEntry == entry {
                entry = nil
                JournalVariables.entry = nil
                //JournalVariables.entryTimestamps = nil
                setupView()
            }
        }
    }
    
    
    // Not working on simulator - http://www.openradar.me/radar?id=6083508816576512
    @objc private func preferredContentSizeChanged(notification: NSNotification) {
        print("preferredContentSizeChanged in entry")
        entryTextView.font = UIFont.preferredFontForTextStyle(styleApplied)
    }


    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EntryDateSegueIdentifier:
                guard let navController = segue.destinationViewController as? UINavigationController,
                    let controller = navController.topViewController as? EntryDateViewController else { return }
                
                controller.delegate = self
                controller.coreDataStack = coreDataStack
                if invalidDate {
                    controller.showMessageLabel = true 
                }
            default:
                return 
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func setupView() {
        tabBarController?.navigationItem.rightBarButtonItem = saveButton
        
        if let entry = entry {
            Entry.setDateButton(forDateButton: dateButton, withEntry: entry)
            entryTextView.attributedText = entry.attributed_text
        } else {
            if let entryDate = entryDate {
                Entry.setDateButton(forDateButton: dateButton, withDate: entryDate)
            } else {
                Entry.setDateButton(forDateButton: dateButton, withEntry: nil)
            }
            saveButton.enabled = false
            entryTextView.attributedText = NSAttributedString()
            entryTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            
            title = "New Entry"
        }
        
        entryTextView.becomeFirstResponder()
        addDismissKeyboardButton()
    }
    
    
    private func entryExists() -> Bool {
        if entry == nil { // Adding a new entry
            
            // If a date is set, use that, otherwise use today's date
            var date = NSDate()
            if let entryDate = entryDate {
                date = entryDate
            }

            return Entry.entryExists(forDate: date, coreDataStack: coreDataStack)
        }
        
        return false
    }
    
    private func loadEntryForDateIfExists() {
        if entry == nil {
            // If a date is set, use that, otherwise use today's date
            var date = NSDate()
            if let entryDate = entryDate {
                date = entryDate
            }
            
            entry = Entry.getEntry(forDate: date, coreDataStack: coreDataStack)
            invalidDate = false
        }
    }
    
    private func addNotificationObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(
            self,
            selector: #selector(EntryViewController.entryWasDeleted(_:)),
            name: EntryWasDeletedNotificationKey,
            object: entry)
        
        notificationCenter.addObserver(
            self,
            selector: #selector(EntryViewController.preferredContentSizeChanged(_:)),
            name: UIContentSizeCategoryDidChangeNotification,
            object: nil)

    }
    
    private func addDismissKeyboardButton() {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            let dismissKeyboardButtonItem = UIBarButtonItem(image: UIImage(named: "HideKeyboard"), style: .Plain, target: entryTextView, action: #selector(UIResponder.resignFirstResponder))
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
            toolbar.items = [dismissKeyboardButtonItem]
            entryTextView.inputAccessoryView = toolbar
        }
    }
    
    private func showTextNotSelectedAlert() {
        let alertMessage = NSLocalizedString("Please select some text in order to apply styles.", comment: "")
        let alertTitle = NSLocalizedString("Select Text", comment: "")
        let actionTitle = NSLocalizedString("OK", comment: "")
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        let action = UIAlertAction(title: actionTitle, style: .Default, handler: nil)
        
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
}



extension EntryViewController: EntryDateViewControllerDelegate {
    func entryDateViewController(controller: EntryDateViewController, didSaveDate date: NSDate) {
        Entry.setDateButton(forDateButton: dateButton, withDate: date)
        
        invalidDate = false
        
        // Save the new date if have entry
        if let entry = entry {
            entry.created_at = date
            coreDataStack.saveContext()
            
            // Update the timestamps
            //setEntryTimestamps()
        }
    }
}

