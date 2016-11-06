//
//  NotifiTableViewController.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/8.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit

class NotifiTableViewController: UITableViewController, FirebaseNotifiDelegate {
    
    let firebaseManager = FirebaseManager()
    var requestEvents: [String : [String:String]] = [:]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        firebaseManager.firebaseNotifiDelegate = self
        firebaseManager.getNotification()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "image1"), forBarMetrics: UIBarMetrics.Default)

    }
    
    //Set table view
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return requestEvents.count
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let identifier = "notifiCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! NotifiTableViewCell
        let names = requestEvents.map { return $0 }
        
        cell.notifiName.text = names[indexPath.row].0
        cell.notifiEvent.text = names[indexPath.row].1["event"]
        cell.acceptButton.tag = indexPath.row
        cell.acceptButton.addTarget(self, action: #selector(NotifiTableViewController.accept(_:)), forControlEvents: .TouchUpInside)
        cell.declineButton.addTarget(self, action: #selector(NotifiTableViewController.decline(_:)), forControlEvents: .TouchUpInside)
        
        return cell
    }

    func accept(sender: UIButton) {

        guard let senderSuperView = sender.superview,
            senderCell = senderSuperView.superview as? UITableViewCell,
            tableViewCellIndexPath = tableView.indexPathForCell(senderCell)
            else {
                
                print("Accept friend request error")
                return
                
        }
        
        
        firebaseManager.acceptRequest(tableViewCellIndexPath.row, requestEvents: requestEvents)

    }
    
    func decline(sender: UIButton) {
        
        guard let senderSuperView = sender.superview,
            senderCell = senderSuperView.superview as? UITableViewCell,
            tableViewCellIndexPath = tableView.indexPathForCell(senderCell)
            else {
                
                print("Accept friend request error")
                return
                
        }
        
        firebaseManager.declineRequest(tableViewCellIndexPath.row, requestEvents: requestEvents)
        
    }
    
    func getNotification(manager: FirebaseManager, didGetData: [String : [String:String]]) {
        
        requestEvents = didGetData
        self.tableView.reloadData()
        
    }

    func acceptRequest(manager: FirebaseManager, acceptCell: String, accept: String) {
        
        requestEvents.removeValueForKey(acceptCell)
        self.tableView.reloadData()
        print(accept)
        
    }

    func declineRequest(manager: FirebaseManager , declineCell: String, decline: String) {
        
        requestEvents.removeValueForKey(declineCell)
        self.tableView.reloadData()
        print(decline)
        
    }
    
}
