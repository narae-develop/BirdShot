//
//  GameViewController.swift
//  ShotGame
//
//  Created by 조나래 on 2015. 12. 08.
//  Copyright (c) 2014년 조나래. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation

// AnyObject를 "anythingObj"라고도 표현할 수 있게 된다.
typealias anythingObj = AnyObject

class GameViewController: UIViewController {
    
    var birdInfo: Array<Int>?
    // 클래스에서 범용적으로 사용될 인스턴스 변수 선언
    var birdImg: UIImage?
    var birdDeadLeft: UIImage?
    var birdDeadRight: UIImage?
    var shotImg: UIImage?
    var bombImg: UIImage?
    var bangImg:UIImage?
    var imgDirection:Bool?
    var birdDirection: Array<Bool>?
    var birdArray: Array<UIImageView>?   // [UIImageView]? 와 같은 표현이다.
    var birdTypeArray : [Int]?
    var shotArray: [UIView]?         // Array<UIView>? 와 같은 표현이다.
    var birdSize: CGSize?
    var shotCheckTimer: NSTimer?
    var birdAddTimer: NSTimer?
    var gameCheckTimer: NSTimer?
    var shotSoundPlayer: AVAudioPlayer?
    var birdSoundPlayer: AVAudioPlayer?
    var boomSoundPlayer: AVAudioPlayer?
    var gameBGM: AVAudioPlayer?
    
    var birdRandTime = Double(0)
    
    var overtime = 60 //게임제한시간, 게임 난이도에 따라 타이머 조절 가능
    @IBOutlet weak var timeLabel: UILabel!
    
    var score = 0
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var gameView: UIView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        timeLabel.text = "Time : " + String(overtime)
        scoreLabel.text = "Score : " + String(score)
        
        
        // 생성된 참새 객체를 넣을 배열
        self.birdArray = [UIImageView]()
        self.birdInfo = [Int]()
        // 생성된 총알 객체를 넣을 배열
        self.shotArray = [UIView]()
        
        self.birdDirection = [Bool]()
        self.birdTypeArray = [Int]()
        
        // 참새 이미지로 사용할 이미지 로드
        self.birdImg = UIImage(named:"bird1")
        
        // 총알 이미지로 사용할 이미지 로드
        self.shotImg = UIImage(named: "bullet")
        
        // 폭탄 이미지로 사용할 이미지 로드
        self.bombImg = UIImage(named: "bomb1")
        
        // 폭발 이미지로 사용할 이미지 로드
        self.bangImg = UIImage(named: "bomb2")

        // 참새 이미지를 통한 참새 사이즈 가져오기
        self.birdSize = CGSize(width: self.birdImg!.size.width, height: self.birdImg!.size.height)
        
        // 번들 내 총소리 파일 위치
        guard let shotSrc = NSBundle.mainBundle().URLForResource("gunShot", withExtension:"mp3") else {
            return
        }
        
        // 번들 내 새소리 파일 위치
        guard let birdSrc = NSBundle.mainBundle().URLForResource("crow", withExtension:"wav") else {
            return
        }
        
        // 번들 내 배경 소리 파일위치
        guard let bgmSrc = NSBundle.mainBundle().URLForResource("gameBGM", withExtension:"mp3") else {
            return
        }
        
        // 번들 내 폭발소리 파일 위치
        guard let boomSrc = NSBundle.mainBundle().URLForResource("boom", withExtension:"aiff") else {
            return
        }
        
        // 총알소리를 재생할 플레이어 초기화 및 재생준비
        do {
            self.shotSoundPlayer = try AVAudioPlayer(contentsOfURL: shotSrc) as AVAudioPlayer
            self.shotSoundPlayer?.prepareToPlay()
        } catch _ {
            self.shotSoundPlayer = nil
            print("총알소리플레이어 초기화 실패")
        }
        
