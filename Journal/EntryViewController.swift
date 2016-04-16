//
//  EntryViewController.swift
//  Journal
//
//  Created by Morgan Davison on 3/11/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit
import CoreData
import FBSDKCoreKit
import FBSDKLoginKit
import TwitterKit

let TwitterHasLoggedInNotificationKey = "com.morgandavison.twitterHasLoggedInNotificationKey"

class EntryViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var coreDataStack: CoreDataStack!
    var entry: Entry?
    var entryDate: NSDate?
    var sinceTimestamp: Int?
    var untilTimestamp: Int?
    var journalTwitter = JournalTwitter()
    var invalidDate = false
    var styleApplied = ""
    
    struct Storyboard {
        static var EntryDateSegueIdentifier = "EntryDate"
        static var SignInSegueIdentifier = "SignIn"
    }
    
    deinit {
       NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        JournalVariables.entry = entry
        
        // Check if an entry already exists for this date
        if entryExists() {
            invalidDate = true
            performSegueWithIdentifier(Storyboard.EntryDateSegueIdentifier, sender: nil)
        }
        
        journalTwitter.coreDataStack = coreDataStack
        entryTextView.delegate = self
        setupView()
        setEntryTimestamps()
        
        // Notifications
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
        
        //notificationCenter.addObserver(self, selector: #selector(EntryViewController.twitterHasRefreshed(_:)), name: TwitterDidRefreshNotificationKey, object: twitterTweets) // This didn't work
        notificationCenter.addObserverForName(TwitterDidRefreshNotificationKey, object: nil, queue: nil) { (notification) in
            self.twitterHasRefreshed(notification)
        }

        
//        if FBSDKAccessToken.currentAccessToken() != nil {
//            // User already has access token
//            getFacebookPosts()
//        } else {
//            //showLoginButton()
//            // TODO: Show exclamation badge on Facebook tab
//        }
//        
//        if let _ = Twitter.sharedInstance().sessionStore.session()?.userID {
//            getTweets()
//        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        tabBarController?.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        tabBarController?.navigationItem.leftItemsSupplementBackButton = true
        
        fixNavigation() // Duplicate tabBarController navigation needs to be shown and hidden depending on orientation
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !JournalVariables.userIsAuthenticated {
            performSegueWithIdentifier(Storyboard.SignInSegueIdentifier, sender: nil)
        }
        
        tabBarController?.navigationItem.title = "Journal Entry"
        tabBarController?.navigationItem.rightBarButtonItem = saveButton
        
        // Check if an entry already exists for this date
        if entryExists() {
            saveButton.enabled = false
        }
    }
    

    
    // Redraw view when switches orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            self.fixNavigation()
        }) { (context: UIViewControllerTransitionCoordinatorContext) -> Void in
            // complete
        }
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
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
        if let entry = entry {
            // Save existing
            entry.created_at = getButtonDate()
            entry.updated_at = NSDate()
            //entry.text = entryTextView.text
            entry.attributed_text = entryTextView.attributedText
            
            coreDataStack.saveContext()
        } else {
            // TODO: Should send a notification so calendar (and maybe list too?) can be highlighted when new entry created when in split view
            // Create new
            let entryEntity = NSEntityDescription.entityForName("Entry", inManagedObjectContext: coreDataStack.managedObjectContext)
            entry = Entry(entity: entryEntity!, insertIntoManagedObjectContext: coreDataStack.managedObjectContext)
            entry?.created_at = getButtonDate()
            //entry?.text = entryTextView.text
            entry?.attributed_text = entryTextView.attributedText
            
            coreDataStack.saveContext()
        }
        
        saveButton.enabled = false
        saveButton.title = "Saved"
        setDateButton(withEntry: entry)
        title = "Journal Entry"
    }
    
    @IBAction func refreshTwitter(sender: UIButton) {
        journalTwitter.requestTweets()
    }
    
    @IBAction func applyBoldStyle(sender: UIBarButtonItem) {
        addOrRemoveFontTrait(withName: "bold", andTrait: UIFontDescriptorSymbolicTraits.TraitBold)
    }
    
    @IBAction func applyItalicsStyle(sender: UIBarButtonItem) {
        addOrRemoveFontTrait(withName: "oblique", andTrait: UIFontDescriptorSymbolicTraits.TraitItalic)
    }
    
    @IBAction func applyUnderlineStyle(sender: UIBarButtonItem) {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            var currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            
            if (currentAttributes[NSUnderlineStyleAttributeName] == nil) ||
                (currentAttributes[NSUnderlineStyleAttributeName]?.integerValue == 0) {
                currentAttributes.updateValue(1, forKey: NSUnderlineStyleAttributeName)
            } else {
                currentAttributes.updateValue(0, forKey: NSUnderlineStyleAttributeName)
            }
            
            entryTextView.textStorage.beginEditing()
            entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            showTextNotSelectedAlert()
        }
    }
    
    @IBAction func applySize(sender: UIBarButtonItem) {
        let alertTitle = NSLocalizedString("Select Text Style", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let titleActionTitle = NSLocalizedString("Title", comment: "")
        let titleAction = UIAlertAction(title: titleActionTitle, style: .Default) { (action) in
            self.applyStyleToSelection(UIFontTextStyleTitle1)
        }
        let subHeadlineActionTitle = NSLocalizedString("SubHeading", comment: "")
        let subHeadlineAction = UIAlertAction(title: subHeadlineActionTitle, style: .Default) { (action) in
            self.applyStyleToSelection(UIFontTextStyleSubheadline)
        }
        let bodyActionTitle = NSLocalizedString("Body", comment: "")
        let bodyAction = UIAlertAction(title: bodyActionTitle, style: .Default) { (action) in
            self.applyStyleToSelection(UIFontTextStyleBody)
        }
        let footnoteActionTitle = NSLocalizedString("Footnote", comment: "")
        let footnoteAction = UIAlertAction(title: footnoteActionTitle, style: .Default) { (action) in
            self.applyStyleToSelection(UIFontTextStyleFootnote)
        }
        let captionActionTitle = NSLocalizedString("Caption", comment: "")
        let captionAction = UIAlertAction(title: captionActionTitle, style: .Default) { (action) in
            self.applyStyleToSelection(UIFontTextStyleCaption1)
        }
        
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .Cancel, handler: nil)
        
        alert.addAction(titleAction)
        alert.addAction(subHeadlineAction)
        alert.addAction(bodyAction)
        alert.addAction(footnoteAction)
        alert.addAction(captionAction)
        
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func alignTextLeft(sender: UIBarButtonItem) { 
        setParagraphAlignment(NSTextAlignment.Left)
    }
    
    @IBAction func alignTextCenter(sender: UIBarButtonItem) {
        setParagraphAlignment(NSTextAlignment.Center)
    }
    
    @IBAction func alignTextRight(sender: UIBarButtonItem) {
        setParagraphAlignment(NSTextAlignment.Right)
    }
    
    @IBAction func changeTextColor(sender: UIBarButtonItem) {        
        let alertTitle = NSLocalizedString("Select Text Color", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let blackActionTitle = NSLocalizedString("Black", comment: "The color black")
        let blackAction = UIAlertAction(title: blackActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.blackColor())
        }
        let redActionTitle = NSLocalizedString("Red", comment: "The color red")
        let redAction = UIAlertAction(title: redActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.redColor())
        }
        let orangeActionTitle = NSLocalizedString("Orange", comment: "The color orange")
        let orangeAction = UIAlertAction(title: orangeActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.orangeColor())
        }
        let yellowActionTitle = NSLocalizedString("Yellow", comment: "The color yellow")
        let yellowAction = UIAlertAction(title: yellowActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.yellowColor())
        }
        let greenActionTitle = NSLocalizedString("Green", comment: "The color green")
        let greenAction = UIAlertAction(title: greenActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.greenColor())
        }
        let blueActionTitle = NSLocalizedString("Blue", comment: "The color blue")
        let blueAction = UIAlertAction(title: blueActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.blueColor())
        }
        let purpleActionTitle = NSLocalizedString("Purple", comment: "The color purple")
        let purpleAction = UIAlertAction(title: purpleActionTitle, style: .Default) { (action) in
            self.changeTextColor(UIColor.purpleColor())
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
        
        presentViewController(alert, animated: true, completion: nil)
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
    
    func twitterHasRefreshed(notification: NSNotification) {
//        twitterTableView.hidden = true
//        twitterTweets.removeAll()
//        getTweets()
//        twitterTableView.hidden = false
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
            setDateButton(withEntry: entry)
            entryTextView.attributedText = entry.attributed_text
        } else {
            if let entryDate = entryDate {
                setDateButton(withDate: entryDate)
            } else {
                setDateButton(withEntry: nil)
            }
            saveButton.enabled = false
            entryTextView.attributedText = NSAttributedString()
            entryTextView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            
            title = "New Entry"
        }
        
    }
    
    private func fixNavigation() {
        if let hidden = tabBarController?.navigationController?.navigationBarHidden {
            if hidden == true {
                tabBarController?.navigationController?.navigationBarHidden = false
            }
        }
    }
    
    private func setDateButton(withEntry entry: Entry?) {
        if let entry = entry {
            let formatter = getFormatter()
            dateButton.setTitle(formatter.stringFromDate(entry.created_at!), forState: .Normal)
        } else {
            let formatter = getFormatter()
            dateButton.setTitle(formatter.stringFromDate(NSDate()), forState: .Normal)
        }
    }
    
    private func setDateButton(withDate date: NSDate) {
        let formatter = getFormatter()
        
        dateButton.setTitle(formatter.stringFromDate(date), forState: .Normal)
    }
    
    private func getButtonDate() -> NSDate {
        let formatter = getFormatter()
        let buttonDate = formatter.dateFromString(dateButton.currentTitle!)
        if let date = buttonDate {
            return date
        }
        
        return NSDate()
    }
    
    private func getFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        
        return formatter
    }
    
    private func getEntryTimestamps() -> [String: Int] {
        let calendar = NSCalendar.currentCalendar()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var since = NSDate()
        var until = NSDate()
        
        if let entry = entry {
            if let createdAt = entry.created_at {
                // get date portion only of createdAt
                let entryDateComponents = calendar.components([.Day, .Month, .Year], fromDate: createdAt)
                
                // set the time to midnight and the last second
                let entryDateBegin = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 00:00:00"
                let entryDateEnd = "\(entryDateComponents.year)-\(entryDateComponents.month)-\(entryDateComponents.day) 23:59:59"
                
                since = formatter.dateFromString(entryDateBegin)!
                until = formatter.dateFromString(entryDateEnd)!
            }
        } else {
            let currentDateComponents = calendar.components([.Day, .Month, .Year], fromDate: NSDate())
            let currentDateBegin = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 00:00:00"
            let currentDateEnd = "\(currentDateComponents.year)-\(currentDateComponents.month)-\(currentDateComponents.day) 23:59:59"
            
            since = formatter.dateFromString(currentDateBegin)!
            until = formatter.dateFromString(currentDateEnd)!
        }
        
        let sinceTimestamp = Int(since.timeIntervalSince1970)
        let untilTimestamp = Int(until.timeIntervalSince1970)
        
        return ["since": sinceTimestamp, "until": untilTimestamp]
    }
    
    private func setEntryTimestamps() {
        let timestamps = getEntryTimestamps()
        
        JournalVariables.entryTimestamps = timestamps
        
        sinceTimestamp = timestamps["since"]
        untilTimestamp = timestamps["until"]
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
    
    // Heading, Subheading, etc.
    private func applyStyleToSelection(style: String) {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            let styledFont = UIFont.preferredFontForTextStyle(style)
            var currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            
            //let fontDict = [NSFontAttributeName: styledFont]
            currentAttributes.updateValue(styledFont, forKey: NSFontAttributeName)
            
            entryTextView.textStorage.beginEditing()
            //entryTextView.textStorage.setAttributes(fontDict, range: selectedRange)
            entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            showTextNotSelectedAlert()
        }
    }
    
    private func addOrRemoveFontTrait(withName name: String, andTrait trait: UIFontDescriptorSymbolicTraits) {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            var currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            let currentFontAttributes = currentAttributes[NSFontAttributeName]
            let fontDescriptor = currentFontAttributes!.fontDescriptor
            let currentFontSize = CGFloat(fontDescriptor().fontAttributes()["NSFontSizeAttribute"]! as! NSNumber)
            
            var changedFontDescriptor = UIFontDescriptor().fontDescriptorWithSymbolicTraits(trait)
            
            if let fontNameAttribute = fontDescriptor().fontAttributes()["NSFontNameAttribute"] as? String {
                if fontNameAttribute.lowercaseString.rangeOfString(name) == nil {
                    let existingTraitsRaw = fontDescriptor().symbolicTraits.rawValue | trait.rawValue
                    let existingTraits = UIFontDescriptorSymbolicTraits(rawValue: existingTraitsRaw)
                    changedFontDescriptor = UIFontDescriptor().fontDescriptorWithSymbolicTraits(existingTraits)
                } else {
                    let existingTraitsWithoutTraitRaw = fontDescriptor().symbolicTraits.rawValue & ~trait.rawValue
                    let existingTraitsWithoutTrait = UIFontDescriptorSymbolicTraits(rawValue: existingTraitsWithoutTraitRaw)
                    changedFontDescriptor = UIFontDescriptor().fontDescriptorWithSymbolicTraits(existingTraitsWithoutTrait)
                }
            }
            
            let updatedFont = UIFont(descriptor: changedFontDescriptor, size: currentFontSize)

            currentAttributes.updateValue(updatedFont, forKey: NSFontAttributeName)
            
            
            entryTextView.textStorage.beginEditing()
            entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            showTextNotSelectedAlert()
        }
    }
    
    private func setParagraphAlignment(alignment: NSTextAlignment) {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            let newParagraphStyle = NSMutableParagraphStyle()
            newParagraphStyle.alignment = alignment
            
            var attributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            attributes.updateValue(newParagraphStyle, forKey: NSParagraphStyleAttributeName)
            
            //let attributes = [NSParagraphStyleAttributeName: newParagraphStyle]
            
            entryTextView.textStorage.beginEditing()
            entryTextView.textStorage.setAttributes(attributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            showTextNotSelectedAlert()
        }
    }
    
    private func changeTextColor(color: UIColor) {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            var currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            
            if (currentAttributes[NSForegroundColorAttributeName] == nil) ||
                (currentAttributes[NSForegroundColorAttributeName] as! UIColor != color) {
                
                currentAttributes.updateValue(color, forKey: NSForegroundColorAttributeName)
            }
            
            entryTextView.textStorage.beginEditing()
            entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            showTextNotSelectedAlert()
        }
    }
    
    private func showTextNotSelectedAlert() {
        let alertMessage = NSLocalizedString("Please select some text in order to apply styles.", comment: "")
        let alertTitle = NSLocalizedString("Nothing Selected", comment: "")
        let actionTitle = NSLocalizedString("OK", comment: "")
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
        let action = UIAlertAction(title: actionTitle, style: .Default, handler: nil)
        
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
}





extension EntryViewController: EntryDateViewControllerDelegate {
    func entryDateViewController(controller: EntryDateViewController, didSaveDate date: NSDate) {
        setDateButton(withDate: date)
    }
}

