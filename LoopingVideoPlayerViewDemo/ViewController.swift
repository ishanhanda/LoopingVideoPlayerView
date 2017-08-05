//
//  ViewController.swift
//  LoopingVideoPlayerViewDemo
//
//  Created by Ishan Handa on 11/08/16.
//  Copyright © 2016 Ishan Handa. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var loopingVideoPlayer: LoopingVideoPlayerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let localVideoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "kuala_lumpur_timelapse", ofType: "mp4")!)
        loopingVideoPlayer.videoURL = localVideoURL
        loopingVideoPlayer.videoGravity = AVLayerVideoGravityResizeAspect
        loopingVideoPlayer.beginPlayBack()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttontapped(_ sender: AnyObject) {
        let url = URL(string: "http://www.videezy.com")!
        UIApplication.shared.openURL(url)
    }
}

