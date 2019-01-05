//
//  EditViewController.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import AVFoundation

class EditViewController: UIViewController {
    
    let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    let screenHeight: CGFloat = UIScreen.main.bounds.size.height
    
    // 当前正在播放的视频的信息
    var video: ChooseVideo.Video!
    
    /// 视频播放模块
    lazy var player: AVPlayer = {
        guard let url = currentPlayUrl else {
            return AVPlayer()
        }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        return player
    }()
    // 当前正在播放的视频，可以为空
    var currentPlayUrl: URL?
    // 画面层
    var playerLayer = AVPlayerLayer()
    // 播放进度的timer
    var playScheduleTimer = Timer()
    var totalTime: Float = 0
    
    /// 底部的裁剪模块
    
    // 最长时间限制
    let maxTime = 15.0
    let minTime = 5.0
    // 显示的图片个数
    let minImageCount = 15
    let lineWidth = 4
    
    @IBOutlet weak var clipCollectionView: UICollectionView!
    @IBOutlet weak var clipLeftHandle: UIButton!
    @IBOutlet weak var clipRightHandle: UIButton!
    @IBOutlet weak var leftShadowViewWidthConstarint: NSLayoutConstraint!
    @IBOutlet weak var rightShadowViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var clipTimeLabel: UILabel!
    
    var showImages: [UIImage] = []
    // 总秒数
    var totalSeconds: Float64 = 0
    // 当前屏幕显示的秒数
    var screenSeconds: Float64 = 0
    var asset: AVAsset?
    var clipLeftBeginPoint = CGPoint(x: 15, y: 0)
    var clipRightBeginPoint = CGPoint(x: UIScreen.main.bounds.size.width - 15, y: 0)
    var clipRightWidth: CGFloat = 15
    var mutableComposition: AVMutableComposition = AVMutableComposition()
    var outputURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addNotification()
        setup()
        setBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func setup() {
        print("------- \(video)")
        view.backgroundColor = .black
        if let url = video.videoUrl {
            let playLayer = setup(url: url, frame: view.bounds)
            view.layer.insertSublayer(playLayer, at: 0)
            player.play()
            
            asset = AVURLAsset(url: url, options: nil)
        }
        getClipImages()
        addGesture()
        
    }

    class func instance(video: ChooseVideo.Video) -> EditViewController {
        let storyB = UIStoryboard(name: "Main", bundle: nil)
        let vc: EditViewController = storyB.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        vc.video = video
        return vc
    }
    
}

extension EditViewController {
    
    private func setBackButton() {
        let button = UIButton(type: .custom)
        view.addSubview(button)
        button.frame = CGRect(x: 0, y: 20, width: 44, height: 44)
        button.setTitle("返回", for: .normal)
        button.addTarget(self, action: #selector(back), for: .touchUpInside)
        button.backgroundColor = .red
    }
    
    @objc func back() {
        removeVideo()
        navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func exportVideo(_ sender: UIButton) {
        dragEnd()
    }
}
