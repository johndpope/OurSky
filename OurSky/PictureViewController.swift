//
//  PictureViewController.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/6.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit
import Alamofire
import FirebaseAnalytics

class PictureViewController: UIViewController {
    
    @IBOutlet weak var nasaTitle: UILabel!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var nasaImage: UIImageView!
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    func getData() {
        
        guard let nasaApi = NSURL(string: "https://api.nasa.gov/planetary/apod?api_key=HDxtBrRqmL4MabwE8LHFtKopz3gI9mlXJU1zeGm4")else {return}
        
        Alamofire.request(.GET, nasaApi)
            .responseJSON { response in
                guard let data = response.result.value else {return}
                
                let title: String = data["title"] as? String ?? ""
                let date: String = data["date"] as? String ?? ""
                
                guard
                    let imageUrlStr: String = data["url"] as? String,
                    let imageData = NSData(contentsOfURL: NSURL(string: imageUrlStr)!),
                    let image = UIImage(data: imageData)
                    else {return}
                
                self.nasaTitle.text = title
                self.date.text = date
                self.nasaImage.image = image
                
                print("Get APOD data")
                
                self.loading.stopAnimating()
                FIRAnalytics.logEventWithName("watch_APOD", parameters: nil)
                
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nasaTitle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        nasaTitle.numberOfLines = 0
        
        loading.startAnimating()
        
        getData()
        
    }
    
}