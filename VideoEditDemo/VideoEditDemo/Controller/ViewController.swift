//
//  ViewController.swift
//  VideoEditDemo
//
//  Created by iOS on 2018/7/27.
//  Copyright © 2018年 weiman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    /// 选择视频
    @IBAction func chooseVideosAction(_ sender: UIButton) {
        let vc = ChooseViewController.instance()
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

