//
//  VideoInfoCell.swift
//  Flashmob
//
//  Created by  BlueYang on 2017/7/4.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit

class VideoInfoCell: UITableViewCell {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        // Initialization code
        titleLabel.layer.cornerRadius = 3.0
        titleLabel.alpha = 0.8
        titleLabel.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        print(self)
//        print(self.debugDescription)
//            print("address:\($0)")
        
    }
    
}
