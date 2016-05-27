//
//  AttributedText.swift
//  Journal
//
//  Created by Morgan Davison on 5/27/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

class AttributedText {
    
    static func addOrRemoveFontTrait(withName name: String, withTrait trait: UIFontDescriptorSymbolicTraits, withEntryTextView entryTextView: UITextView) -> String? {
        
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
            //showTextNotSelectedAlert()
            return "Text not selected"
        }
        
        return nil 
    }
    
    static func applyUnderlineStyle(withEntryTextView entryTextView: UITextView) -> String? {
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
            //showTextNotSelectedAlert()
            return "Text not selected"
        }
        
        return nil 
    }
    
    static func setParagraphAlignment(forAlignment alignment: NSTextAlignment, withEntryTextView entryTextView: UITextView) -> String? {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            let newParagraphStyle = NSMutableParagraphStyle()
            newParagraphStyle.alignment = alignment
            
            var attributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            attributes.updateValue(newParagraphStyle, forKey: NSParagraphStyleAttributeName)
            
            entryTextView.textStorage.beginEditing()
            entryTextView.textStorage.setAttributes(attributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            //showTextNotSelectedAlert()
            return "Text not selected"
        }
        
        return nil
    }
    
    static func applyStyleToSelection(style: String, withEntryTextView entryTextView: UITextView)  -> String? {
        let selectedRange = entryTextView.selectedRange
        
        if selectedRange.length > 0 {
            let styledFont = UIFont.preferredFontForTextStyle(style)
            var currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            
            currentAttributes.updateValue(styledFont, forKey: NSFontAttributeName)
            
            entryTextView.textStorage.beginEditing()
            entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
            entryTextView.textStorage.endEditing()
        } else {
            //showTextNotSelectedAlert()
            return "Text not selected"
        }
        
        return nil 
    }
    
    static func changeTextColor(color: UIColor, forEntryTextView entryTextView: UITextView) -> String? {
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
            //showTextNotSelectedAlert()
            return "Text not selected"
        }
        
        return nil 
    }

    

}