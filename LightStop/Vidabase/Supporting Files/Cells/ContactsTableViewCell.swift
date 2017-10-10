//
//  ContactsTableViewCell.swift
//  Vidabase
//
//  Created by Carlos Martinez on 4/26/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit

class ContactsTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastCommentLabel: UILabel!
    @IBOutlet weak var timeLastCommentLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.contactImageView.layer.cornerRadius = self.contactImageView.frame.size.width / 2
        self.contactImageView.clipsToBounds = true
        self.contactImageView.layer.borderWidth = 2.0
        self.contactImageView.layer.borderColor = UIColor.lightGray.cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
