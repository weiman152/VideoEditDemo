//
//  ChooseViewController.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit

class ChooseViewController: UIViewController {
    
    private let screenWidth: CGFloat = UIScreen.main.bounds.size.width
    private let screenHeight: CGFloat = UIScreen.main.bounds.size.height

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var items:[ChooseVideo.Video] = []
    private lazy var chooseVideoViewModel = ChooseVideoViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "选择视频"
        
        chooseVideoViewModel.getVideos {[weak self] (videos) in
            self?.items = videos
            DispatchQueue.main.async {
               self?.collectionView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    class func instance() -> ChooseViewController {
        let storyB = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyB.instantiateViewController(withIdentifier: "ChooseViewController") as! ChooseViewController
        return vc
    }

}

extension ChooseViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (screenWidth - 8) / 3.0, height: (screenWidth - 8) / 3.0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let vc = EditViewController.instance(video: items[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ChooseViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChooseCell",
                                                      for: indexPath) as! ChooseCell
        cell.set(video: items[indexPath.row])
        return cell
    }
    
}





