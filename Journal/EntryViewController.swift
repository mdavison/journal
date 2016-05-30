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
    @IBOutlet var editingToolbar: EditingToolbar!
    
    var coreDataStack: CoreDataStack!
    var entry: Entry?
    var entryDate: NSDate?
    var invalidDate = false
    var styleApplied = ""
    var addEntry = false
    var attributedTextModel = AttributedText()
    
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
        addNotificationObservers()
        attributedTextModel.entryTextView = entryTextView
        attributedTextModel.delegate = self
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
        
//        if let toolbar = NSBundle.mainBundle().loadNibNamed("EditingToolbar", owner: self, options: nil).first as? EditingToolbar {
//            entryTextView.inputAccessoryView = toolbar
//            entryTextView.reloadInputViews()
//        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if let toolbar = NSBundle.mainBundle().loadNibNamed("EditingToolbar", owner: self, options: nil).first as? EditingToolbar {
            entryTextView.inputAccessoryView = toolbar
            entryTextView.reloadInputViews()
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func save(sender: UIBarButtonItem) {
        entry = Entry.save(withEntry: entry, withDate: Entry.getButtonDate(forButton: dateButton), withText: entryTextView.attributedText, withCoreDataStack: coreDataStack)
        
        saveButton.enabled = false
        saveButton.title = "Saved"
        Entry.setDateButton(forDateButton: dateButton, withEntry: entry)
        title = "Journal Entry"
        
        // Post notification that entry was saved - then listen for it in calendar
        NSNotificationCenter.defaultCenter().postNotificationName(HasSavedEntryNotificationKey, object: self)
    }
    
    @IBAction func applyBoldStyle(sender: UIBarButtonItem) {
        // This works
        //editingToolbar.boldButton.image = UIImage(named: "BoldIconFilled")
        
        attributedTextModel.addOrRemoveFontTrait(withName: "bold", withTrait: UIFontDescriptorSymbolicTraits.TraitBold)
    }
    
    @IBAction func applyItalicsStyle(sender: UIBarButtonItem) {
        attributedTextModel.addOrRemoveFontTrait(withName: "oblique", withTrait: UIFontDescriptorSymbolicTraits.TraitItalic)
    }
    
    @IBAction func applyUnderlineStyle(sender: UIBarButtonItem) {
        attributedTextModel.applyUnderlineStyle()
    }
    
    @IBAction func applySize(sender: UIBarButtonItem) {
        let alertTitle = NSLocalizedString("Select Text Style", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let titleActionTitle = NSLocalizedString("Title", comment: "")
        let titleAction = UIAlertAction(title: titleActionTitle, style: .Default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyleTitle1)
        }
        let subHeadlineActionTitle = NSLocalizedString("SubHeading", comment: "")
        let subHeadlineAction = UIAlertAction(title: subHeadlineActionTitle, style: .Default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyleSubheadline)
        }
        let bodyActionTitle = NSLocalizedString("Body", comment: "")
        let bodyAction = UIAlertAction(title: bodyActionTitle, style: .Default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyleBody)
        }
        let footnoteActionTitle = NSLocalizedString("Footnote", comment: "")
        let footnoteAction = UIAlertAction(title: footnoteActionTitle, style: .Default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyleFootnote)
        }
        let captionActionTitle = NSLocalizedString("Caption", comment: "")
        let captionAction = UIAlertAction(title: captionActionTitle, style: .Default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyleCaption1)
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
        alert.popoverPresentationController?.barButtonItem = editingToolbar.textSizeButton
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func alignTextLeft(sender: UIBarButtonItem) { 
        attributedTextModel.setParagraphAlignment(forAlignment: NSTextAlignment.Left)
    }
    
    @IBAction func alignTextCenter(sender: UIBarButtonItem) {
        attributedTextModel.setParagraphAlignment(forAlignment: NSTextAlignment.Center)
    }
    
    @IBAction func alignTextRight(sender: UIBarButtonItem) {
        attributedTextModel.setParagraphAlignment(forAlignment: NSTextAlignment.Right)
    }
    
    @IBAction func changeTextColor(sender: UIBarButtonItem) {        
        let alertTitle = NSLocalizedString("Select Text Color", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let blackActionTitle = NSLocalizedString("Black", comment: "The color black")
        let blackAction = UIAlertAction(title: blackActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.blackColor())
        }
        let redActionTitle = NSLocalizedString("Red", comment: "The color red")
        let redAction = UIAlertAction(title: redActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.redColor())
        }
        let orangeActionTitle = NSLocalizedString("Orange", comment: "The color orange")
        let orangeAction = UIAlertAction(title: orangeActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.orangeColor())
        }
        let yellowActionTitle = NSLocalizedString("Yellow", comment: "The color yellow")
        let yellowAction = UIAlertAction(title: yellowActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.yellowColor())
        }
        let greenActionTitle = NSLocalizedString("Green", comment: "The color green")
        let greenAction = UIAlertAction(title: greenActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.greenColor())
        }
        let blueActionTitle = NSLocalizedString("Blue", comment: "The color blue")
        let blueAction = UIAlertAction(title: blueActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.blueColor())
        }
        let purpleActionTitle = NSLocalizedString("Purple", comment: "The color purple")
        let purpleAction = UIAlertAction(title: purpleActionTitle, style: .Default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.purpleColor())
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
        alert.popoverPresentationController?.barButtonItem = editingToolbar.textColorButton

        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func hideEditingToolbar(sender: UIBarButtonItem) {
        entryTextView.inputAccessoryView = nil
        entryTextView.reloadInputViews()
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
        
        // Add the toolbar
        if let toolbar = NSBundle.mainBundle().loadNibNamed("EditingToolbar", owner: self, options: nil).first as? EditingToolbar {
            entryTextView.inputAccessoryView = toolbar
        }
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
    
//    private func addDismissKeyboardButton() {
//        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
//            let dismissKeyboardButtonItem = UIBarButtonItem(image: UIImage(named: "HideKeyboard"), style: .Plain, target: entryTextView, action: #selector(UIResponder.resignFirstResponder))
//            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
//            toolbar.items = [dismissKeyboardButtonItem]
//            entryTextView.inputAccessoryView = toolbar
//        }
//    }
    
//    private func showTextNotSelectedAlert() {
//        let alertMessage = NSLocalizedString("Please select some text in order to apply styles.", comment: "")
//        let alertTitle = NSLocalizedString("Select Text", comment: "")
//        let actionTitle = NSLocalizedString("OK", comment: "")
//        
//        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
//        let action = UIAlertAction(title: actionTitle, style: .Default, handler: nil)
//        
//        alert.addAction(action)
//        
//        presentViewController(alert, animated: true, completion: nil)
//    }
    
}


