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
}

class AttributedText {
    
    var entryTextView: UITextView?
    var currentAttributes = [String: AnyObject]()
    var delegate: AttributedTextDelegate?
    
    
    func addOrRemoveFontTrait(withName name: String, withTrait trait: UIFontDescriptorSymbolicTraits) {
        if let entryTextView = entryTextView {
            var isOn = true
            let selectedRange = entryTextView.selectedRange
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            } else {
                currentAttributes = entryTextView.typingAttributes
            }
            
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
                    isOn = false
                }
            }
            
            let updatedFont = UIFont(descriptor: changedFontDescriptor, size: currentFontSize)
            
            currentAttributes.updateValue(updatedFont, forKey: NSFontAttributeName)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
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
                currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            } else {
                currentAttributes = entryTextView.typingAttributes
            }
            
            if (currentAttributes[NSUnderlineStyleAttributeName] == nil) ||
                (currentAttributes[NSUnderlineStyleAttributeName]?.integerValue == 0) {
                currentAttributes.updateValue(1, forKey: NSUnderlineStyleAttributeName)
            } else {
                currentAttributes.updateValue(0, forKey: NSUnderlineStyleAttributeName)
                isOn = false
            }
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
            
            toggleButton(forStyle: "underline", isOn: isOn)
        }
    }
    
    func applyStyleToSelection(style: String) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            let styledFont = UIFont.preferredFontForTextStyle(style)
            var currentAttributes = [String: AnyObject]()
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            } else {
                currentAttributes = entryTextView.typingAttributes
            }
            
            currentAttributes.updateValue(styledFont, forKey: NSFontAttributeName)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
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
                currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            } else {
                currentAttributes = entryTextView.typingAttributes
            }
            
            currentAttributes.updateValue(newParagraphStyle, forKey: NSParagraphStyleAttributeName)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
        }
    }
    
    func changeTextColor(color: UIColor) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            var currentAttributes = [String: AnyObject]()
            
            if selectedRange.length > 0 {
                currentAttributes = entryTextView.textStorage.attributesAtIndex(selectedRange.location, effectiveRange: nil)
            } else {
                currentAttributes = entryTextView.typingAttributes
            }
            
            if (currentAttributes[NSForegroundColorAttributeName] == nil) ||
                (currentAttributes[NSForegroundColorAttributeName] as! UIColor != color) {
                
                currentAttributes.updateValue(color, forKey: NSForegroundColorAttributeName)
            }
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
            } else {
                entryTextView.typingAttributes = currentAttributes
            }
            
            toggleButton(forColor: color)
        }
    }
    
    
    private func toggleButton(forStyle style: String, isOn: Bool) {
        switch style {
        case "bold":
            delegate?.buttonToggled(forButtonName: EditingToolbarButtonName.Bold, isOn: isOn)
        case "oblique":
            delegate?.buttonToggled(forButtonName: EditingToolbarButtonName.Italic, isOn: isOn)
        case "underline":
            delegate?.buttonToggled(forButtonName: EditingToolbarButtonName.Underline, isOn: isOn)
        default:
            return
        }
    }
    
    private func toggleButton(forColor color: UIColor) {
        delegate?.buttonToggled(forColor: color)
    }

}