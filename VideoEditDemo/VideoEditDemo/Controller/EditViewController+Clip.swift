//
//  EditViewController+Clip.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/31.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import AVFoundation

extension EditViewController {
    
    func getClipImages() {
        guard let asset = asset else {
            return
        }
        totalSeconds = ChooseVideo.fml_getSeconds(asset: asset)
        var imageCount = 0
        if totalSeconds <= maxTime {
            imageCount = minImageCount
            screenSeconds = totalSeconds
        } else {
            imageCount = Int(ceil(Double(totalSeconds * Float64(minImageCount) / maxTime)))
            screenSeconds = maxTime
        }
    
        fml_getImagesCount(imageCount: imageCount) {[weak self] (image) in
            
            guard image != nil, let img = image, let this = self else {
                return
            }
            // 将图片压缩到最大20K进行显示
            let scaledImg = UIImage.resetImgSize(sourceImage: img, maxImageLenght: 300, maxSizeKB: 1024 * 20)
            if let img = scaledImg {
                this.showImages.append(img)
                DispatchQueue.main.async {
                    this.clipCollectionView.reloadData()
                }
            }
        }
    }
    
    func addGesture() {
        let leftPan = UIPanGestureRecognizer(target: self, action: #selector(leftPan(pan:)))
        clipLeftHandle.addGestureRecognizer(leftPan)
        
        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(rightPan(pan:)))
        clipRightHandle.addGestureRecognizer(rightPan)
    }
    
    @objc func leftPan(pan: UIPanGestureRecognizer) {
        let touchPoint = pan.location(in: nil)
        switch pan.state {
        case .began:
            clipLeftBeginPoint = touchPoint
        case .changed:
            let distance = pan.translation(in: view).x
            let newWidth = clipLeftBeginPoint.x + distance
            leftShadowViewWidthConstarint.constant = newWidth > 15 ? newWidth : 15
        case .ended:
            clipLeftBeginPoint = touchPoint
            
        default:
            break
        }
    }
    
    @objc func rightPan(pan: UIPanGestureRecognizer) {
        let touchPoint = pan.location(in: view)
        switch pan.state {
        case .began:
            clipRightBeginPoint = touchPoint
            clipRightWidth = screenWidth - clipRightBeginPoint.x
        case .changed:
            let distance = pan.translation(in: view).x
            let newWidth = clipRightWidth - distance
            rightShadowViewWidthConstraint.constant = newWidth > 15 ? newWidth : 15
        case .ended:
            clipRightBeginPoint = touchPoint
        default:
            break
        }
    }
    
}

extension EditViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ClipCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ClipCell", for: indexPath) as! ClipCell
        cell.showImage.image = showImages[indexPath.row]
        return cell
    }
}

extension EditViewController: UICollectionViewDelegateFlowLayout {
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: screenWidth / CGFloat(minImageCount), height: 56)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension EditViewController {
    
    func getOnePxSecond() -> Float {
        let totalWidth = clipCollectionView.contentSize.width
        let pxTime = totalTime / Float(totalWidth)
        return pxTime
    }
    
    func getStartTime() -> Float {
        let offsetX = clipCollectionView.contentOffset.x
        let width = offsetX + leftShadowViewWidthConstarint.constant
        return Float(width) * getOnePxSecond()
    }
    
    func getEndTime() -> Float {
        let offsetX = clipCollectionView.contentOffset.x
        let width = offsetX + clipRightHandle.frame.origin.x
        return Float(width) * getOnePxSecond()
    }
    
    func dragEnd() {
        let startTime = getStartTime()
        let endTime = getEndTime()
        clipTimeLabel.text = "已读取\(Int(endTime - startTime))秒"
        // 开始裁剪
        if let asset = asset {
           trimAsset(asset: asset, startSecond: startTime, endSecond: endTime)
        } else {
            print("裁剪失败")
        }
    }
}

extension EditViewController {

    func fml_getImagesCount(imageCount: Int, callBack: @escaping (UIImage?) -> Void) {
        
        guard let asset = asset else {
            return
        }
        let durationSeconds: Float64 = ChooseVideo.fml_getSeconds(asset: asset)
        // 获取视频的帧数
        let fps = ChooseVideo.fml_getFPS(asset: asset)
        var times: [NSValue] = []
        let totalFrames: Float64 = durationSeconds * Float64(fps)
        //一共切imageCount张图
        let perFrames = totalFrames / Float64(imageCount)
        var frame: Float64 = 0
        
        var timeFrame: CMTime = CMTimeMake(0, 0)
        
        while frame < totalFrames {
            // 帧率
            timeFrame = CMTimeMake(Int64(frame), Int32(fps))
            let timeValue = NSValue(time: timeFrame)
            times.append(timeValue)
            frame += perFrames
        }
        
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        // 防止时间出现偏差
        imgGenerator.requestedTimeToleranceBefore = kCMTimeZero
        imgGenerator.requestedTimeToleranceAfter = kCMTimeZero
        // 截图的时候调整到正确的方向
        imgGenerator.appliesPreferredTrackTransform = true
        
        imgGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, cgimage, actualTime, result, error) in
            
            switch result {
            case .cancelled:
                break
            case .failed:
                break
            case .succeeded:
                if let cgImage = cgimage {
                    let displayImage = UIImage(cgImage: cgImage)
                    callBack(displayImage)
                }
                
                callBack(nil)
            }
        }
        
    }
}

