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
    //var currentAttributes = [String: AnyObject]()
//    var currentAttributes = [NSAttributedString.NSAttributedString.Key: Any]()
    var currentAttributes = [NSAttributedString.Key: Any]()
    //var currentAttributes = [String: Any]()
    weak var delegate: AttributedTextDelegate?
    
    
    func addOrRemoveFontTrait(withName name: String, withTrait trait: UIFontDescriptor.SymbolicTraits) {
        if let entryTextView = entryTextView {
            var isOn = true
            let selectedRange = entryTextView.selectedRange
            
            if selectedRange.length > 0 {
//                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
            } else {
//                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
//                currentAttributes = convertTypingAttributes(from: convertFromNSAttributedStringKeyDictionary(entryTextView.typingAttributes))
                currentAttributes = entryTextView.typingAttributes
            }
            
            let currentFontAttributes = currentAttributes[NSAttributedString.Key.font] as! UIFont // TODO: wrap this in a guard
            let fontDescriptor = currentFontAttributes.fontDescriptor
            //let currentFontSize = CGFloat(fontDescriptor.fontAttributes["NSFontSizeAttribute"]! as! NSNumber)
            let currentFontSize = CGFloat(truncating: fontDescriptor.object(forKey: .size) as! NSNumber)
            // let fontAttribute = fontDescriptor.object(forKey: .face) as? String
            let fontName = fontDescriptor.object(forKey: .name) as? String
            
            var changedFontDescriptor = UIFontDescriptor().withSymbolicTraits(trait)
            
            //if let fontNameAttribute = fontDescriptor.fontAttributes["NSFontNameAttribute"] as? String {
            if let fontNameAttribute = fontName {
                if fontNameAttribute.lowercased().range(of: name) == nil {
                    let existingTraitsRaw = (fontDescriptor.symbolicTraits.rawValue) | trait.rawValue
                    let existingTraits = UIFontDescriptor.SymbolicTraits(rawValue: existingTraitsRaw)
                    changedFontDescriptor = UIFontDescriptor().withSymbolicTraits(existingTraits)
                } else {
                    let existingTraitsWithoutTraitRaw = (fontDescriptor.symbolicTraits.rawValue) & ~trait.rawValue
                    let existingTraitsWithoutTrait = UIFontDescriptor.SymbolicTraits(rawValue: existingTraitsWithoutTraitRaw)
                    changedFontDescriptor = UIFontDescriptor().withSymbolicTraits(existingTraitsWithoutTrait)
                    isOn = false
                }
            }
            
            let updatedFont = UIFont(descriptor: changedFontDescriptor!, size: currentFontSize)
            
            //currentAttributes.updateValue(updatedFont, forKey: NSFontAttributeName)
            currentAttributes.updateValue(updatedFont, forKey: NSAttributedString.Key.font)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
//                entryTextView.typingAttributes = convertToNSAttributedStringKeyDictionary(convertCurrentAttributes(from: currentAttributes))
            }
            
            toggleButton(forStyle: name, isOn: isOn)
        }
    }

    func applyUnderlineStyle() {
        if let entryTextView = entryTextView {
            var isOn = true
            
            let selectedRange = entryTextView.selectedRange
            
            if selectedRange.length > 0 {
//                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
            } else {
//                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
//                currentAttributes = convertTypingAttributes(from: convertFromNSAttributedStringKeyDictionary(entryTextView.typingAttributes))
                currentAttributes = entryTextView.typingAttributes
            }
            
            // let fontName = fontDescriptor.object(forKey: .name) as? String
            let underlineStyleAttribute = currentAttributes[NSAttributedString.Key.underlineStyle] as? NSNumber
            
//            if (currentAttributes[NSUnderlineStyleAttributeName] == nil) ||
//                (currentAttributes[NSUnderlineStyleAttributeName]?.intValue == 0) {
            if (underlineStyleAttribute == nil) || (underlineStyleAttribute?.intValue == 0) {
                //currentAttributes.updateValue(1 as AnyObject, forKey: NSUnderlineStyleAttributeName)
                currentAttributes.updateValue(1 as Any, forKey: NSAttributedString.Key.underlineStyle)
            } else {
                //currentAttributes.updateValue(0 as AnyObject, forKey: NSUnderlineStyleAttributeName)
                currentAttributes.updateValue(0 as Any, forKey: NSAttributedString.Key.underlineStyle)
                isOn = false
            }
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
//                entryTextView.typingAttributes = convertToNSAttributedStringKeyDictionary(convertCurrentAttributes(from: currentAttributes))
            }
            
            toggleButton(forStyle: "underline", isOn: isOn)
        }
    }
    
    func applyStyleToSelection(_ style: String) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            let styledFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle(rawValue: style))
            //var currentAttributes = [String: AnyObject]()
            
            if selectedRange.length > 0 {
//                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
            } else {
//                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
//                currentAttributes = convertTypingAttributes(from: convertFromNSAttributedStringKeyDictionary(entryTextView.typingAttributes))
                currentAttributes = entryTextView.typingAttributes
            }
            
            //currentAttributes.updateValue(styledFont, forKey: NSFontAttributeName)
            currentAttributes.updateValue(styledFont, forKey: NSAttributedString.Key.font)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
