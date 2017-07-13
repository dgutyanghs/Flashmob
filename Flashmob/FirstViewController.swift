//
//  FirstViewController.swift
//  Flashmob
//
//  Created by  BlueYang on 2017/6/27.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit
import Alamofire
import RxAlamofire
import RxSwift
import RxCocoa
import SwiftyJSON
import AlamofireImage
import SwiftMessages
import ESPullToRefresh
import AVFoundation
import AVKit

class FirstViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var videoArray = Variable<[Video]> ([])
    let bag = DisposeBag ()

    
    var manager:SessionManager? = nil
    let videoArrayKey = "videoArraykey"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "短视频"
        
        ///网络下载并发个数限制
        let config: URLSessionConfiguration = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = 20
        self.manager = Alamofire.SessionManager(configuration: config)
        
        ///looking for last time in local Plist
        let tmp:[AnyObject]? = UserDefaults.standard.value(forKey: videoArrayKey) as? [AnyObject]
        videoArray.value = Video.extractValuesFromPropertyListArray(propertyListArray: tmp)
        // Do any additional setup after loading the view, typically from a nib.
        
        let cellID = "videoCellStoryboard"
        /// 因为该tableViewCell是在Storyboard中定义，所以不需要register方法
//        tableView.register(VideoInfoCell.self, forCellReuseIdentifier: cellID)
        tableView.es_addPullToRefresh {
            [weak self] in
            self?.downloadVideoInfo()
            self?.tableView.es_stopPullToRefresh()
        }
        
       
        videoArray.asObservable().observeOn(MainScheduler.instance).bind(to: tableView.rx.items(cellIdentifier: cellID, cellType: VideoInfoCell.self)) {
            _, videoItem, cell  in
            cell.titleLabel.text = "  " + videoItem.title
            cell.bgImageView.af_setImage(withURL: URL.init(string: videoItem.cover)!)
            cell.textView.text = videoItem.desc
            cell.progressBar.progress = videoItem.progress
            if videoItem.progress == 1.0 {
                cell.titleLabel.textColor = UIColor.green
            }else {
                cell.titleLabel.textColor = UIColor.white
            }
        }.addDisposableTo(bag)
        
        
        let cellTapedObservable = Observable.combineLatest(tableView.rx.modelSelected(Video.self), tableView.rx.itemSelected) { (videoItem, indexPath) -> (Video, IndexPath)   in
            return (videoItem, indexPath)
        }
        
        cellTapedObservable.debounce(0.5, scheduler: ConcurrentMainScheduler.instance)
            .subscribe(onNext: {
           [weak self]  tuple in
                
            let video = tuple.0
            /// 1: video has download finished, play it
            if video.progress == 1.0 {
                self?.playVideo(video)
            }else {
            /// 2: start to download video file
               self?.downloadVideo(video: tuple.0, indexPath: tuple.1)
            }
            
        }).addDisposableTo(bag)
        
        ///dowload video info from webserver
        _ = downloadVideoInfo(from:0)
        
    }
    
    
    func showMessage(_ msg:String, title:String?, theme:Theme)  {
        let view = MessageView.viewFromNib(layout: .StatusLine)
        
        // Theme message elements with the warning style.
        view.configureTheme(theme)
        
        // Add a drop shadow.
        view.configureDropShadow()
        
        view.configureContent(title:title ?? " " , body: msg)
        
        // Show the message.
        SwiftMessages.show(view: view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func downloadVideo(video: Video, indexPath: IndexPath)  {
        
        let url = URL.init(string: video.mp4_url)!
        let urlRequest = try! URLRequest(url: url, method: .get)
        
        _ = self.manager?.rx.download(urlRequest, to: { (_, httpUrlRespones) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                let name = "vod/" + httpUrlRespones.suggestedFilename!
            
                let fileManager = FileManager.default
                let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = directoryURL.appendingPathComponent(name)
                
                return (fileURL, [.createIntermediateDirectories, .removePreviousFile])
            })
            .flatMap { $0.rx.progress() }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                [weak self] progress in
                print(" index:\(indexPath.row) :\(video.title) progress : \(progress.completed)")
                let cell = self?.tableView.cellForRow(at: indexPath) as? VideoInfoCell
                cell?.progressBar.progress = progress.completed
            }, onCompleted: {
                [weak self] in
                print("download completed")
                
                if let `self` = self {
                    self.videoArray.value[indexPath.row].setProgress(value: 1.0)
                    let item = self.videoArray.value[indexPath.row]
                    self.showMessage(item.title, title:"下载完成", theme: .success)
                    ///save Plist
                    Video.saveValuesToDefaults(newValues: self.videoArray.value, key: self.videoArrayKey)
                }
                
            }).addDisposableTo(bag)
    }
    
    private func playVideo(_ video:Video) {
        
            let array = video.mp4_url.components(separatedBy: "/")
            let name = array.last
            
            if let name = name  {
                let fileManager = FileManager.default
                let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = directoryURL.appendingPathComponent("/vod/" + name)
                
                print(fileURL)
                
                
                let videoURL = fileURL
                let player = AVPlayer(url: videoURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                DispatchQueue.main.async {
                    self.present(playerViewController, animated: true) {
                        playerViewController.player?.play()
                    }
                }
            }
    }
    

}


extension FirstViewController {
    
    func downloadVideoInfo(from index: Int = 0) {
            let urlString = "https://120.25.207.78/flashmobinfo"
            let param = ["index": index]
            _ = Alamofire.request(urlString, method: .post, parameters: param)
                .responseJSON { [weak self] (response) in
                    switch response.result {
                    case .success(let json):
                        let newArray = Video.generateModel(with:JSON(json))
                        if let `self` = self {
                            self.videoArray.value = self.mergeVideoArrays(originArray: self.videoArray.value, newArray: newArray)
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
       }
    
    ///合并&过滤掉重复的项
    func mergeVideoArrays(originArray:[Video], newArray:[Video]) -> [Video] {
        
        var total = originArray
        
        for new in newArray {
            var isExist = false
            for origin in originArray {
                if origin.index == new.index {
                    isExist = true
                    break
                }
            }
            
            if !isExist {
                total.append(new)
            }
        }
        
        
        return total.sorted { (lhs, rhs) -> Bool in
            lhs.index > rhs.index
        }
        
    }
    
    
    func testMergeVideoArrays(originArray:[Video], newArray:[Video]) -> [Video] {
        var total = originArray + newArray
       
//        total.map { $0.index != $1.index }
//        [originArray, newArray].map { }
        
//       Array
        return total
    }
    
}

