//
//  IHLoopingVideoPlayerView.swift
//
//  Copyright © 2016 Ishan Handa. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import AVFoundation

class IHLoopingVideoPlayerView: UIView {
    
    private var OddPlayerStatusContext = "OddPlayerStatusContext"
    private var EvenPlayerStatusContext = "EvenPlayerStatusContext"
    
    private var PlayerStatusKey = "status"
    private var PlayerItemKey = "currentItem"
    
    /// Video player view responsible for playing odd index
    private var oddVideoPlayerView = IHVideoPlayerView()
    
    /// Video player view responsible for playing even index
    private var evenVideoPlayerView = IHVideoPlayerView()
    
    /// Index of the video to play
    private var currentVideoIndex: Int?
    
    /**
     Specifies how the video is displayed within an IHLoopingVideoPlayerView’s bounds.
     
     Options are AVLayerVideoGravityResizeAspect, AVLayerVideoGravityResizeAspectFill
     and AVLayerVideoGravityResize. AVLayerVideoGravityResizeAspectFill is default.
     See <AVFoundation/AVAnimation.h> for a description of these options.
     */
    var videoGravity: String {
        set {
            (self.oddVideoPlayerView.layer as! AVPlayerLayer).videoGravity = newValue
            (self.evenVideoPlayerView.layer as! AVPlayerLayer).videoGravity = newValue
        }
        get {
            return (self.evenVideoPlayerView.layer as! AVPlayerLayer).videoGravity
        }
    }
    
    /**
     Gives the index of the next video to be played.
    */
    private var nextVideoIndex: Int? {
        get {
            if let currentVideoIndex = self.currentVideoIndex ,uRls = self.videoURLs where uRls.count > 0 {
                let newIndex = currentVideoIndex + 1
                return newIndex < uRls.count ? newIndex : 0
            } else {
                return nil
            }
        }
    }
    
    /// Helper to check if current index is even.
    private var isCurrentEven: Bool {
        get {
            guard let currentIndex = self.currentVideoIndex else { return false }
            return currentIndex % 2 == 0
        }
    }
    
    /// The duration for which the current video will be played before fading in the next loop.
    private var currentVideoPlayDuration: Double!
    
    /// Transion to to fade into next video.
    private var fadeTime: Double = 5.0
    
    /// stores copies of urls to be played back to back.
    private var videoURLs: [NSURL]?
    
    /// The url for the video to be played infinitely.
    var videoURL: NSURL? {
        get {
            return self.videoURLs?.first ?? nil
        }
        
        set {
            if let newValue = newValue {
                self.videoURLs = [newValue, newValue]
            } else {
                self.videoURLs = nil
            }
        }
    }
    
    
    // MARK: - Initalizers
    
    override init(frame : CGRect) {
        super.init(frame : frame)
        self.commonInit()
    }
    
    
    convenience init(videoURL: NSURL) {
        self.init(frame:CGRect.zero)
        self.videoURLs = [videoURL, videoURL]
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    
    private func commonInit() {
        // Initialize Players
        self.oddVideoPlayerView.player = AVPlayer()
        self.oddVideoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        self.evenVideoPlayerView.player = AVPlayer()
        self.evenVideoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create View Layout
        self.addSubview(self.oddVideoPlayerView)
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[oddVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["oddVideoPlayerView": self.oddVideoPlayerView]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[oddVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["oddVideoPlayerView": self.oddVideoPlayerView]))
        
        self.addSubview(self.evenVideoPlayerView)
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[evenVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["evenVideoPlayerView": self.evenVideoPlayerView]))
        self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[evenVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["evenVideoPlayerView": self.evenVideoPlayerView]))
    }
    
    
    deinit {
        self.oddVideoPlayerView.player.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey, context: &self.OddPlayerStatusContext)
        self.evenVideoPlayerView.player.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey, context: &self.EvenPlayerStatusContext)
    }
}


// MARK: - LoopingVideoPlayerView Playback Control

extension IHLoopingVideoPlayerView {
    
