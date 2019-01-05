//
//  EditViewController+VideoPlay.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/31.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import AVFoundation

extension EditViewController {
    
    func setup(url: URL, frame: CGRect) -> AVPlayerLayer {
        currentPlayUrl = url
        
        let playItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playItem)
        // 添加观察者
        addObserverToPlayItem()
        // 监控播放进度
        setupScheduleTimer()
        
        playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = frame
        playerLayer.videoGravity = .resizeAspect
        return playerLayer
    }
    
}

extension EditViewController {
    
    func replay() {
        if let playerItem = player.currentItem {
            playerItem.seek(to: kCMTimeZero, completionHandler: nil)
        }
        player.play()
    }
    
    func removeVideo() {
        if let playerItem = player.currentItem {
            playerItem.seek(to: kCMTimeZero, completionHandler: nil)
            playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
        player.replaceCurrentItem(with: nil)
        currentPlayUrl = nil
        playerLayer.removeFromSuperlayer()
        playScheduleTimer.invalidate()
    }
    
}

/// 通知
extension EditViewController {
    
    func addNotification() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playItemDidPlayToEnd(nitification:)),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    @objc private func playItemDidPlayToEnd(nitification: Notification) {
        print("播放完成")
        replay()
    }
}

/// 观察者
extension EditViewController {
    
    //添加观察者，观察视频下载过程以及视频播放状态
    private func addObserverToPlayItem() {
        guard let item = player.currentItem else {
            return
        }
        item.addObserver(self,
                         forKeyPath: "loadedTimeRanges",
                         options: .new,
                         context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let item = object,
            item is AVPlayerItem else {
                return
        }
        let playItem: AVPlayerItem = item as! AVPlayerItem
        
        let totalTimeM = playItem.duration
        let totalTime = Float(totalTimeM.value)/Float(totalTimeM.timescale)
        self.totalTime = totalTime
        // 缓冲
        if keyPath == "loadedTimeRanges" {
            // 加载时间
            let array = playItem.loadedTimeRanges
            // 本次缓冲时间范围
            let timeRange = array.first as! CMTimeRange
            let start: Float = Float(CMTimeGetSeconds(timeRange.start))
            let duration: Float = Float(CMTimeGetSeconds(timeRange.duration))
            //缓冲总时长
            let totalBuffer: TimeInterval = TimeInterval(start + duration)
            //缓冲进度
            let progress: Float = Float(totalBuffer*1.0)/Float(totalTime)
            DispatchQueue.main.async { 
                print("----progress:----- \(progress)")
            }
        }
        
    }
    
}

/// 播放进度
extension EditViewController {
    
    func setupScheduleTimer() {
        if playScheduleTimer.isValid == true {
            playScheduleTimer.invalidate()
        }
        playScheduleTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(scheduleTimer), userInfo: nil, repeats: true)
    }
    
    @objc func scheduleTimer() {
        guard let item = player.currentItem else {
            return
        }
        let currentProgress = CMTimeGetSeconds(item.currentTime())/CMTimeGetSeconds(item.duration)
        let time: CMTime = item.currentTime()
        let currentTime = Float(time.value) / Float(time.timescale)
//        delegate?.updatePlayTime(progress: Float(currentProgress),
//                                 value: currentTime)
    }
    
}
