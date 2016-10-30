//
//  Location.swift
//  OurSky
//
//  Created by 王迺瑜 on 2016/10/30.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import Foundation
import CoreLocation

class Location {
    
    static let shared = Location()
    var latitude: AnyObject?
    var longitude: AnyObject?
    
    func getLocationString(location: CLLocation) {
        
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
        
    }
    
}