    /// Call this function to start playng the video.
    func beginPlayBack() {
        guard let urls = self.videoURLs where urls.count > 0 else {
            return
        }
        
        // Setting up even and odd players to play the first two items in urls
        self.currentVideoIndex = 0
        let playerItem = AVPlayerItem(URL: urls[0])
        playerItem.addObserver(self, forKeyPath: PlayerStatusKey, options: [.New, .Old], context: &self.EvenPlayerStatusContext)
        self.evenVideoPlayerView.player.replaceCurrentItemWithPlayerItem(playerItem)
        
        let nextPlayerItem = AVPlayerItem(URL: urls[1])
        nextPlayerItem.addObserver(self, forKeyPath: PlayerStatusKey, options: [.New, .Old], context: &self.OddPlayerStatusContext)
        self.oddVideoPlayerView.player.replaceCurrentItemWithPlayerItem(nextPlayerItem)
    }
    
    
    /**
     This function is called once the status for each AVPlayer changes to Ready to Play.
     
     it fades in the odd or even player based on odd or even index and stops playeing the other player.
     This is repeated infinitely so that the looping video appears to be one continuous video.
     */
    private func startPlaying() {
        if self.isCurrentEven {
            self.bringSubviewToFront(self.evenVideoPlayerView)
            self.evenVideoPlayerView.player.play()
            UIView.animateWithDuration(self.fadeTime, animations: {
                self.evenVideoPlayerView.alpha = 1
                }, completion: { (finished) in
                    if finished {
                        self.oddVideoPlayerView.alpha = 0
                    }
            })
            
            // Set up to play the odd video after current play duration.
            delay(self.currentVideoPlayDuration) {
                self.currentVideoIndex = self.nextVideoIndex
                self.oddVideoPlayerView.player.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey, context: &self.OddPlayerStatusContext)
                let playerItem = AVPlayerItem(URL: self.videoURLs![self.currentVideoIndex!])
                playerItem.addObserver(self, forKeyPath: self.PlayerStatusKey, options: [.New, .Old], context: &self.OddPlayerStatusContext)
                self.oddVideoPlayerView.player.replaceCurrentItemWithPlayerItem(playerItem)
            }
        } else {
            self.bringSubviewToFront(self.oddVideoPlayerView)
            self.oddVideoPlayerView.player.play()
            UIView.animateWithDuration(self.fadeTime, animations: {
                self.oddVideoPlayerView.alpha = 1
                }, completion: { (finished) in
                    if finished {
                        self.evenVideoPlayerView.alpha = 0
                    }
            })
            
            // Set up to play the even video after current play duration.
            delay(self.currentVideoPlayDuration) {
                self.currentVideoIndex = self.nextVideoIndex
                self.evenVideoPlayerView.player.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey, context: &self.EvenPlayerStatusContext)
                let playerItem = AVPlayerItem(URL: self.videoURLs![self.currentVideoIndex!])
                playerItem.addObserver(self, forKeyPath: self.PlayerStatusKey, options: [.New, .Old], context: &self.EvenPlayerStatusContext)
                self.evenVideoPlayerView.player.replaceCurrentItemWithPlayerItem(playerItem)
            }
        }
    }
}


/// utiltiy function to execute after time delay.
func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}


// MARK: - LoopingVideoPlayerView AVPlayer Observers

extension IHLoopingVideoPlayerView {
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        switch context {
        case &self.OddPlayerStatusContext where !self.isCurrentEven:
            if self.oddVideoPlayerView.player.currentItem!.status == .ReadyToPlay {
                // Calculate the duration for which the next item is to played.
                self.currentVideoPlayDuration = self.playerDurationForPlayerItem(self.oddVideoPlayerView.player.currentItem!)
                self.startPlaying()
            }
        case &self.EvenPlayerStatusContext where self.isCurrentEven:
            if self.evenVideoPlayerView.player.currentItem!.status == .ReadyToPlay {
                // Calculate the duration for which the next item is to played.
                self.currentVideoPlayDuration = self.playerDurationForPlayerItem(self.evenVideoPlayerView.player.currentItem!)
                self.startPlaying()
            }
        default:
            break
        }
    }
    
    /** 
     The duration for which an item should be played.
     Calculated by subtracting the fadeTime from the duration of the playerItem.
     */
    func playerDurationForPlayerItem(playerItem: AVPlayerItem) -> Double {
        return CMTimeGetSeconds(playerItem.duration) - self.fadeTime - 1
    }
}
