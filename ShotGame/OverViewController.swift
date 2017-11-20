//
//  OverViewController.swift
//  ShotGame
//
//  Created by 조나래 on 2015. 12. 08.
//  Copyright © 2015년 조나래. All rights reserved.
//

import UIKit
import AVFoundation

class OverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    var scoreText: String = ""
    var gameBGM: AVAudioPlayer?

    @IBOutlet weak var tableView: UITableView!
    let textCellIdentifier = "TextCell"
    var scoreList : [String]?

    @IBOutlet weak var ScoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        self.scoreList = [String]()

        /* DB 체크 시작 */
        let filemgr = NSFileManager.defaultManager()
        let dirPaths = filemgr.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        let databasePath = dirPaths[0].URLByAppendingPathComponent("/ShotRank.db").path!

        if !filemgr.fileExistsAtPath(databasePath as String) {
            
            let connectDB = FMDatabase(path: databasePath as String)
            
            if connectDB == nil {
                print("Error: \(connectDB.lastErrorMessage())")
            }
            
            if connectDB.open() {
                let sql_stmt = "CREATE TABLE IF NOT EXISTS RANK (SEQ INTEGER PRIMARY KEY AUTOINCREMENT, SCORE INT, DATE DATE)"
                if !connectDB.executeStatements(sql_stmt) {
                    print("Error: \(connectDB.lastErrorMessage())")
                }
                connectDB.close()
            } else {
                print("Error: \(connectDB.lastErrorMessage())")
            }
        }
        /* DB 체크 끝*/
        /* DB 점수 insert & select */
        let connectDB = FMDatabase(path: databasePath as String)
        if connectDB.open() {
            let sql_stmt = "INSERT INTO RANK (SCORE, DATE) VALUES ('\(scoreText)', datetime('now','localtime'))"
            if !connectDB.executeStatements(sql_stmt) {
                print("ErrorInsert: \(connectDB.lastErrorMessage())")
            }
            let sql_stmt2 = "SELECT SCORE FROM RANK ORDER BY SCORE DESC LIMIT 5"
            let results:FMResultSet? = connectDB.executeQuery(sql_stmt2, withArgumentsInArray: nil)

            while results?.next() == true {
                let rankScore = results?.stringForColumn("SCORE")
                //let rankDate = results?.dateForColumn("DATE")
                //let bestScore = rankScore! + String(rankDate)
                scoreList?.append(rankScore!)
            }
            connectDB.close()
        } else {
            print("Error: \(connectDB.lastErrorMessage())")
        }
        /* DB 점수 insert & select */
        

        // Do any additional setup after loading the view.
        
        // 번들 내 배경소리 파일위치
        guard let 배경소리위치 = NSBundle.mainBundle().URLForResource("overBGM", withExtension:"wav") else {
            return
        }
        
        // 배경소리를 재생할 플레이어 초기화 및 재생준비
        do {
            self.gameBGM = try AVAudioPlayer(contentsOfURL: 배경소리위치) as AVAudioPlayer
            self.gameBGM?.prepareToPlay()
            self.gameBGM?.numberOfLoops = -1
            self.gameBGM?.play()
        } catch _ {
            self.gameBGM = nil
            print("배경음악 초기화 실패")
        }
        ScoreLabel.text = "Score:" + scoreText
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func Restart(sender: AnyObject) {
        self.gameBGM?.stop()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.scoreList?.count)!
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(textCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        let row = indexPath.row
        cell.textLabel?.text = String(self.scoreList![row])
        cell.textLabel?.textAlignment = NSTextAlignment.Center

        return cell
    }
}
