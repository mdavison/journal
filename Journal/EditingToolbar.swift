//
//  EditingToolbar.swift
//  Journal
//
//  Created by Morgan Davison on 5/28/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

enum EditingToolbarButtonName {
    case bold
    case italic
    case underline
    case alignLeft
    case alignCenter
    case alignRight
    case color
    case size 
}

class EditingToolbar: UIToolbar {

    @IBOutlet weak var boldButton: UIBarButtonItem!
    @IBOutlet weak var italicsButton: UIBarButtonItem!
    @IBOutlet weak var underlineButton: UIBarButtonItem!
    @IBOutlet weak var textColorButton: UIBarButtonItem!
    @IBOutlet weak var textSizeButton: UIBarButtonItem!
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
