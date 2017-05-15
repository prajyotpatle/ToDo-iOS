//
//  TaskCell.swift
//  To-Do
//
//  Created by Vaibhav Gote on 15/05/17.
//
//

import UIKit

class TaskCell: UITableViewCell {
    
    @IBOutlet weak var priorityView: UIView!
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var imageViewCheckbox: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
