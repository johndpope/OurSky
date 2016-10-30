//
//  FirebaseManager.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/11.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import Foundation
import Firebase
import FBSDKLoginKit

//MARK: Users Protocol
protocol FirebaseGlobeDelegate: class {
    
    func getFriendData(manager: FirebaseManager, didGetData: [[String:AnyObject]])
    
    func getFriendData(manager: FirebaseManager, getDataFail: String)
    
}

//MARK: Search VC Protocol
protocol FirebaseNameListDelegate: class {
    
    func getNameListData(manager: FirebaseManager, didGetData: [[String:String]])
    
    func sendFriendRequest(manager: FirebaseManager, sendRequest: String)
    
}

//MARK: Notification VC Protocol
protocol FirebaseNotifiDelegate: class {
    
    func getNotification(manager: FirebaseManager, didGetData: [String : [String:String]])
    
    func acceptRequest(manager: FirebaseManager, acceptCell: String, accept: String)
    
    func declineRequest(manager: FirebaseManager , declineCell: String, decline: String)
    
}

//MARK: Transfer Date
class TransferDate {
    
    var dateInString: String = ""
    let dataFormatter = NSDateFormatter()
    
    func transferToString(date: NSDate) {
        
        self.dataFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateInString = self.dataFormatter.stringFromDate(date)
        
    }
    
    func calculateOnlineStatus(date: String) -> String {
                
        let calendar = NSCalendar.currentCalendar()
            
            let currentDate = NSDate()
            self.dataFormatter.dateFormat = "yyyy-MM-dd HH:mm"

            guard let friendDate = self.dataFormatter.dateFromString(date) else {return ""}
        
            if calendar.component(.Year, fromDate: currentDate) - calendar.component(.Year, fromDate: friendDate) == 0 {
                
                if calendar.component(.Month, fromDate: currentDate) - calendar.component(.Month, fromDate: friendDate) == 0 {
                    
                    if calendar.component(.Day, fromDate: currentDate) - calendar.component(.Day, fromDate: friendDate) == 0 {
                        
                        if calendar.component(.Hour, fromDate: currentDate) - calendar.component(.Hour, fromDate: friendDate) == 0 {
                            
                            if calendar.component(.Minute, fromDate: currentDate) - calendar.component(.Minute, fromDate: friendDate) == 0 {
                                
                                return "Online"
                                
                            } else {
                                
                                return "\(calendar.component(.Minute, fromDate: currentDate) - calendar.component(.Minute, fromDate: friendDate)) minutes ago"
                                
                            }} else {
                            
                            return "\(calendar.component(.Hour, fromDate: currentDate) - calendar.component(.Hour, fromDate: friendDate)) hours ago"
                            
                        }} else {
                        
                        return "\(calendar.component(.Day, fromDate: currentDate) - calendar.component(.Day, fromDate: friendDate)) days ago"
                        
                    }} else {
                    
                    return "\(calendar.component(.Month, fromDate: currentDate) - calendar.component(.Month, fromDate: friendDate)) months ago"
                    
                }} else {
                
                return "\(calendar.component(.Year, fromDate: currentDate) - calendar.component(.Year, fromDate: friendDate)) year ago"
                
            }
            
        }
}


//MARK: Firebase Model
class FirebaseManager {
    enum GetFriendDataError: ErrorType {
        case noLogIn, doNotHaveFriends, cancelled, unknown
    }
    
    let loginManager = FBSDKLoginManager()
    let databaseRef = FIRDatabase.database().reference()
    weak var firebaseNameListDelegate: FirebaseNameListDelegate?
    weak var firebaseNotifiDelegate: FirebaseNotifiDelegate?
    var currentUser = FIRAuth.auth()?.currentUser
    let userDefault = NSUserDefaults.standardUserDefaults()
    
