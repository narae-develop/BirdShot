//
//  IntroViewController.swift
//  ShotGame
//
//  Created by 조나래 on 2015. 12. 08.
//  Copyright © 2015년 조나래. All rights reserved.
//

import UIKit
import AVFoundation

class IntroViewController: UIViewController {
    
    var gameBGM: AVAudioPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 번들 내 배경소리 파일위치
        guard let 배경소리위치 = NSBundle.mainBundle().URLForResource("introBGM", withExtension:"wav") else {
            return
        }
        
        // 배경소리를 재생할 플레이어 초기화 및 재생준비
        do {
            self.gameBGM = try AVAudioPlayer(contentsOfURL: 배경소리위치) as AVAudioPlayer
            self.gameBGM?.prepareToPlay()
            self.gameBGM?.play()
        } catch _ {
            self.gameBGM = nil
            print("배경음악 초기화 실패")
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func gamePlay(sender: AnyObject) {
        self.gameBGM?.stop()
    }
    
}
