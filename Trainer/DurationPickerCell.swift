//
//  DurationPickerCell.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/16/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import UIKit

class DurationPickerCell: UITableViewCell {

    @IBOutlet weak var timePicker: UIDatePicker!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state

    }
    @IBAction func timeChanged(_ sender: Any) {
    }
    
}