    //MARK: Friend Data
    typealias DidGetFriendData = (friendData: [[String:AnyObject]]) -> Void
    typealias DidNotGetData = (status: ErrorType) -> Void
    func loadFriendData(success: DidGetFriendData, failure: DidNotGetData) {
        
        guard let user = currentUser else {
            
            failure(status: GetFriendDataError.noLogIn)
            return
        
        }
        
        var friendIds: [String] = []
        var friendInfo: [String:AnyObject] = [:]
        var friendStatus: [[String:AnyObject]] = []
        
        //Read friend list, get id
        
        databaseRef.child("friend_list").child(user.uid).observeSingleEventOfType(.Value, withBlock:
            { (snapshot) in
                
                // Get user value
                guard let value = snapshot.value as? [String:AnyObject] else {
                    
                    failure(status: GetFriendDataError.doNotHaveFriends)
                    return
                }
                
                for friendId in value {
                    
                    friendIds.append(friendId.0)
                    
                }
                
                //----------------------
                
                for id in friendIds {
                    self.databaseRef.child("users").child(id).observeSingleEventOfType(
                        .Value,
                        withBlock: { (snapshot) in
                            
                            guard let value = snapshot.value as? [String: AnyObject] else {return}
                            
                            friendInfo["name"] = value["name"]
                            friendInfo["online"] = value["online"]
                            friendInfo["latitude"] = value["location"]!["latitude"]
                            friendInfo["longitude"] = value["location"]!["longitude"]
                            friendInfo["phoneNumber"] = value["phone_number"]
                            friendInfo["profilePic"] = value["profile_pic"]
                            
                            friendStatus.append(friendInfo)
                            
                            dispatch_async(dispatch_get_main_queue(), {
                                                                
                                success(friendData: friendStatus)
                                
                                FIRAnalytics.logEventWithName("Number_of_friends", parameters: ["user_id": user.uid, "number_of_friends": friendIds.count])
                            })
                            
                        },
                        withCancelBlock: { (error) in
                          failure(status: GetFriendDataError.cancelled)
                        }
                    )
                    
                }
                
                
        }) { (error) in
            
            failure(status: GetFriendDataError.unknown)
            
        }
        
    }
    
