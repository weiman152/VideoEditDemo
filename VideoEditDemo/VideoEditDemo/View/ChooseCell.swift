//
//  ChooseCell.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit

class ChooseCell: UICollectionViewCell {
    
    @IBOutlet weak var videoImage: UIImageView!
    @IBOutlet weak var videoDuration: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        videoImage.contentMode = .scaleAspectFill
    }
    
    func set(video: ChooseVideo.Video) {
        videoImage.image = video.image
        videoDuration.text = ChooseVideo.timeToHMS(time: Float(video.duration ?? 0))
    }
    
}
