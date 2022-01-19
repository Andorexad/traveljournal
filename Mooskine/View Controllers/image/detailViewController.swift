//
//  detailViewController.swift
//  Mooskine
//
//  Created by Andi Xu on 12/12/21.
//  Copyright © 2021 Udacity. All rights reserved.
//


import UIKit

class detailViewController: UIViewController {

   
    var m: Meme!
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var toplabel: UITextField!
    
    @IBOutlet weak var botlabel: UITextField!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toplabel.text = self.m.top
        self.botlabel.text = self.m.bottom
        self.tabBarController?.tabBar.isHidden = true
        self.imageView!.image = UIImage(data: self.m.ori!)
            
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

}
