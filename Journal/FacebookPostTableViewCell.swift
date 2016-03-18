//
//  FacebookPostTableViewCell.swift
//  Journal
//
//  Created by Morgan Davison on 3/17/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

import UIKit

class FacebookPostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var postTextView: UITextView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
