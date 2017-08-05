//
//  LoopingVideoPlayerView.swift
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

class LoopingVideoPlayerView: UIView {
    
    fileprivate var OddPlayerStatusContext = "OddPlayerStatusContext"
    fileprivate var EvenPlayerStatusContext = "EvenPlayerStatusContext"
    
    fileprivate var PlayerStatusKey = "status"
    fileprivate var PlayerItemKey = "currentItem"
    
    /// Video player view responsible for playing odd index
    fileprivate var oddVideoPlayerView = VideoPlayerView()
    
    /// Video player view responsible for playing even index
    fileprivate var evenVideoPlayerView = VideoPlayerView()
    
    /// Index of the video to play
    fileprivate var currentVideoIndex: Int?
    
    /**
     Specifies how the video is displayed within an LoopingVideoPlayerView’s bounds.
     
     Options are AVLayerVideoGravityResizeAspect, AVLayerVideoGravityResizeAspectFill
     and AVLayerVideoGravityResize. AVLayerVideoGravityResizeAspectFill is default.
     See <AVFoundation/AVAnimation.h> for a description of these options.
     */
    public var videoGravity: String {
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
    fileprivate var nextVideoIndex: Int? {
        get {
            if let currentVideoIndex = self.currentVideoIndex ,let uRls = self.videoURLs, uRls.count > 0 {
                let newIndex = currentVideoIndex + 1
                return newIndex < uRls.count ? newIndex : 0
            } else {
                return nil
            }
        }
    }
    
    /// Helper to check if current index is even.
    fileprivate var isCurrentEven: Bool {
        get {
            guard let currentIndex = self.currentVideoIndex else { return false }
            return currentIndex % 2 == 0
        }
    }
    
    /// The duration for which the current video will be played before fading in the next loop.
    fileprivate var currentVideoPlayDuration: Double!
    
    /// Transion to to fade into next video.
    fileprivate var fadeTime: Double = 5.0
    
    /// stores copies of urls to be played back to back.
    fileprivate var videoURLs: [URL]?
    
    /// The url for the video to be played infinitely.
    public var videoURL: URL? {
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
    
    public override init(frame : CGRect) {
        super.init(frame : frame)
        self.commonInit()
    }
    
    public convenience init(videoURL: URL) {
        self.init(frame:CGRect.zero)
        self.videoURLs = [videoURL, videoURL]
    }
    
    public required init?(coder aDecoder: NSCoder) {
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
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[oddVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["oddVideoPlayerView": self.oddVideoPlayerView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[oddVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["oddVideoPlayerView": self.oddVideoPlayerView]))
        
        self.addSubview(self.evenVideoPlayerView)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[evenVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["evenVideoPlayerView": self.evenVideoPlayerView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[evenVideoPlayerView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["evenVideoPlayerView": self.evenVideoPlayerView]))
    }
    
    deinit {
        self.oddVideoPlayerView.player.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey, context: &self.OddPlayerStatusContext)
        self.evenVideoPlayerView.player.currentItem?.removeObserver(self, forKeyPath: self.PlayerStatusKey, context: &self.EvenPlayerStatusContext)
    }
}


// MARK: - LoopingVideoPlayerView Playback Control

extension LoopingVideoPlayerView {
    
    /// Call this function to start playng the video.
    public func beginPlayBack() {
        guard let urls = self.videoURLs, urls.count > 0 else {
            return
        }
        
        // Setting up even and odd players to play the first two items in urls
        self.currentVideoIndex = 0
        let playerItem = AVPlayerItem(url: urls[0])
        playerItem.addObserver(self, forKeyPath: PlayerStatusKey, options: [.new, .old], context: &self.EvenPlayerStatusContext)
        self.evenVideoPlayerView.player.replaceCurrentItem(with: playerItem)
        
        let nextPlayerItem = AVPlayerItem(url: urls[1])
        nextPlayerItem.addObserver(self, forKeyPath: PlayerStatusKey, options: [.new, .old], context: &self.OddPlayerStatusContext)
        self.oddVideoPlayerView.player.replaceCurrentItem(with: nextPlayerItem)
    }
    
    /**
     This function is called once the status for each AVPlayer changes to Ready to Play.
     
     it fades in the odd or even player based on odd or even index and stops playeing the other player.
     This is repeated infinitely so that the looping video appears to be one continuous video.
     */
    fileprivate func startPlaying() {
        if self.isCurrentEven {
            self.bringSubview(toFront: self.evenVideoPlayerView)
            self.evenVideoPlayerView.player.play()
            UIView.animate(withDuration: self.fadeTime, animations: {
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
                let playerItem = AVPlayerItem(url: self.videoURLs![self.currentVideoIndex!])
                playerItem.addObserver(self, forKeyPath: self.PlayerStatusKey, options: [.new, .old], context: &self.OddPlayerStatusContext)
                self.oddVideoPlayerView.player.replaceCurrentItem(with: playerItem)
            }
        } else {
            self.bringSubview(toFront: self.oddVideoPlayerView)
            self.oddVideoPlayerView.player.play()
            UIView.animate(withDuration: self.fadeTime, animations: {
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
                let playerItem = AVPlayerItem(url: self.videoURLs![self.currentVideoIndex!])
                playerItem.addObserver(self, forKeyPath: self.PlayerStatusKey, options: [.new, .old], context: &self.EvenPlayerStatusContext)
                self.evenVideoPlayerView.player.replaceCurrentItem(with: playerItem)
            }
        }
    }
}


/// utiltiy function to execute after time delay.
func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}


// MARK: - LoopingVideoPlayerView AVPlayer Observers

extension LoopingVideoPlayerView {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch context! {
        case &self.OddPlayerStatusContext where !self.isCurrentEven:
            if self.oddVideoPlayerView.player.currentItem!.status == .readyToPlay {
                // Calculate the duration for which the next item is to played.
                self.currentVideoPlayDuration = self.playerDurationForPlayerItem(self.oddVideoPlayerView.player.currentItem!)
                self.startPlaying()
            }
        case &self.EvenPlayerStatusContext where self.isCurrentEven:
            if self.evenVideoPlayerView.player.currentItem!.status == .readyToPlay {
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
    func playerDurationForPlayerItem(_ playerItem: AVPlayerItem) -> Double {
        return CMTimeGetSeconds(playerItem.duration) - self.fadeTime - 1
    }
}
