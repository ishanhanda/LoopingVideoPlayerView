# IHLoopingVideoPlayerView
An iOS UIView subclass that loops a video infinitely.

## Problem
Playing back to back videos is a simple task that is frequently needed. If you are planning to do this without joining the videos into a single file you will notice that the transition from one video to the next is not smooth.

IHLoopingVideoPlayerView plays back to back videos with a fade transition in between. It demonstrates this with a single video being played over and over with a smooth transition which makes it very difficult to identify the transition, giving the illusion of a never ending video. This can be used for example, if you need a video to be playing continuously in the background of a view.

## Usage
```swift
        let localVideoURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("GasFlames", ofType: "mov")!)
        loopingVideoPlayer.videoURL = localVideoURL
        loopingVideoPlayer.videoGravity = AVLayerVideoGravityResizeAspect
        loopingVideoPlayer.beginPlayBack()
```

<a href="http://www.videezy.com">Free Stock Video Footage by Videezy!</a>
