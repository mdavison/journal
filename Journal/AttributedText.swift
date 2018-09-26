//
//  AttributedText.swift
//  Journal
//
//  Created by Morgan Davison on 5/27/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

protocol AttributedTextDelegate: class {
    func buttonToggled(forButtonName buttonName: EditingToolbarButtonName, isOn on: Bool)
    func buttonToggled(forColor color: UIColor)
    func textWasEdited()
}

class AttributedText {
    
    var entryTextView: UITextView?
    var currentAttributes = [String: AnyObject]()
    weak var delegate: AttributedTextDelegate?
    
    
    func addOrRemoveFontTrait(withName name: String, withTrait trait: UIFontDescriptorSymbolicTraits) {
        if let entryTextView = entryTextView {
            var isOn = true
            let selectedRange = entryTextView.selectedRange
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
            } else {
                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
            }
            
            let currentFontAttributes = currentAttributes[NSFontAttributeName]
            let fontDescriptor = currentFontAttributes!.fontDescriptor
            let currentFontSize = CGFloat(fontDescriptor?.fontAttributes["NSFontSizeAttribute"]! as! NSNumber)
            
            var changedFontDescriptor = UIFontDescriptor().withSymbolicTraits(trait)
            
            if let fontNameAttribute = fontDescriptor?.fontAttributes["NSFontNameAttribute"] as? String {
                if fontNameAttribute.lowercased().range(of: name) == nil {
                    let existingTraitsRaw = (fontDescriptor?.symbolicTraits.rawValue)! | trait.rawValue
                    let existingTraits = UIFontDescriptorSymbolicTraits(rawValue: existingTraitsRaw)
                    changedFontDescriptor = UIFontDescriptor().withSymbolicTraits(existingTraits)
                } else {
                    let existingTraitsWithoutTraitRaw = (fontDescriptor?.symbolicTraits.rawValue)! & ~trait.rawValue
                    let existingTraitsWithoutTrait = UIFontDescriptorSymbolicTraits(rawValue: existingTraitsWithoutTraitRaw)
                    changedFontDescriptor = UIFontDescriptor().withSymbolicTraits(existingTraitsWithoutTrait)
                    isOn = false
                }
            }
            
            let updatedFont = UIFont(descriptor: changedFontDescriptor!, size: currentFontSize)
            
            currentAttributes.updateValue(updatedFont, forKey: NSFontAttributeName)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
            
            toggleButton(forStyle: name, isOn: isOn)
        }
    }

    func applyUnderlineStyle() {
        if let entryTextView = entryTextView {
            var isOn = true
            
            let selectedRange = entryTextView.selectedRange
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
            } else {
                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
            }
            
            if (currentAttributes[NSUnderlineStyleAttributeName] == nil) ||
                (currentAttributes[NSUnderlineStyleAttributeName]?.intValue == 0) {
                currentAttributes.updateValue(1 as AnyObject, forKey: NSUnderlineStyleAttributeName)
            } else {
                currentAttributes.updateValue(0 as AnyObject, forKey: NSUnderlineStyleAttributeName)
                isOn = false
            }
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
            
            toggleButton(forStyle: "underline", isOn: isOn)
        }
    }
    
    func applyStyleToSelection(_ style: String) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            let styledFont = UIFont.preferredFont(forTextStyle: UIFontTextStyle(rawValue: style))
            var currentAttributes = [String: AnyObject]()
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
            } else {
                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
            }
            
            currentAttributes.updateValue(styledFont, forKey: NSFontAttributeName)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
        }
    }

    func setParagraphAlignment(forAlignment alignment: NSTextAlignment) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            let newParagraphStyle = NSMutableParagraphStyle()
            newParagraphStyle.alignment = alignment
            
            var currentAttributes = [String: AnyObject]()
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
            } else {
                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
            }
            
            currentAttributes.updateValue(newParagraphStyle, forKey: NSParagraphStyleAttributeName)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
        }
    }
    
    func changeTextColor(_ color: UIColor) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            var currentAttributes = [String: AnyObject]()
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
            } else {
                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
            }
            
            if (currentAttributes[NSForegroundColorAttributeName] == nil) ||
                (currentAttributes[NSForegroundColorAttributeName] as! UIColor != color) {
                
                currentAttributes.updateValue(color, forKey: NSForegroundColorAttributeName)
            }
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
            
            toggleButton(forColor: color)
        }
    }
    
    
    fileprivate func toggleButton(forStyle style: String, isOn: Bool) {
        switch style {
        case "bold":
            delegate?.buttonToggled(forButtonName: EditingToolbarButtonName.bold, isOn: isOn)
        case "oblique":
            delegate?.buttonToggled(forButtonName: EditingToolbarButtonName.italic, isOn: isOn)
        case "underline":
            delegate?.buttonToggled(forButtonName: EditingToolbarButtonName.underline, isOn: isOn)
        default:
            return
        }
    }
    
    fileprivate func toggleButton(forColor color: UIColor) {
        delegate?.buttonToggled(forColor: color)
    }

}
