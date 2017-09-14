//
//  WorkoutCell.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/14/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit

class WorkoutCell: UITableViewCell {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblDuration: UILabel!
    @IBOutlet weak var lblLast: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
