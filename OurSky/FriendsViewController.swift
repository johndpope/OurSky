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
    var pullToRefreshControl: UIRefreshControl!

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
        
        pullToRefresh()
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
        
        friendCell.layer.cornerRadius = 15
        friendCell.layer.borderColor = UIColor(red: 26/255, green: 15/255, blue: 34/255, alpha: 1).CGColor
        friendCell.layer.borderWidth = 2
        
        let transferDate = TransferDate()
        let friendTime = friendStatus[indexPath.row]["online"] as? String ?? ""
        let friendOnline = transferDate.calculateOnlineStatus(friendTime)
        
        if friendStatus[indexPath.row]["phoneNumber"] == nil {
            
            friendCell.facetimeCall.hidden = true
            
        } else {
            
            friendCell.facetimeCall.hidden = false
        }
        
        if friendStatus[indexPath.row]["latitude"] == nil {
            
            friendCell.optionButton.hidden = true
            
        } else {
            
            friendCell.optionButton.hidden = false
            
        }
        
        friendCell.tag = indexPath.row
        friendCell.friendID.text = friendStatus[indexPath.row]["name"] as? String ?? ""
        friendCell.friendStatus.text = friendOnline
        friendCell.optionButton.layer.cornerRadius = friendCell.optionButton.bounds.width/2
        friendCell.optionButton.clipsToBounds = true
        friendCell.facetimeCall.addTarget(self, action: #selector(facetime(_:)), forControlEvents: .TouchUpInside)
        friendCell.facetimeCall.layer.cornerRadius = friendCell.facetimeCall.bounds.width/2
        friendCell.facetimeCall.clipsToBounds = true
        
        friendCell.friendProfilePic.layer.cornerRadius = friendCell.friendProfilePic.bounds.width/2
        friendCell.friendProfilePic.clipsToBounds = true
        
        if let friendProfilePicString = friendStatus[indexPath.row]["profilePic"] as? String,
            friendProfilePicURL = NSURL(string: friendProfilePicString),
            friendProfilePicData = NSData(contentsOfURL: friendProfilePicURL) {
            
            friendCell.friendProfilePic.image = UIImage(data: friendProfilePicData)
            
        }
        
        return friendCell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if let identifier = segue.identifier {
            
            if identifier == "showFriendLocation" {
                
                guard let destVC = segue.destinationViewController as? GlobeViewController else {return}
                guard let senderButton: UIButton = sender as? UIButton,
                    senderSuperView = senderButton.superview,
                    senderCell = senderSuperView.superview as? UITableViewCell,
                    tableViewCellIndexPath = tableView.indexPathForCell(senderCell)
                    else {
                        
                        print("Get friend's location error")
                        return
                        
                }
                
                let currentFriend = friendStatus[tableViewCellIndexPath.row]
                destVC.friendStatus.append(currentFriend)
                destVC.fromSpecificFriend = true
                FIRAnalytics.logEventWithName("Watch_friend_location", parameters: nil)
                
            }
            
            if identifier == "showLookingAt" {
                
                //                guard let destVC = segue.destinationViewController as? SkyMapViewController else {return}
                
            }
            
        }
    }
    
    func facetime(sender: UIButton) {
        
        guard let senderSuperView = sender.superview,
            senderCell = senderSuperView.superview as? UITableViewCell,
            tableViewCellIndexPath = tableView.indexPathForCell(senderCell),
            phoneNumber = friendStatus[tableViewCellIndexPath.row]["phoneNumber"]
            else {
                
                print("Facetime audio with friend error.")
                return
                
        }
        
        if let facetimeURL:NSURL = NSURL(string: "facetime-audio://\(phoneNumber)") {
            
            let application:UIApplication = UIApplication.sharedApplication()
            if (application.canOpenURL(facetimeURL)) {
                
                application.openURL(facetimeURL)
                
            }
        }
    }
    
    func pullToRefresh() {
        
        pullToRefreshControl = UIRefreshControl()
        
        pullToRefreshControl.addTarget(self, action: #selector(FriendsViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        // Setup UI
        
        pullToRefreshControl.tintColor = UIColor(red: 182/255, green: 212/255, blue: 242/255, alpha: 1)
        
//        let attributes = [NSForegroundColorAttributeName: UIColor(red: 182/255, green: 212/255, blue: 242/255, alpha: 1), NSFontAttributeName : UIFont(name: "CourierNewPSMT", size: 20)!]
        
//        let attributedTitle = NSAttributedString(string: "pull to refresh", attributes: attributes)
        
//        pullToRefreshControl.attributedTitle = attributedTitle
        
        tableView.addSubview(pullToRefreshControl)
    }
    
    func refresh(sender:AnyObject) {

        firebaseManager.loadFriendData (
            {(friendData: [[String:AnyObject]]) -> Void in
                
                self.friendStatus = friendData
                self.tableView.reloadData()
                print("Get friend list")
                
                self.pullToRefreshControl.endRefreshing()

            },
            failure: { (status: ErrorType) -> Void in
                
                print(status)
                
            }
        )
     }
    
}
