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
    
    private var oddVideoPlayerView = IHVideoPlayerView()
    private var evenVideoPlayerView = IHVideoPlayerView()
    
    private var currentVideoIndex: Int?
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
    private var isCurrentEven: Bool {
        get {
            guard let currentIndex = self.currentVideoIndex else { return false }
            return currentIndex % 2 == 0
        }
    }
    
    private var currentVideoPlayDuration: Double!
    
    private var fadeTime: Double = 2.0
    
    private var videoURLs: [NSURL]?
    
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
    
    func beginPlayBack() {
        guard let urls = self.videoURLs where urls.count > 0 else {
            return
        }
        
        self.currentVideoIndex = 0
        let playerItem = AVPlayerItem(URL: urls[0])
        playerItem.addObserver(self, forKeyPath: PlayerStatusKey, options: [.New, .Old], context: &self.EvenPlayerStatusContext)
        self.evenVideoPlayerView.player.replaceCurrentItemWithPlayerItem(playerItem)
        
        let nextPlayerItem = AVPlayerItem(URL: urls[1])
        nextPlayerItem.addObserver(self, forKeyPath: PlayerStatusKey, options: [.New, .Old], context: &self.OddPlayerStatusContext)
        self.oddVideoPlayerView.player.replaceCurrentItemWithPlayerItem(nextPlayerItem)
    }
    
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
                self.currentVideoPlayDuration = self.playerDurationForPlayerItem(self.oddVideoPlayerView.player.currentItem!)
                self.startPlaying()
            }
        case &self.EvenPlayerStatusContext where self.isCurrentEven:
            if self.evenVideoPlayerView.player.currentItem!.status == .ReadyToPlay {
                self.currentVideoPlayDuration = self.playerDurationForPlayerItem(self.evenVideoPlayerView.player.currentItem!)
                self.startPlaying()
            }
        default:
            break
        }
    }
    
    
    func playerDurationForPlayerItem(playerItem: AVPlayerItem) -> Double {
        return CMTimeGetSeconds(playerItem.duration) - self.fadeTime - 1
    }
}
