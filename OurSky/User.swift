//
//  User.swift
//  OurSky
//
//  Created by 王迺瑜 on 2016/10/24.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import FirebaseAuth

class User {
    
    let identifier: String
    let name: String
    let email: String
    let profilePic : String
    var onlineDate = NSDate()
    var latitude: AnyObject?
    var longitude: AnyObject?
    var phoneNumber: String?
    
    init(identifier: String, name: String, email: String, profilePic: String) {
        
        self.identifier = identifier
        self.name = name
        self.email = email
        self.profilePic = profilePic
        
    }
    
}

extension User {
    
    enum ParseUserInfoError: ErrorType {
        case missingName, missingEmail, missingProfilePic
    }
    
    class func parseUserInfo(identifier: String, userInfo: FIRUserInfo) throws -> User {
        
        guard
            let name = userInfo.displayName
            else {
                
                throw ParseUserInfoError.missingName
                
        }
        
        guard
            let email = userInfo.email
            else {
                
                throw ParseUserInfoError.missingEmail
                
        }
        
        guard
            let profilePic = userInfo.photoURL
            else {
                
                throw ParseUserInfoError.missingProfilePic
                
        }
        
        return User(
            identifier: identifier,
            name: name,
            email: email,
            profilePic: profilePic.absoluteString
        )
        
    }
    
    func newUserJSON() -> [String: AnyObject] {
        
        let dataFormatter = NSDateFormatter()
        dataFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let onlineDateString = dataFormatter.stringFromDate(onlineDate)
        
        var newUser: [String:AnyObject] = [
            
            "name": name,
            "email": email,
            "profile_pic": profilePic,
            "online": onlineDateString
            
        ]
        
        if let latitude = latitude,
            longitude = longitude {
            
            newUser["location"] = [
                
                "latitude": latitude,
                "longitude": longitude
                
            ]
            
        }
        
        if let phoneNumber = phoneNumber {
            
            newUser["phone_number"] = phoneNumber
            
        }
        
        return newUser
        
    }
    
}
