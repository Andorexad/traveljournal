//
//  TableViewCell.swift
//  Mooskine
//
//  Created by Andi Xu on 12/12/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell, Cell {

    // Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        countLabel.text = nil
    }

}
