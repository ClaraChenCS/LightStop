//
//  WebViewController.swift
//  Kamptive
//
//  Created by Carlos Martinez on 4/7/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit

// MARK: - Class Implementation
class WebViewController: UIViewController {

    // MARK: Properties
    var url:URL?      // Hold url - Usually set on Prepare for Segue Function
    
    // MARK: IBOutlets
    @IBOutlet weak var webView: UIWebView!  // Reference to elements on View

    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load URL set on url property
        webView.loadRequest(URLRequest(url: url!))
    }
    
    // MARK: - IBActions
    @IBAction func donePressed(_ sender: UIBarButtonItem) {
        
        // Dismiss Modal View Controller
        dismiss(animated: true, completion: nil)
    }

}
