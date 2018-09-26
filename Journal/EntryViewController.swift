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

class EntryViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var entryTextView: UITextView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var editingToolbar: EditingToolbar!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var coreDataStack: CoreDataStack!
    var entry: Entry?
    var entryDate: Date?
    var invalidDate = false
    var styleApplied = ""
    var addEntry = false
    var attributedTextModel = AttributedText()
    var toolbar: EditingToolbar?
    var edited = false {
        didSet {
           saveButton.isEnabled = edited
        }
    }
    
    struct Storyboard {
        static var EntryDateSegueIdentifier = "EntryDate"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if addEntry { // User tapped Add button
            if entryExists() {
                invalidDate = true
                performSegue(withIdentifier: Storyboard.EntryDateSegueIdentifier, sender: nil)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Check if an entry already exists for this date
        if entryExists() {
            saveButton.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if edited {
            // Auto save
            saveAndNotify()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITextViewDelegate Methods
    
    func textViewDidChange(_ textView: UITextView) {
        edited = true 
        saveButton.title = "Save"
        if invalidDate == false {
            saveButton.isEnabled = true
        }
        
        // If user started to create new entry but then deleted the
        // text, assume they didn't mean to create the entry and
        // don't autosave
        if entry == nil && entryTextView.attributedText.string.isEmpty {
            edited = false
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if let toolbar = toolbar {
            entryTextView.inputAccessoryView = toolbar
            entryTextView.reloadInputViews()
        }
    }
    
    // MARK: - Table View Controller Methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    
    // MARK: - Actions
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        saveAndNotify()
        
        saveButton.isEnabled = false
        saveButton.title = "Saved" // This doesn't work
        Entry.setDateButton(forDateButton: dateButton, withEntry: entry)
        title = "Journal Entry"
    }
    
    @IBAction func applyBoldStyle(_ sender: UIBarButtonItem) {
        attributedTextModel.addOrRemoveFontTrait(withName: "bold", withTrait: UIFontDescriptorSymbolicTraits.traitBold)
    }
    
    @IBAction func applyItalicsStyle(_ sender: UIBarButtonItem) {
        attributedTextModel.addOrRemoveFontTrait(withName: "oblique", withTrait: UIFontDescriptorSymbolicTraits.traitItalic)
    }
    
    @IBAction func applyUnderlineStyle(_ sender: UIBarButtonItem) {
        attributedTextModel.applyUnderlineStyle()
    }
    
    @IBAction func applySize(_ sender: UIBarButtonItem) {
        let alertTitle = NSLocalizedString("Select Text Style", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
        
        let titleActionTitle = NSLocalizedString("Title", comment: "")
        let titleAction = UIAlertAction(title: titleActionTitle, style: .default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyle.title1.rawValue)
        }
        let subHeadlineActionTitle = NSLocalizedString("SubHeading", comment: "")
        let subHeadlineAction = UIAlertAction(title: subHeadlineActionTitle, style: .default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyle.subheadline.rawValue)
        }
        let bodyActionTitle = NSLocalizedString("Body", comment: "")
        let bodyAction = UIAlertAction(title: bodyActionTitle, style: .default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyle.body.rawValue)
        }
        let footnoteActionTitle = NSLocalizedString("Footnote", comment: "")
        let footnoteAction = UIAlertAction(title: footnoteActionTitle, style: .default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyle.footnote.rawValue)
        }
        let captionActionTitle = NSLocalizedString("Caption", comment: "")
        let captionAction = UIAlertAction(title: captionActionTitle, style: .default) { (action) in
            self.attributedTextModel.applyStyleToSelection(UIFontTextStyle.caption1.rawValue)
        }
        
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        
        alert.addAction(titleAction)
        alert.addAction(subHeadlineAction)
        alert.addAction(bodyAction)
        alert.addAction(footnoteAction)
        alert.addAction(captionAction)
        
        alert.addAction(cancelAction)
        
        // If on iPad, have to attach to toolbar
        alert.popoverPresentationController?.barButtonItem = editingToolbar.textSizeButton
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func alignTextLeft(_ sender: UIBarButtonItem) { 
        attributedTextModel.setParagraphAlignment(forAlignment: NSTextAlignment.left)
    }
    
    @IBAction func alignTextCenter(_ sender: UIBarButtonItem) {
        attributedTextModel.setParagraphAlignment(forAlignment: NSTextAlignment.center)
    }
    
    @IBAction func alignTextRight(_ sender: UIBarButtonItem) {
        attributedTextModel.setParagraphAlignment(forAlignment: NSTextAlignment.right)
    }
    
    @IBAction func changeTextColor(_ sender: UIBarButtonItem) {        
        let alertTitle = NSLocalizedString("Select Text Color", comment: "")
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
        
        let blackActionTitle = NSLocalizedString("Black", comment: "The color black")
        let blackAction = UIAlertAction(title: blackActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.black)
        }
        let redActionTitle = NSLocalizedString("Red", comment: "The color red")
        let redAction = UIAlertAction(title: redActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.red)
        }
        let orangeActionTitle = NSLocalizedString("Orange", comment: "The color orange")
        let orangeAction = UIAlertAction(title: orangeActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.orange)
        }
        let yellowActionTitle = NSLocalizedString("Yellow", comment: "The color yellow")
        let yellowAction = UIAlertAction(title: yellowActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.yellow)
        }
        let greenActionTitle = NSLocalizedString("Green", comment: "The color green")
        let greenAction = UIAlertAction(title: greenActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.green)
        }
        let blueActionTitle = NSLocalizedString("Blue", comment: "The color blue")
        let blueAction = UIAlertAction(title: blueActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.blue)
        }
        let purpleActionTitle = NSLocalizedString("Purple", comment: "The color purple")
        let purpleAction = UIAlertAction(title: purpleActionTitle, style: .default) { (action) in
            self.attributedTextModel.changeTextColor(UIColor.purple)
        }
        
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "")
        let cancelAction = UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil)
        
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

        
        present(alert, animated: true, completion: nil)
    }
    