//                entryTextView.typingAttributes = convertToNSAttributedStringKeyDictionary(convertCurrentAttributes(from: currentAttributes))
            }
        }
    }

    func setParagraphAlignment(forAlignment alignment: NSTextAlignment) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            let newParagraphStyle = NSMutableParagraphStyle()
            newParagraphStyle.alignment = alignment
            
            //var currentAttributes = [String: AnyObject]()
            if selectedRange.length > 0 {
//                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
            } else {
//                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
//                currentAttributes = convertTypingAttributes(from: convertFromNSAttributedStringKeyDictionary(entryTextView.typingAttributes))
                currentAttributes = entryTextView.typingAttributes
            }
            
            //currentAttributes.updateValue(newParagraphStyle, forKey: NSParagraphStyleAttributeName)
            currentAttributes.updateValue(newParagraphStyle, forKey: NSAttributedString.Key.paragraphStyle)
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
//                entryTextView.typingAttributes = convertToNSAttributedStringKeyDictionary(convertCurrentAttributes(from: currentAttributes))
            }
        }
    }
    
    func changeTextColor(_ color: UIColor) {
        if let entryTextView = entryTextView {
            let selectedRange = entryTextView.selectedRange
            //var currentAttributes = [String: AnyObject]()
            
            if selectedRange.length > 0 {
                //currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil) as [String : AnyObject]
                currentAttributes = entryTextView.textStorage.attributes(at: selectedRange.location, effectiveRange: nil)
            } else {
//                currentAttributes = entryTextView.typingAttributes as [String : AnyObject]
//                currentAttributes = convertTypingAttributes(from: convertFromNSAttributedStringKeyDictionary(entryTextView.typingAttributes))
                currentAttributes = entryTextView.typingAttributes
            }
            
            let fontColor = currentAttributes[NSAttributedString.Key.foregroundColor] as? UIColor
            //if (currentAttributes[NSForegroundColorAttributeName] == nil) ||
            //(currentAttributes[NSForegroundColorAttributeName] as! UIColor != color) {
            if (fontColor == nil) || (fontColor != color) {
                //currentAttributes.updateValue(color, forKey: NSForegroundColorAttributeName)
                currentAttributes.updateValue(color, forKey: NSAttributedString.Key.foregroundColor)
            }
            
            if selectedRange.length > 0 {
                entryTextView.textStorage.beginEditing()
                entryTextView.textStorage.setAttributes(currentAttributes, range: selectedRange)
                entryTextView.textStorage.endEditing()
                delegate?.textWasEdited()
            } else {
                entryTextView.typingAttributes = currentAttributes
//                entryTextView.typingAttributes = convertToNSAttributedStringKeyDictionary(convertCurrentAttributes(from: currentAttributes))
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
    
//    fileprivate func convertTypingAttributes(from stringTuple: [String: Any]) -> [NSAttributedString.NSAttributedString.Key: Any] {
//        // Convert UITextView.typingAttributes from [String: Any] to [NSAttributedString.Key: Any]
//        let convertedTuple = Dictionary<<#Key: Hashable#>, Any>(uniqueKeysWithValues: stringTuple.map { (arg) -> <#Result#> in
//
//            let (key, value) = arg
//            return (NSAttributedString.NSAttributedString.Key(key), value)
//        })
//
//        return convertedTuple
//    }
    

//    fileprivate func convertCurrentAttributes(from attribTuple: [NSAttributedString.NSAttributedString.Key: Any]) -> [String: Any] {
//        // Convert currentAttributes to [String: Any]
//        let attribToString = Dictionary(uniqueKeysWithValues: attribTuple.map { key, value in
//            (String(key.rawValue), value)
//        })
//
//        return attribToString
//    }
}


//extension Dictionary where Key == NSAttributedStringKey {
//    func asTypingAttributes() -> [String: Any] {
//        var result = [String: Any]()
//
//        for (key, value) in self {
//            result[key.rawValue] = value
//
//        }
//
//        return result
//    }
//
//}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKeyDictionary(_ input: [NSAttributedString.Key: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