    func loadNameList() {
        
        guard let user = currentUser else {return}
        var appUsers: [[String:String]] = []
        var friendStatus: [String : [String]] = [:]
        
        //Search data once
        databaseRef.child("friend_request").observeSingleEventOfType(.Value, withBlock:
            { (snapshot) in
                
                // Get user value
                guard let requestInfo = snapshot.value as? [String:AnyObject] else {return}
                guard let userName = user.displayName else {return}
                for info in requestInfo {
                    
                    let requestId = info.0
                    
                    guard
                        var requestObject = info.1["request_object"] as? [String:String],
                        var requestUser = info.1["request_user"] as? [String:String],
                        let requestStatus = info.1["request_status"] as? String
                        else {return}
                    
                    if requestObject["user_id"] == user.uid {
                        
                        var requestFriendInfo: [String] = []
                        requestFriendInfo.append(requestId)
                        requestFriendInfo.append(requestStatus)
                        friendStatus[requestUser["name"]!] = requestFriendInfo
                        
                    } else if requestUser["user_id"] == user.uid {
                        
                        var requestFriendInfo: [String] = []
                        requestFriendInfo.append(requestId)
                        requestFriendInfo.append(requestStatus)
                        friendStatus[requestObject["name"]!] = requestFriendInfo
                        
                    }
                }
                
                var requestFriendInfo: [String] = []
                requestFriendInfo.append("i'm user")
                requestFriendInfo.append("true")
                friendStatus[userName] = requestFriendInfo
                
        })
        
        //Search data once
        databaseRef.child("name_list").observeSingleEventOfType(.Value, withBlock:
            { (snapshot) in
                
                // Get user value
                let value = snapshot.value
                let nameList = value as! [String:String]
                
                for name in nameList {
                    
                    var userInfo: [String:String] = [:]
                    
                    for friend in friendStatus {
                        
                        
                        if name.0 == friend.0 {
                            
                            userInfo["request_id"] = friend.1[0]
                            userInfo["name"] = name.0
                            userInfo["user_id"] = name.1
                            userInfo["request_status"] = friend.1[1]
                            
                            break
                            
                        } else {
                            
                            userInfo["request_id"] = "don't have id."
                            userInfo["name"] = name.0
                            userInfo["user_id"] = name.1
                            userInfo["request_status"] = "false"
                            
                        }
                    }
                    
                    appUsers.append(userInfo)
                    
                }
                
                self.firebaseNameListDelegate?.getNameListData(self, didGetData: appUsers)
                
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }
    
    func sendFriendRequest(requestId: String, filteredNames: [String:String]) {
        
        //!!! Need to know the indexPath !!!//
        
        if let user = currentUser {
            
            for profile in user.providerData {
                
                let uuid = NSUUID().UUIDString
                let userName = profile.displayName
                let transferDate = TransferDate()
                transferDate.transferToString(NSDate())
                let names = filteredNames.map { return $0 }
                
                let requestInfo: [String:AnyObject] = ["request_user": ["name":userName!, "user_id":user.uid], "request_object": ["name":names[0].0, "user_id": names[0].1], "request_date": transferDate.dateInString, "request_status": "unknown"]
                
                if requestId == "don't have id." {
                    
                    databaseRef.child("friend_request").child(uuid).setValue(requestInfo)
                    
                } else {
                    
                    databaseRef.child("friend_request").child(requestId).setValue(requestInfo)
                    
                }
                
            }
        }
        
        firebaseNameListDelegate?.sendFriendRequest(self, sendRequest: "send friend request")
        
    }
    
    func getNotification() {
        
        guard let user = currentUser else {return}
        var requestEvents: [String : [String:String]] = [:]
        
        //Search data once
        databaseRef.child("friend_request").observeSingleEventOfType(.Value, withBlock:
            { (snapshot) in
                
                // Get user value
                guard let requestInfo = snapshot.value as? [String:AnyObject] else {return}
                for info in requestInfo {
                    
                    let requestId: String = info.0
                    guard
                        var requestObject = info.1["request_object"] as? [String:String],
                        var requestUser = info.1["request_user"] as? [String:String],
                        let requestDate = info.1["request_date"] as? String,
                        let requestStatus = info.1["request_status"] as? String
                        else {return}
                    if requestObject["user_id"] == user.uid && requestStatus == "unknown"
                        
                    {
                        
                        requestEvents[requestUser["name"]!] = ["event":"wants to add you as friend.", "date": requestDate, "userId": requestUser["user_id"]!, "requestId": requestId]
                        
                    }
                }
                
                self.firebaseNotifiDelegate?.getNotification(self, didGetData: requestEvents)
                
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func acceptRequest(acceptCell: Int, requestEvents: [String: [String:String]]) {
        
        
        //!!!Need to know indexPath!!!//
        guard let user = currentUser else {return}
        let names = requestEvents.map { return $0 }
        let transferDate = TransferDate()
        transferDate.transferToString(NSDate())
        let acceptUser: [String:String] = ["name":names[acceptCell].0, "acceptDate":transferDate.dateInString]
        let acceptObject: [String:String] = ["name":(user.displayName)!, "acceptDate":transferDate.dateInString]
        
        //Add friend info into friend_list
        databaseRef.child("friend_list").child(user.uid).child(names[acceptCell].1["userId"]!).setValue(acceptUser)
        databaseRef.child("friend_list").child(names[acceptCell].1["userId"]!).child(user.uid).setValue(acceptObject)
        databaseRef.updateChildValues(["/friend_request/\(names[acceptCell].1["requestId"]!)/request_status" : "true"])
        
        
        firebaseNotifiDelegate?.acceptRequest(self, acceptCell: names[acceptCell].0, accept: "accept to be friend.")
        FIRAnalytics.logEventWithName("Be_friend", parameters: nil)
        
    }
    
    func declineRequest(declineCell: Int, requestEvents: [String: [String:String]]) {
        
        let names = requestEvents.map { return $0 }
        databaseRef.updateChildValues(["/friend_request/\(names[declineCell].1["requestId"]!)/request_status" : "false"])
        
        firebaseNotifiDelegate?.declineRequest(self, declineCell: names[declineCell].0, decline: "decline to be friend.")
        
    }
    
    //MARK: Trying Sky Map Function
    //try looking at position
    func lookingAt() -> [String:Float] {
        
        var lookingDirection: [String : Float] = [:]
        
        //Search data once
        databaseRef.child("direction").observeEventType(.Value, withBlock:
            { (snapshot) in
                
                let directionInfo = snapshot.value as! [String : AnyObject]
                let attitudeD = directionInfo["attitude"] as? Double ?? 0.0
                let headingD = directionInfo["heading"] as? Double ?? 0.0
                
                let attitude = Float(attitudeD)
                let heading = Float(headingD)
                
                lookingDirection["attitude"] = attitude
                lookingDirection["heading"] = heading
                
        })
        
        return lookingDirection
        
    }
}
