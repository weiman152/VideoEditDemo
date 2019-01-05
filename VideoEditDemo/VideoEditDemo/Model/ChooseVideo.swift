//
//  ChooseVideo.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import Photos

enum ChooseVideo { }

extension ChooseVideo {
    struct Video {
        var image: UIImage?             // 视频封面
        var duration: Double?           // 视频时长
        var localIdentifier: String?
        var asset: PHAsset?             // 操作信息的对象
        var videoUrl: URL?              // 视频本地地址
        var avSet: AVAsset?             // 剪辑控制
    }
}

extension ChooseVideo {
    
    static func timeToHMS(time: Float) -> String {
        
        let format = DateFormatter()
        if time / 3600 >= 1 {
            format.dateFormat = "HH:mm:ss"
        } else {
            format.dateFormat = "mm:ss"
        }
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        let string = format.string(from: date)
        return string
    }
    
    static func fml_getSeconds(asset: AVAsset) -> Float64 {
        let cmtime = asset.duration
        return CMTimeGetSeconds(cmtime)
    }
    
    static func fml_getFPS(asset: AVAsset) -> Float {
        let fps = asset.tracks(withMediaType: .video).last?.nominalFrameRate
        return fps ?? 0
    }
}
