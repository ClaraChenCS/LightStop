//
//  IntroCordinatorViewController.swift
//  Kamptive
//
//  Created by Carlos Martinez on 5/27/16.
//  Copyright © 2016 Carlos Martinez. All rights reserved.
//

import UIKit

// MARK: - Class Implementation
class IntroCordinatorViewController: UIViewController, BWWalkthroughViewControllerDelegate {
    let stb = UIStoryboard(name: "Main", bundle: nil)
    
    // MARK: - Properties
    lazy var introPage_five: IntroVideoViewController? = {
        return self.stb.instantiateViewController(withIdentifier: "IntroPage_5") as! IntroVideoViewController // Video
    }()
    
    lazy var introPage_four:UIViewController? = {
        return self.stb.instantiateViewController(withIdentifier: "IntroPage_4") // Still
    }()
    
    lazy var introPage_three:UIViewController? = {
        return self.stb.instantiateViewController(withIdentifier: "IntroPage_3") // Still
    }()
    
    lazy var introPage_two:UIViewController? = {
        return self.stb.instantiateViewController(withIdentifier: "IntroPage_2") // Still
    }()
    
    lazy var introPage_one:UIViewController? = {
        return self.stb.instantiateViewController(withIdentifier: "IntroPage_1") // Still
    }()
    
    lazy var introMain:BWWalkthroughViewController? = {
        return self.stb.instantiateViewController(withIdentifier: "IntroMain") as! BWWalkthroughViewController// Still
    }()
    
    // MARK: - View Life Cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set as Delegate
        introMain!.delegate = self
        
        // Attach the pages to the master
        introMain!.addViewController(vc: introPage_one!)
        introMain!.addViewController(vc: introPage_two!)
        introMain!.addViewController(vc: introPage_three!)
        introMain!.addViewController(vc: introPage_four!)
        introMain!.addViewController(vc: introPage_five!)
        
        //performSegueWithIdentifier("IntroCoordinatorToWalkThroughSegue", sender: self)
        self.present(introMain!, animated: true, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Release resources on Memory warning to avoid Crash; these resources are loaded 'Lazy'ly
        // so they can be reloaded on request
        introPage_one = nil
        introPage_two = nil
        introPage_three = nil
        introPage_four = nil
        introPage_five = nil
        introMain = nil
    }
    
    deinit {
        print("deinit IntroCordinatorViewController")
    }
    
    // MARK: - Hide Status Bar
    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    // MARK: - BWWalkthroughViewControllerDelegate Methods
    func walkthroughPageDidChange(pageNumber:Int) {
        // Call to delegate methods and check if we are on last page (#4); then play video and stop when other page
        if pageNumber == 4 {
            self.introPage_five!.playVideo()
        } else {
            self.introPage_five!.stopVideo()
        }
    }
    
    func stopVideo() {
        // Stop Video before leving Intro screen to Authentication
        self.introPage_five!.stopVideo()
    }
}
