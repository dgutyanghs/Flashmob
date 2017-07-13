//
//  SecondViewController.swift
//  Flashmob
//
//  Created by  BlueYang on 2017/6/27.
//  Copyright © 2017年  BlueYang. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import SwiftyJSON

class SecondViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!

    let bag = DisposeBag()
    var  version:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.green], for: .selected)
//        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.green], for: .normal)
        // Do any additional setup after loading the view, typically from a nib.
        title = "关于"
        let cellID = "aboutMeCell"
       let aboutInfo = Observable.of([("版本", "version:1.0.0"),("作者","Alex Yang"),("E-mail", "yanghs.dgut@gmail.com"),("博客","https://dgutyanghs.github.io/")])
        aboutInfo.bind(to: tableView.rx.items(cellIdentifier: cellID, cellType: UITableViewCell.self )) {
            _, item, cell  in
            cell.textLabel?.text = item.0
            cell.detailTextLabel?.text = item.1
        }.addDisposableTo(bag)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func downloadSoftwareInfo() {
            let urlString = "https://120.25.207.78/swinfo"
            _ = Alamofire.request(urlString, method: .post)
                .responseJSON { [weak self] (response) in
                    switch response.result {
                    case .success(let json):
//                        let info = JSON(json)
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
       }


}

