//
//  FriendsViewController
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/6.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class FriendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var logButton: UIBarButtonItem!
    
    @IBOutlet weak var phoneNumberButton: UIBarButtonItem!
    
    
    var friendStatus: [[String:AnyObject]] = []
    let userDefault = NSUserDefaults.standardUserDefaults()
    let firebaseManager = FirebaseManager()
    let userManager = UserManager.shared
    
    
    //login both facebook and firebase
    @IBAction func login(sender: UIBarButtonItem) {
        
        guard sender == logButton else {return}
        userManager.checkLogInStatus(
            fromViewController: self,
            logIn: { (user: User) -> Void in
                
                self.userManager.logOutWithFacebook(
                    fromViewController: self,
                    success: { (didLogOut: String) -> Void in
                        
                        self.logButton.title = "Log in"
                        self.navigationItem.title = "Profile"
                        self.friendStatus.removeAll()
                        self.tableView.reloadData()
                        
                    },
                    failure: { (error: String) -> Void in
                        
                        print(error)
                        
                    }
                )
            },
            
            logOut: { (logStatus: String) -> Void in
                
                self.userManager.logInWithFacebook(
                    fromViewController: self,
                    success: { (user: User) -> Void in
                        
                        self.logButton.title = "Log out"
                        self.navigationItem.title = user.name
                        
                        self.firebaseManager.loadFriendData (
                            {(friendData: [[String:AnyObject]]) -> Void in
                            
                            self.friendStatus = friendData
                            self.tableView.reloadData()
                            print("Get friend list")
                            
                            },
                            failure: { (status: ErrorType) -> Void in
                                
                                print(status)
                                
                            }
                        )
                    },
                    failure: { (error: ErrorType) -> Void in
                        
                        print(error)
                        
                    }
                )
            }
        )
        
    }
    
    @IBAction func phoneNumber(sender: UIBarButtonItem) {
        
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Main",
            bundle: nil)
        let phoneNumberVC: PhoneNumberViewController = storyboard.instantiateViewControllerWithIdentifier("PhoneNumberViewController") as! PhoneNumberViewController
        phoneNumberVC.preferredContentSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: 100)
        
        phoneNumberVC.modalPresentationStyle = UIModalPresentationStyle.Popover
        
        let popOverVC = phoneNumberVC.popoverPresentationController
        popOverVC?.barButtonItem = phoneNumberButton
        popOverVC?.delegate = self
        self.presentViewController(phoneNumberVC, animated: true, completion: nil)
        
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        return .None
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userManager.checkLogInStatus(
            fromViewController: self,
            logIn: { (user: User) -> Void in
                
                self.navigationItem.title = user.name
                self.logButton.title = "Log out"
                print("already log in")
                
            },
            
            logOut: { (logStatus: String) -> Void in
                
                self.logButton.title = "Log in"
                
            }
        )
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "image1"), forBarMetrics: UIBarMetrics.Default)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        firebaseManager.loadFriendData (
            {(friendData: [[String:AnyObject]]) -> Void in
            
            self.friendStatus = friendData
            self.tableView.reloadData()
            print("Get friend list")
            
            },
            failure: { (status: ErrorType) -> Void in
                                            
            print(status)
                                            
            }
        )
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return friendStatus.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let friendCellIdentifier = "FriendsTableViewCell"
        let friendCell = tableView.dequeueReusableCellWithIdentifier(friendCellIdentifier, forIndexPath: indexPath) as! FriendsTableViewCell
        let transferDate = TransferDate()
        let friendTime = friendStatus[indexPath.row]["online"] as? String ?? ""
        let friendOnline = transferDate.calculateOnlineStatus(friendTime)
        
        if let friendProfilePicURL = friendStatus[indexPath.row]["profilePic"] as? NSURL,
            friendProfilePicData = NSData(contentsOfURL: friendProfilePicURL) {
            
            friendCell.friendProfilePic.image = UIImage(data: friendProfilePicData)
            
        }
        
        friendCell.friendID.text = friendStatus[indexPath.row]["name"] as? String ?? ""
        friendCell.friendStatus.text = friendOnline
        friendCell.optionButton.layer.cornerRadius = friendCell.optionButton.bounds.width/2
        friendCell.optionButton.clipsToBounds = true
        friendCell.facetimeCall.layer.cornerRadius = friendCell.optionButton.bounds.width/2
        friendCell.facetimeCall.clipsToBounds = true
        
        
        return friendCell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if let identifier = segue.identifier {
            
            if identifier == "showFriendLocation" {
                
                guard let destVC = segue.destinationViewController as? GlobeViewController else {return}
                guard let currentFriendLocation = sender?.tag else {return}
                let currentFriend = friendStatus[currentFriendLocation]
                destVC.friendStatus.append(currentFriend)
                destVC.fromSpecificFriend = true
                FIRAnalytics.logEventWithName("Watch_friend_location", parameters: nil)
                
            }
            
            if identifier == "showLookingAt" {
                
                //                guard let destVC = segue.destinationViewController as? SkyMapViewController else {return}
                
            }
            
        }
    }
}

