//
//  ViewController.swift
//  SpotifyLoadingScreen
//
//  Created by Kaushik Das on 23/6/15.
//  Copyright (c) 2015 com.kaushik. Free to use and modify at your own wish!
//

import UIKit
import MediaPlayer
import AVFoundation
import AVKit

// MARK: - Class Implementation
class IntroVideoViewController: BWWalkthroughViewController {
    
    // MARK: - Properties
    let playerController = AVPlayerViewController()
    let player = AVPlayer(url:NSURL.fileURL(withPath: Bundle.main.path(forResource: "black", ofType: "mp4")!))
    
    // MARK: - IBOutlets
    @IBOutlet var backgroundView: UIView!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure Movie Controller
        self.playerController.player = self.player
        self.playerController.showsPlaybackControls = false
        self.playerController.view.frame = self.backgroundView.frame
        self.playerController.videoGravity = AVLayerVideoGravityResize
        self.backgroundView.addSubview(playerController.view)
        
        // Add observer for Video Playback end; and then loop and play again
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(IntroVideoViewController.playerItemDidReachEnd(notification:)),
                                                         name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                         object: self.playerController.player!.currentItem)
        
    }
    
    deinit {
        print("deinit IntroVideoViewController")
    }
    
    // MARK: - Hide Status Bar
    override public var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    func playVideo(){
        // Start Movie Playback
        self.playerController.player!.play()
    }
    
    func stopVideo(){
        // Stop Movie Playback
        self.playerController.player!.pause()
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        // Reset Movie to Beginning (time = 0)
        self.playerController.player!.seek(to: kCMTimeZero)
        
        // Start Play Again
        self.playerController.player!.play()
    }
}

