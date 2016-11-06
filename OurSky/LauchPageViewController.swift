//
//  LauchPageViewController.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/7.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import CoreLocation
import Crashlytics

class LauchPageViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    let online = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAnalytics.logEventWithName(kFIREventAppOpen, parameters: nil)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        locationManager.stopUpdatingLocation()
        
        guard let location = locations.last else { return }
        
        Location.shared.getLocationString(location)
        
        if let currentUser = UserManager.shared.currentUser {
            
            currentUser.onlineDate = NSDate()
            currentUser.latitude = location.coordinate.latitude
            currentUser.longitude = location.coordinate.longitude
            
            UserManager.shared.updateUserInfo(currentUser.identifier, withNewUser: currentUser)
            
        }
        
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("myPerformeCode:"), userInfo: nil, repeats: false)
        
    }
    
    func myPerformeCode(timer : NSTimer) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let skyMapController = storyboard.instantiateViewControllerWithIdentifier("SkyMapViewController")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = skyMapController
        
    }
    
}