//    @IBAction func hideEditingToolbar(sender: UIBarButtonItem) {
//        entryTextView.inputAccessoryView = nil
//        entryTextView.reloadInputViews()
//    }
    
    @IBAction func showEditingToolbar(_ sender: UIButton) {
        if let toolbar = toolbar {
            entryTextView.inputAccessoryView = toolbar
            entryTextView.reloadInputViews()
        }
    }
    
    
    // MARK: - Notification Handling
    
    func entryWasDeleted(_ notification: Notification) {
        if let notificationEntry = notification.object as? Entry {
            if notificationEntry == entry {
                entry = nil
                JournalVariables.entry = nil
                setupView()
            }
        }
    }
    
    
    // Not working on simulator - http://www.openradar.me/radar?id=6083508816576512
    @objc fileprivate func preferredContentSizeChanged(_ notification: Notification) {
        print("preferredContentSizeChanged in entry")
        entryTextView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle(rawValue: styleApplied))
    }
    
    func hideEditingToolbar() {
        entryTextView.inputAccessoryView = nil
        //entryTextView.reloadInputViews()
        entryTextView.resignFirstResponder()
    }


    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case Storyboard.EntryDateSegueIdentifier:
                guard let navController = segue.destination as? UINavigationController,
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
    
    fileprivate func setupView() {
        tabBarController?.navigationItem.rightBarButtonItem = saveButton
        
        // Theme
        Theme.setup(withNavigationController: navigationController)
        
        if let entry = entry {
            Entry.setDateButton(forDateButton: dateButton, withEntry: entry)
            entryTextView.attributedText = entry.attributed_text
        } else {
            if let entryDate = entryDate {
                Entry.setDateButton(forDateButton: dateButton, withDate: entryDate)
            } else {
                Entry.setDateButton(forDateButton: dateButton, withEntry: nil)
            }
            saveButton.isEnabled = false
            entryTextView.attributedText = NSAttributedString()
            entryTextView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            
            title = "New Entry"
        }
        
        entryTextView.becomeFirstResponder()
        
        // Add the toolbar
        toolbar = Bundle.main.loadNibNamed("EditingToolbar", owner: self, options: nil)!.first as? EditingToolbar
        if let toolbar = toolbar {
            entryTextView.inputAccessoryView = toolbar
            
            // Theme
            toolbar.barTintColor = Theme.Colors.barTint
            toolbar.tintColor = Theme.Colors.tint
        }
        
        
        
    }
    
    
    fileprivate func entryExists() -> Bool {
        if entry == nil { // Adding a new entry
            
            // If a date is set, use that, otherwise use today's date
            var date = Date()
            if let entryDate = entryDate {
                date = entryDate
            }

            return Entry.entryExists(forDate: date, coreDataStack: coreDataStack)
        }
        
        return false
    }
    
    fileprivate func loadEntryForDateIfExists() {
        if entry == nil {
            // If a date is set, use that, otherwise use today's date
            var date = Date()
            if let entryDate = entryDate {
                date = entryDate
            }
            
            entry = Entry.getEntry(forDate: date, coreDataStack: coreDataStack)
            invalidDate = false
        }
    }
    
    fileprivate func addNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(EntryViewController.entryWasDeleted(_:)),
            name: NSNotification.Name(rawValue: EntryWasDeletedNotificationKey),
            object: entry)
        
        notificationCenter.addObserver(
            self,
            selector: #selector(EntryViewController.preferredContentSizeChanged(_:)),
            name: NSNotification.Name.UIContentSizeCategoryDidChange,
            object: nil)
        
        notificationCenter.addObserver(
            self,
            selector: #selector(EntryViewController.hideEditingToolbar),
            name: NSNotification.Name.UIKeyboardDidHide,
            object: nil)
    }
    
    fileprivate func saveAndNotify() {
        entry = Entry.save(withEntry: entry, withDate: Entry.getButtonDate(forButton: dateButton), withText: entryTextView.attributedText, withCoreDataStack: coreDataStack)
        
        // Post notification that entry was saved - then listen for it in calendar
        NotificationCenter.default.post(name: Notification.Name(rawValue: HasSavedEntryNotificationKey), object: self)
    }
    
}


extension EntryViewController: EntryDateViewControllerDelegate {
    func entryDateViewController(_ controller: EntryDateViewController, didSaveDate date: Date) {
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
        case EditingToolbarButtonName.bold:
            editingToolbar.boldButton.image = on ? UIImage(named: "BoldIconFilled") : UIImage(named: "BoldIcon")
        case EditingToolbarButtonName.italic:
            editingToolbar.italicsButton.image = on ? UIImage(named: "ItalicsIconFilled") : UIImage(named: "ItalicsIcon")
        case EditingToolbarButtonName.underline:
            editingToolbar.underlineButton.image = on ? UIImage(named: "UnderlineIconFilled") : UIImage(named: "UnderlineIcon")
        default:
            return
        }
    }
    
    func buttonToggled(forColor color: UIColor) {
        editingToolbar.textColorButton.tintColor = color
    }
    
    func textWasEdited() {
        edited = true
    }
}