/// 视频裁剪
extension EditViewController {
    
    func trimAsset(asset: AVAsset, startSecond: Float, endSecond: Float) {
        
        var assetVideoTrack: AVAssetTrack?
        var assetAudioTrack: AVAssetTrack?
        
        if asset.tracks(withMediaType: .video).count > 0 {
            assetVideoTrack = asset.tracks(withMediaType: .video).first
        }
        if asset.tracks(withMediaType: .audio).count > 0 {
            assetAudioTrack = asset.tracks(withMediaType: .audio).first
        }
        
        let insertionPoint = kCMTimeZero
        let startDuration = CMTimeMakeWithSeconds(Float64(startSecond), Int32(ChooseVideo.fml_getFPS(asset: asset)))
        let duration = CMTimeMakeWithSeconds(Float64(endSecond - startSecond), Int32(ChooseVideo.fml_getFPS(asset: asset)))
        
        if assetVideoTrack != nil, let assetVideoTrack = assetVideoTrack {
            let compositionVideoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            do{
               try compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(startDuration, duration), of: assetVideoTrack, at: insertionPoint)
                compositionVideoTrack?.preferredTransform = assetVideoTrack.preferredTransform
            } catch {}
        }
        
        if assetAudioTrack != nil, let assetAudioTrack = assetAudioTrack {
            let compositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
               try compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(startDuration, duration), of: assetAudioTrack, at: insertionPoint)
            }catch{}
        }
        print("裁剪完成,准备导出")
        exportAsset()
    }
    
    
    /// 导出裁剪后的视频
    func exportAsset() {
        
        // 1. 创建用于导出视频的url
        let manager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let output = paths.first
        if var outputUrl = output {
            do {
                try manager.createDirectory(atPath: outputUrl, withIntermediateDirectories: true, attributes: nil)
                outputUrl = outputUrl.appending("\(Date().milliStamp).mp4")
                // 移除已经存在的文件
                if manager.fileExists(atPath: outputUrl) {
                    do {
                        try manager.removeItem(atPath: outputUrl)
                    } catch {
                        print(error)
                    }
                }
                // 2. 创建一个包含该组合的导出会话，并将导出的影片写入到照片库中。
                let exportSession = AVAssetExportSession.init(asset: mutableComposition.copy() as! AVAsset, presetName: AVAssetExportPreset1920x1080)
                guard let session = exportSession else {
                    print("exportSession 为空")
                    return
                }
                session.outputURL = URL(fileURLWithPath: outputUrl)
                session.outputFileType = AVFileType.mp4
                session.exportAsynchronously(completionHandler: {[weak self] in
                    
                    guard let this = self else {
                        return
                    }
                    
                    switch session.status {
                    case .completed:
                        this.outputURL = session.outputURL
                        print("---裁剪后的视频地址------ \(String(describing: this.outputURL))")
                    case .failed:
                        print("---导出错误-- \(String(describing: session.error))")
                    case .cancelled:
                        print("---取消导出-- \(String(describing: session.error))")
                    default:
                        break
                    }
                    
                })
                
            }catch{
                print(error)
            }
        } else {
            print("导出地址不存在")
        }
        
        
    }
    
}

extension UIImage {
    
    ///图片压缩方法
    
    class func resetImgSize(sourceImage : UIImage,maxImageLenght : CGFloat,maxSizeKB : CGFloat) -> UIImage? {
        
        var maxSize = maxSizeKB
        var maxImageSize = maxImageLenght
        if (maxSize <= 0.0) {
            maxSize = 1024.0;
        }
        
        if (maxImageSize <= 0.0)  {
            maxImageSize = 1024.0;
        }
        
        //先调整分辨率
        var newSize = CGSize.init(width: sourceImage.size.width, height: sourceImage.size.height)
        let tempHeight = newSize.height / maxImageSize;
        let tempWidth = newSize.width / maxImageSize;
        if (tempWidth > 1.0 && tempWidth > tempHeight) {
            newSize = CGSize.init(width: sourceImage.size.width / tempWidth, height: sourceImage.size.height / tempWidth)
        } else if (tempHeight > 1.0 && tempWidth < tempHeight){
            newSize = CGSize.init(width: sourceImage.size.width / tempHeight, height: sourceImage.size.height / tempHeight)
        }
        
        UIGraphicsBeginImageContext(newSize)
        
        sourceImage.draw(in: CGRect.init(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        var imageData = UIImageJPEGRepresentation(newImage!, 1.0)
        var sizeOriginKB : CGFloat = CGFloat((imageData?.count)!) / 1024.0;
        //调整大小
        var resizeRate = 0.9;
        while (sizeOriginKB > maxSize && resizeRate > 0.1) {
            imageData = UIImageJPEGRepresentation(newImage!,CGFloat(resizeRate));
            sizeOriginKB = CGFloat((imageData?.count)!) / 1024.0;
            resizeRate -= 0.1;
        }
        let finalImage = UIImage(data: imageData!)
        return finalImage
        
    }
}

extension Date {
    
    /// 获取当前 毫秒级 时间戳 - 13位
    var milliStamp : String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return "\(millisecond)"
    }
}










