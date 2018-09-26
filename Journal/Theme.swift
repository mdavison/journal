//
//  Theme.swift
//  Journal
//
//  Created by Morgan Davison on 5/30/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

class Theme {
    
    struct Colors {
        // Color of the buttons
        static var tint = UIColor(red: 38.0/255.0, green: 165.0/255.0, blue: 1.0, alpha: 1)
        
        // Nav bar and toolbar backgrounds
        static var barTint = UIColor(red: 241.0/255.0, green: 255.0/255.0, blue: 1.0, alpha: 1)
        
        // Other colors
        static var sky = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 1.0, alpha: 1)
    }
    
    struct TextAttributes {
        static var font: UIFont {
            get {
                if let avenir = UIFont(name: "Avenir", size: 20) {
                    return avenir
                } else {
                    return UIFont.systemFont(ofSize: 20)
                }
            }
        }
        
        // Tungsten
        static var color = UIColor(red: 51.0/255.0, green: 51/255.0, blue: 51.0/255.0, alpha: 1)
    }
    
    static func setup(withNavigationController navigationController: UINavigationController?) {
        navigationController?.navigationBar.barTintColor = Theme.Colors.barTint
        navigationController?.navigationBar.tintColor = Theme.Colors.tint
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: Theme.TextAttributes.color]
    }
    
}
