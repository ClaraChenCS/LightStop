//
//  ImageViewController.swift
//  uHype
//
//  Created by Carlos Martinez on 12/10/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {

    var imageToPresent:UIImage?
    
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        imageView.image = imageToPresent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }

}
