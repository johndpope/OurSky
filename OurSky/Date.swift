//
//  Date.swift
//  OurSky
//
//  Created by 王迺瑜 on 2016/11/2.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import Foundation
import DateTools

//MARK: Transfer Date
class TransferDate {
    
    var dateInString: String = ""
    let dateFormatter = NSDateFormatter()
    
    func transferToString(date: NSDate) {
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateInString = self.dateFormatter.stringFromDate(date)
        
    }
    
    func calculateOnlineStatus(date: String) -> String {
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let friendDate = self.dateFormatter.dateFromString(date) else {return ""}
        
        return friendDate.timeAgoSinceNow()
        
    }
}
