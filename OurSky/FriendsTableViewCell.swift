//
//  FriendsTableViewCell.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/6.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit

class FriendsTableViewCell: UITableViewCell {
    @IBOutlet weak var friendProfilePic: UIImageView!

    @IBOutlet weak var friendID: UILabel!
    
    @IBOutlet weak var friendStatus: UILabel!
    
    @IBOutlet weak var optionButton: UIButton!
    
    @IBOutlet weak var facetimeCall: UIButton!
    
    @IBAction func facetimeCall(sender: AnyObject) {
        
        facetime("85294518648")
        
    }
    
    private func facetime(phoneNumber:String) {
        if let facetimeURL:NSURL = NSURL(string: "facetime-audio://\(phoneNumber)") {
            let application:UIApplication = UIApplication.sharedApplication()
            if (application.canOpenURL(facetimeURL)) {
                
                application.openURL(facetimeURL)
                
            }
        }
    }
    
}