extension EntryViewController: EntryDateViewControllerDelegate {
    func entryDateViewController(controller: EntryDateViewController, didSaveDate date: NSDate) {
        Entry.setDateButton(forDateButton: dateButton, withDate: date)
        
        invalidDate = false
        
        // Save the new date if have entry
        if let entry = entry {
            entry.created_at = date
            coreDataStack.saveContext()
        }
    }
}


extension EntryViewController: AttributedTextDelegate {
    
    func buttonToggled(forButtonName buttonName: EditingToolbarButtonName, isOn on: Bool) {
        switch buttonName {
        case EditingToolbarButtonName.Bold:
            print("bold toggled")
            editingToolbar.boldButton.image = on ? UIImage(named: "BoldIconFilled") : UIImage(named: "BoldIcon")
        case EditingToolbarButtonName.Italic:
            editingToolbar.italicsButton.image = on ? UIImage(named: "ItalicsIconFilled") : UIImage(named: "ItalicsIcon")
        case EditingToolbarButtonName.Underline:
            editingToolbar.underlineButton.image = on ? UIImage(named: "UnderlineIconFilled") : UIImage(named: "UnderlineIcon")
        default:
            return
        }
    }
    
    func buttonToggled(forColor color: UIColor) {
        editingToolbar.textColorButton.tintColor = color
    }
}

