//
//  UserManager.swift
//  OurSky
//
//  Created by 王迺瑜 on 2016/10/24.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseAnalytics
import FBSDKLoginKit

class UserManager {
    
    static let shared = UserManager()
    
    let firebaseManager = FirebaseManager()
    
    private let fbLogInManager = FBSDKLoginManager()
    
    private let firebaseDatabase = FIRDatabase.database().reference()
    
    var currentUser: User?
    
    
    func restoreCurrentUser() {
        
        // firebase pop out user
        if let user = FIRAuth.auth()?.currentUser,
            userInfo = user.providerData.first {
            
            do {
                
                let currentUser = try User.parseUserInfo(user.uid, userInfo: userInfo)
                
                firebaseDatabase.child("users").child(user.uid).observeSingleEventOfType(
                    .Value,
                    withBlock: { (snapshot) in
                        
                        guard let value = snapshot.value as? [String: AnyObject] else {
                            
                            print("Can't get user's Information")
                            return
                            
                        }
                        
                        let phoneNumber = value["phone_number"] as? String ?? ""
                        
                        currentUser.phoneNumber = phoneNumber
                        
                   }
                )
                
                self.currentUser = currentUser
                
            } catch {
                
                print("parse user info failed")
                
            }
            
            return
            
        }
    }
}

extension UserManager {
    
    enum LogInFacebookError: ErrorType {
        case cancelled, missingUserInfo, unknown
    }
    
    typealias AlreadyLogInFacebook = (user: User) -> Void
    typealias DidNotLogInFacebook = (logStatus: String) -> Void
    
    func checkLogInStatus(fromViewController fromViewController: UIViewController, logIn: AlreadyLogInFacebook, logOut: DidNotLogInFacebook) {
        
        if let user = currentUser {
            
            logIn(user: user)
            
        } else {
            
            logOut(logStatus: "Not yet log in")
            
        }
    }
    
    typealias LogInWithFacebookSuccess = (user: User) -> Void
    typealias LogInWithFacebookFailure = (error: ErrorType) -> Void
    
    func logInWithFacebook(fromViewController fromViewController: UIViewController, success: LogInWithFacebookSuccess, failure: LogInWithFacebookFailure) {
        
        fbLogInManager.logInWithReadPermissions(
            [ "public_profile", "email", "user_friends" ],
            fromViewController: fromViewController,
            handler: { result, error in
                
                if let error = error {
                    
                    failure(error: error)
                    
                    return
                    
                }
                
                if result.isCancelled {
                    
                    failure(error: LogInFacebookError.cancelled)
                    
                    return
                    
                }
                
                let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
                FIRAuth.auth()?.signInWithCredential(credential) { user, error in
                    
                    if let error = error {
                        
                        failure(error: error)
                        
                        return
                        
                    }
                    
                    guard let user = user else {return}
                    
                    if let userInfo = user.providerData.first {
                        
                        do {
                            
                            let currentUser = try User.parseUserInfo(user.uid, userInfo: userInfo)
                            
                            let location = Location.shared
                            
                            currentUser.latitude = location.latitude
                            currentUser.longitude = location.longitude
                            
                            self.currentUser = currentUser
                            
                            let newUserJSON = currentUser.newUserJSON()
                            
                            self.firebaseDatabase.child("users").observeSingleEventOfType(.Value, withBlock:
                                { (snapshot) in
                                    
                                    guard let value = snapshot.value as? [String: AnyObject] else {return}
                                    
                                    for id in value.keys {
                                        
                                        if id == user.uid {
                                            
                                            self.firebaseDatabase.child("users").child(id).updateChildValues(newUserJSON)
                                            
                                            success(user: currentUser)
                                            
                                            return
                                            
                                        }
                                        
                                    }
                                }
                            )
                            
                            self.firebaseDatabase.child("users").child(currentUser.identifier).setValue(newUserJSON)
                            self.firebaseDatabase.child("name_list").child(currentUser.name).setValue(currentUser.identifier)
                            FIRAnalytics.logEventWithName(kFIREventLogin, parameters: ["ID": currentUser.identifier, "name": currentUser.name])
                            
                            success(user: currentUser)
                            
                        }
                        catch {
                            
                            failure(error: LogInFacebookError.missingUserInfo)
                            
                        }
                        
                    } else {
                        
                        failure(error: LogInFacebookError.unknown)
                        
                    }
                }
                
            }
        )
        
    }
    
    typealias LogOutWithFacebookSuccess = (didLogOut: String) -> Void
    typealias LogOutWithFacebookFailure = (error: String) -> Void
    
    func logOutWithFacebook(fromViewController fromViewController: UIViewController, success: LogOutWithFacebookSuccess, failure: LogOutWithFacebookFailure) {
        
        fbLogInManager.logOut()
        do {
            
            try FIRAuth.auth()?.signOut()
            currentUser = nil
            success(didLogOut: "Log out")
            
        } catch {
            
            failure(error: "Unknown")
            
        }
    }
    
    func updateUserInfo(userId: String, withNewUser newUser: User) {
        
        let newUserJSON = newUser.newUserJSON()
        
        firebaseDatabase.child("users").child(userId).updateChildValues(newUserJSON)
        
    }
    
}
