//
//  ViewController.swift
//  IHLoopingVideoPlayerViewDemo
//
//  Created by Ishan Handa on 11/08/16.
//  Copyright © 2016 Ishan Handa. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet var loopingVideoPlayer: IHLoopingVideoPlayerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let localVideoURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("GasFlames", ofType: "mov")!)
        loopingVideoPlayer.videoURL = localVideoURL
        loopingVideoPlayer.videoGravity = AVLayerVideoGravityResizeAspect
        loopingVideoPlayer.beginPlayBack()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttontapped(sender: AnyObject) {
        let url = NSURL(string: "http://www.videezy.com")!
        UIApplication.sharedApplication().openURL(url)
    }
}

