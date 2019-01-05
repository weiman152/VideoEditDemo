//
//  ChooseVideoViewModel.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import Photos

class ChooseVideoViewModel: NSObject {
    
    func getVideos(result: @escaping (([ChooseVideo.Video]) -> Void)) {
        let status = PHAuthorizationStatus.authorized
        if status == .restricted || status == .denied {
            // 无权访问,提示用户打开权限
            print("无权访问,提示用户打开权限")
            result([])
        } else {
            getVideosFromAlbum { (videos) in
                result(videos)
            }
        }
    }

}

extension ChooseVideoViewModel {
    
    /// 从相册中获取视频数组
    private func getVideosFromAlbum(result: @escaping (([ChooseVideo.Video]) -> Void)){
        var videos: [ChooseVideo.Video] = []
        // 获取所有资源的集合，并按资源的创建时间排序如果不写就是乱序
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let option = PHVideoRequestOptions()
        option.version = .current
        option.deliveryMode = .automatic
        
        let manager = PHImageManager.default()
        let assets: PHFetchResult = PHAsset.fetchAssets(with: .video, options: nil)
        
        var tempCount = assets.count
        // 获取视频
        for i in 0..<assets.count {
            
            let asset = assets.object(at: i)
            manager.requestAVAsset(forVideo: asset, options: option) { (avasset, audioMix, array) in
            
                let urlAsset: AVURLAsset = avasset as! AVURLAsset
                var model = ChooseVideo.Video()
                model.avSet = avasset
                model.videoUrl = urlAsset.url
                model.image = UIImage.thumbnailImageForVideo(videoURL: urlAsset.url, time: 0.5)
                model.duration = CMTimeGetSeconds(urlAsset.duration)
                videos.append(model)
                // 为了防止多次回调
                tempCount = tempCount - 1
                if tempCount == 0 {
                    result(videos)
                }
                
            }
        }
    }
}

extension UIImage {
    /// 根据视频url和时间点截图
    static func thumbnailImageForVideo(videoURL: URL, time: TimeInterval) -> UIImage? {
        
        let asset = AVURLAsset.init(url: videoURL, options: nil)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureMode.encodedPixels
        let thumbnailCGImage: CGImage?
        let thumbnailImageTime: CFTimeInterval = time
        var thumbnailImage: UIImage?
        do {
            thumbnailCGImage = try assetImageGenerator.copyCGImage(at: CMTimeMake(Int64(thumbnailImageTime),60), actualTime: nil)
            if let cgImage = thumbnailCGImage {
                thumbnailImage = UIImage(cgImage: cgImage)
            }
            
        } catch {
            
        }
        
        return thumbnailImage
    }
}