        // 새소리를 재생할 플레이어 초기화 및 재생준비
        do {
            self.birdSoundPlayer = try AVAudioPlayer(contentsOfURL: birdSrc) as AVAudioPlayer
            self.birdSoundPlayer?.prepareToPlay()
        } catch _ {
            self.birdSoundPlayer = nil
            print("새소리플레이어 초기화 실패")
        }
        
        // 배경소리를 재생할 플레이어 초기화 및 재생준비
        do {
            self.gameBGM = try AVAudioPlayer(contentsOfURL: bgmSrc) as AVAudioPlayer
            self.gameBGM?.prepareToPlay()
            self.gameBGM?.numberOfLoops = -1
            self.gameBGM?.play()
        } catch _ {
            self.gameBGM = nil
            print("배경음악 초기화 실패")
        }
        
        // 폭발소리를 재생할 플레이어 초기화 및 재생준비
        do {
            self.boomSoundPlayer = try AVAudioPlayer(contentsOfURL: boomSrc) as AVAudioPlayer
            self.boomSoundPlayer?.prepareToPlay()
        } catch _ {
            self.boomSoundPlayer = nil
            print("폭발소리플레이어 초기화 실패")
        }

        // 참새가 총알을 맞은 상태인지 0.1초 마다 체크할 타이머
        self.shotCheckTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("birdHitCheck:"), userInfo: nil, repeats: true)
        
        // 새로운 참새를 화면에 추가할 타이머
        self.birdAddTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("birdAdd"), userInfo: nil, repeats: true)
        
        self.gameCheckTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeCheck:"), userInfo: nil, repeats: true)
        
        // 총알을 발사하기 위해 Tap Gesuture Recognizer를 화면에 추가
        // delegate를 사용하지 않고도 바로 selector를 통하여 action을 설정해 줄 수도 있다.
        let shotGesuture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("shootTarget:"))
        self.view.addGestureRecognizer(shotGesuture)
    }
    
    // 객체가 화면에서 나타나거나 움직일 목표가 될 임의의 위치를 생성해 반환한다.
    func targetPosition(targetFrame: CGRect, viewLeft:Bool) -> (targetPoint: CGPoint, viewLeft: Bool) {
        let positionY = Int(rand())
        
        // 임의의 좌표를 위한 x, y 값을 만든다.
        let randY = positionY % Int(targetFrame.size.height - self.birdSize!.height)
        var randX = targetFrame.size.width + self.birdSize!.width
        
        // 화면 왼쪽이면 새가 안보이게 하기 위하여 x좌표를 새 크기만큼 왼쪽으로 더 옮겨준다.
        if (viewLeft) {
            randX = -self.birdSize!.width
        }
        
        // 좌표값인 CGPoint와 왼쪽인지 오른쪽인지에 대한 flag 전달. 사실 flag는 꼭 필요한 것은 아니지만 예제를 위해 첨부.
        return (CGPoint(x:CGFloat(randX), y:CGFloat(randY)) , viewLeft)
    }
    
    // 뷰를 특정 위치까지 이동시키는 애니메이션을 만들고 실행하는 메소드
    func viewMove(_view: UIView?, _viewPoint: CGPoint, _time: NSTimeInterval) {
        // 애니메이션 블록
        UIView.animateWithDuration(_time, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
            if let _moveView = _view {
                _moveView.frame = CGRect(origin: _viewPoint, size: _moveView.frame.size)
            }
            }, completion:{
                (compeleted: Bool) in
                // 애니메이션이 끝나면
                if (compeleted == true) {
                    if let _changeView = _view {
                        
                        // 배열 안의 객체 인덱스를 담을 임시변수
                        var _index: Int? = nil
                        
                        // 움직인 뷰가 UIImageView의 서브클래스라면 (새라면)
                        if _changeView.isKindOfClass(UIImageView) {
                            
                            // 인덱스값을 찾아서
                            _index = (self.birdArray!).indexOf(_changeView as! UIImageView)
                            
                            // 해당 인덱스의 참새를 지워준다.
                            self.birdArray?.removeAtIndex(_index!)
                            self.birdInfo?.removeAtIndex(_index!)
                            self.birdDirection?.removeAtIndex(_index!)
                            self.birdTypeArray?.removeAtIndex(_index!)
                            
                            // 움직임 뷰가 UIView의 서브클래스라면 (총알이라면)
                        } else if _changeView.isKindOfClass(UIView) {
                            
                            // 인덱스값을 찾아서
                            _index = (self.shotArray!).indexOf(_changeView)
                            // 해당 인덱스의 총알을 지워준다.
                            self.shotArray?.removeAtIndex(_index!)
                        }
                        
                        // 화면에서 우리눈에 보이지 않는다고 없어진 것이 아니다.
                        // 화면 바깥에 남아있는 뷰 객체를 화면에서 없애줘야 메모리가 해제될 것이다.
                        _changeView.removeFromSuperview()
                    }
                }
        })
    }
    
    // 화면에 새로운 참새를 한마리 더 추가하는 메소드
    func birdAdd()
    {
        // 왼쪽에서 나오도록 만들지 오른쪽에서 나오도록 만들지 결정
        let viewLeft: Bool = Bool(Int(rand()) % 2)
        let birdType = Int(arc4random_uniform(5) + 1)

        birdDirection?.append(viewLeft)
        
        // 'targetPosition' 메소드의 결과값
        var targetPositionResult = self.targetPosition(self.view.bounds, viewLeft: viewLeft)
        
        // 참새가 출발할 위치
        var birdPosition = targetPositionResult.targetPoint
        
        // 참새 이미지뷰 생성
        let bird: UIImageView = UIImageView(image: self.birdImg)
        if (viewLeft) {
            if(birdType==1) {
                bird.animationImages = [
                    UIImage(named: "bird3.png")!,
                    UIImage(named: "bird4.png")!
                ]
            } else if (birdType==2) {
                bird.animationImages = [
                    UIImage(named: "bird9.png")!,
                    UIImage(named: "bird10.png")!
                ]
            } else if (birdType==3) {
                bird.animationImages = [
                    UIImage(named: "bird15.png")!,
                    UIImage(named: "bird16.png")!
                ]
            } else if (birdType==4) {
                bird.animationImages = [
                    UIImage(named: "bird21.png")!,
                    UIImage(named: "bird22.png")!
                ]
            } else {
                bird.image = self.bombImg
            }
        } else {
            if(birdType==1) {
                bird.animationImages = [
                    UIImage(named: "bird1.png")!,
                    UIImage(named: "bird2.png")!
                ]
            } else if (birdType==2) {
                bird.animationImages = [
                    UIImage(named: "bird7.png")!,
                    UIImage(named: "bird8.png")!
                ]
            } else if (birdType==3) {
                bird.animationImages = [
                    UIImage(named: "bird13.png")!,
                    UIImage(named: "bird14.png")!
                ]
            } else if (birdType==4) {
                bird.animationImages = [
                    UIImage(named: "bird19.png")!,
                    UIImage(named: "bird20.png")!
                ]
            } else {
                bird.image = self.bombImg
            }
        }
        bird.animationDuration = 1
        bird.startAnimating()
        
        // 참새이미지뷰의 프레임 조절로 나타날 위치와 사이즈 조절
        bird.frame = CGRect(origin:birdPosition, size:self.birdSize!)
        
        // 화면에 참새 보여주기
        self.gameView.addSubview(bird)
        
        // 참새 배열에 참새 추가
        self.birdArray?.append(bird)
        
        // 참새가 이동할 임의의 위치 생성 (기존의 위치와 왼쪽 오른쪽이 반대이다)
        targetPositionResult = self.targetPosition(self.view.bounds, viewLeft: !viewLeft)
        birdPosition = targetPositionResult.targetPoint
        
        birdRandTime = Double(arc4random_uniform(4) + 2)
        self.birdInfo?.append(Int(birdRandTime))
        
        self.birdTypeArray?.append(birdType)
        
        // 뷰이동 메소드 호출
        self.viewMove(bird, _viewPoint:birdPosition, _time:birdRandTime)
    }
    
    // 화면에 새로운 총알을 쏘아올리는 메소드
    func shootTarget(sender: UITapGestureRecognizer? = nil)
    {
        let shotImgView : UIImageView = UIImageView(image: self.shotImg)
        // 총알을 만들고 쏘아올린다.
        let shotSize = CGSize(width: self.shotImg!.size.width, height: self.shotImg!.size.height)
        let shotX = sender?.locationInView(self.view).x
        let startPosition = CGPoint(x: shotX!, y: self.view.bounds.size.height + shotSize.height)
        let startPositionFrame: CGRect = CGRect(origin: startPosition, size: shotSize)
        let endPosition = CGPoint(x: shotX!, y: -shotSize.height)
        
        let shot: UIView = UIView(frame: startPositionFrame)
        
        shot.frame = CGRect(origin:startPosition, size:shotSize)
        //shot.backgroundColor = UIColor.blackColor()
        
        shot.addSubview(shotImgView)
        
        self.view.addSubview(shot)
        self.shotArray?.append(shot)
        
        self.viewMove(shot, _viewPoint: endPosition, _time:1)
        
        // 총알을 쏘아올림과 동시에 총소리를 재생한다.
        self.shotSoundPlayer?.currentTime = 0
        self.shotSoundPlayer?.play()
    }
    
    func timeCheck(_timer: NSTimer)
    {
        if(overtime>0) {
            overtime -= 1
            timeLabel.text = "Time : " + String(overtime)
        } else {
            _timer.invalidate()
            self.gameBGM?.stop()
            
            /*
            //이동할 뷰 컨트롤러 인스턴스 생성
            let uvc = self.storyboard?.instantiateViewControllerWithIdentifier("Over")
            //화면 전환 스타일 설정
            uvc?.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            //화면 전환
            self.presentViewController(uvc!, animated: true, completion: nil)
            */
            
            self.performSegueWithIdentifier("Over_screen", sender: self)

        }
    }

    override func prepareForSegue(segue:UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as! OverViewController
        destination.scoreText = String(score)
    }

    // 화면에 총알에 맞은 참새가 있는지 체크한다.
    func birdHitCheck(_timer: NSTimer)
    {
        // 참새배열안에 존재하는 참새들을 모두 검사한다.
        for _bird : anythingObj in self.birdArray! {
            let objView: UIImageView = _bird as! UIImageView
            
            // 참새이미지가 현재 어느 위치에 있는지 확인하기 위하여 참새 이미지뷰의 레이어를 가져온다.
            if let birdLayer: CALayer = objView.layer.presentationLayer() as? CALayer {
                
                // 총알배열에 존재하는 총알들을 모두 검사한다.
                for _shot : anythingObj in self.shotArray! {
                    if let shotView: UIView = _shot as? UIView {
                        if let _shotPosition: CGPoint = shotView.layer.presentationLayer()?.position {
                            
                            var bombBool: Bool = false
                            
                            // 참새레이어와 총알레이어가 겹쳐있다면 참새가 총을 맞은 상태다.
                            if (birdLayer.hitTest(_shotPosition) != nil)
                            {
                                // 참새배열과 총알배열에서 참새와 총알을 꺼낸다.
                                let _birdInx:Int? = (self.birdArray!).indexOf(objView)
                                let _shotInx:Int? = (self.shotArray!).indexOf(shotView)
                                
                                // 참새인덱스를 찾았다면 (참새배열에서 참새를 찾았다면)
                                if let _index = _birdInx {
                                    imgDirection = birdDirection![_index]
                                    // 죽은새 이미지로 사용할 이미지 로드
                                    if(birdTypeArray![_index]==1){
                                        self.birdDeadLeft = UIImage(named:"bird5")
                                        self.birdDeadRight = UIImage(named:"bird6")
                                        score = score + (100 - (25 * (birdInfo![_index]-2)))
                                    } else if(birdTypeArray![_index]==2){
                                        self.birdDeadLeft = UIImage(named:"bird11")
                                        self.birdDeadRight = UIImage(named:"bird12")
                                        score = score + (100 - (25 * (birdInfo![_index]-2)))
                                    } else if (birdTypeArray![_index]==3) {
                                        self.birdDeadLeft = UIImage(named:"bird17")
                                        self.birdDeadRight = UIImage(named:"bird18")
                                        score = score + (100 - (25 * (birdInfo![_index]-2)))
                                    } else if (birdTypeArray![_index]==4) {
                                        self.birdDeadLeft = UIImage(named:"bird23")
                                        self.birdDeadRight = UIImage(named:"bird24")
                                        score = score + (100 - (25 * (birdInfo![_index]-2)))
                                    } else {
                                        score = score - (100 - (100 - (25 * (birdInfo![_index]-2))))
                                        if(score<0) {
                                            score = 0
                                        }
                                        bombBool = true
                                    }
                                    
                                    self.birdArray?.removeAtIndex(_index)
                                    self.birdInfo?.removeAtIndex(_index)
                                    self.birdDirection?.removeAtIndex(_index)
                                    self.birdTypeArray?.removeAtIndex(_index)
                                }
                                
                                // 총알인덱스를 찾았다면 (총알배열에서 총알를 찾았다면)
                                if let _index = _shotInx {
                                    self.shotArray?.removeAtIndex(_index)
                                }
                                
                                // 총알과 참새 애니메이션을 중지한다.
                                shotView.layer.removeAllAnimations()
                                birdLayer.removeAllAnimations()
                                
                                // 참새와 총알의 현재위치를 찾는다
                                let _birdPosition: CGPoint = CGPoint(x: birdLayer.position.x - objView.frame.size.width / 2, y: birdLayer.position.y - objView.frame.size.height / 2)
                                let _shotPoint: CGPoint = CGPoint(x: shotView.layer.position.x - shotView.frame.size.width / 2, y: shotView.layer.position.y - shotView.frame.size.height / 2)
                                
                                // 현재 이동중인 위치로 참새 위치를 잡아준 후 죽은새 이미지로 교체한다.
                                objView.frame = CGRect(origin: _birdPosition, size: objView.frame.size)
                                if(!bombBool) {
                                    if((imgDirection) == true) {
                                        objView.image = self.birdDeadRight
                                    } else {
                                        objView.image = self.birdDeadLeft
                                    }
                                } else {
                                    objView.image = self.bangImg
                                }
                                
                                // 총알뷰의 위치도 현재 애니메이션 중인 위치로 잡아준다.
                                shotView.frame = CGRect(origin: _shotPoint, size: shotView.frame.size)
                                
                                // 서서히 사라지는 페이드아웃 애니메이션을 위해 메소드 실행
                                self.viewFadeOut([shotView, objView])
                                
                                scoreLabel.text = "Score : " + String(score)
                                
                                // 새나 폭탄이 맞는 소리를 재생해준다.
                                if(!bombBool) {
                                    self.birdSoundPlayer!.play()
                                    break;
                                } else {
                                    self.boomSoundPlayer!.play()
                                    break;
                                }
                            }
                        } else {
                            continue
                        }
                    } else {
                        continue
                    }
                }
            } else {
                continue
            }
        }
    }
    
    // 배열에 담긴 뷰들을 서서히 페이드아웃 시키는 애니메이션을 실행한다.
    func viewFadeOut(_viewArr: [UIView])
    {
        for _obj: anythingObj in _viewArr
        {
            let _view: UIView = _obj as! UIView
            
            // alpha 값을 이용하여 뷰를 서서히 사라지게하는 애니메이션
            UIView.animateWithDuration(0.7, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                _view.alpha = 0
                }, completion: {
                    (value: Bool) in
                    // 애니메이션이 끝나면 뷰를 화면에서 제거한다.
                    _view.removeFromSuperview()
            })
        }
    }
}

