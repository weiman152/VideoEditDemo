//
//  ContestVideoPickerViewController.swift
//  LiveTrivia
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit
import Photos

class ContestVideoPickerViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private var info: Contest.PublishInfo!
    private let manager = PHCachingImageManager()
    private var assets = PHAsset.fetchAssets(with: .video, options: nil)
    
    private let loadingView = SystemLoadingView()
    
    lazy var navigationBar: NavigationBar = {
        $0.backButton.tintColor = .white
        $0.backgroundView.backgroundColor = .hex("27173C")
        return $0
    } ( NavigationBar() )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "上传视频"
        setup(navigationBar: navigationBar)
        setup()
        setupLayout()
        setupNotification()
    }
    
    private func setup() {
        view.addSubview(loadingView)
        loadingView.loadingView.activityIndicatorViewStyle = .white
        loadingView.backgroundColor = .hex("000000", alpha: 0.5)
        loadingView.cornerRadius = 6.auto()
    }
    
    private func setupLayout() {
        loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    private func setupNotification() {
        PHPhotoLibrary.shared().register(self)
    }
    
    override func gotoBack() {
        dismiss(animated: true) { }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private class func instance() -> ContestVideoPickerViewController {
        return StoryBoard.contest.instance()
    }
    
    class func instance(info: Contest.PublishInfo) -> ContestVideoPickerViewController {
        let vc = instance()
        vc.info = info
        return vc
    }
}

/// PHPhotoLibraryChangeObserver代理实现，图片新增、删除、修改开始后会触发
extension ContestVideoPickerViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        DispatchQueue.main.async { [weak self] in
            self?.assets = PHAsset.fetchAssets(with: .video, options: nil)
            self?.collectionView.reloadData()
        }
    }
}

extension ContestVideoPickerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (screenWidth - 4) / 3.0, height: (screenWidth - 4) / 3.0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        
        let option = PHVideoRequestOptions()
        option.version = .current
        option.deliveryMode = .automatic
        option.isNetworkAccessAllowed = true
        option.progressHandler = { (progress, error, bool, info) in
            print("\(progress) | \(bool)")
        }
        let asset = assets[indexPath.row]
        
        loadingView.start()
        manager.requestPlayerItem(forVideo: asset, options: option) {
            [weak self] (item, info) in
            guard let this = self else { return }
            guard let item = item else { return }
            DispatchQueue.main.async {
                this.loadingView.stop()
                let vc = ContestVideoClipViewController.instance(
                    item: item,
                    info: this.info
                )
                this.push(vc, animated: true)
            }
        }
    }
}

extension ContestVideoPickerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: ContestVideoPickerCell.self, for: indexPath)
        cell.set(manager: manager, asset: assets[indexPath.row])
        return cell
    }
}
