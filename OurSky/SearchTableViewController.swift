//
//  SearchTableViewController.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/8.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController, FirebaseNameListDelegate {
    
    let firebaseManager = FirebaseManager()
    let searchController = UISearchController(searchResultsController: nil)
    var names: [[String:String]] = []
    var filteredNames: [[String:String]] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Set search bar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        firebaseManager.firebaseNameListDelegate = self
        firebaseManager.loadNameList()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(named: "image1"), forBarMetrics: UIBarMetrics.Default)

    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All")
    {
        filteredNames = []
        
        var allNames: [String] = []
        
        for allName in names {
            allNames.append(allName["name"]!)
        }
        
        let results = allNames.filter { name in return name.lowercaseString.containsString(searchText.lowercaseString) }
        
        for result in results {
            
            for allName in names {
                
                if result == allName["name"]! {
                    
                    filteredNames.append(allName)
                    
                }
            }
            
        }
        
        self.tableView.reloadData()
    }
    
    //Set table view
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredNames.count
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let identifier = "searchCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as! SearchTableViewCell
//                let names = filteredNames.map { return $0 }
//                let name = names[indexPath.row]
        
        cell.name.text = filteredNames[indexPath.row]["name"]
        cell.addFriend.addTarget(self, action: #selector(SearchTableViewController.friendRequest(_:)), forControlEvents: .TouchUpInside)
        cell.addFriend.tag = indexPath.row
        
        switch filteredNames[indexPath.row]["request_status"]! {
            
        case "true": cell.addFriend.setImage(UIImage(named: "profile"), forState: .Normal)
        case "unknown": cell.addFriend.setImage(UIImage(named: "waiting"), forState: .Normal)
        case "false": cell.addFriend.setImage(UIImage(named: "addfriend"), forState: .Normal)
            
        default: break
            
        }
        
        return cell
        
    }
    
    //Send a friend request
    func friendRequest(sender: UIButton) {
        
        let currentSender = sender.tag
        
        //still don't know the indexPath of this button.
        
        switch filteredNames[currentSender]["request_status"]! {
            
        case "true": print("already been friend")
        case "unknown": print("still waiting for answer")
        case "false":
            guard let requestId : String = filteredNames[currentSender]["request_id"] else {return}
            var sendFriend: [String:String] = [:]
            sendFriend[filteredNames[currentSender]["name"]!] = filteredNames[currentSender]["user_id"]!
            firebaseManager.sendFriendRequest(requestId, filteredNames: sendFriend)
            sender.setImage(UIImage(named: "waiting"), forState: .Normal)
            
        default: break
            
        }
    }
    
    func getNameListData(manager: FirebaseManager, didGetData: [[String:String]]) {
        
        names = didGetData
        
    }
    
    func sendFriendRequest(manager: FirebaseManager, sendRequest: String) {
        
        print(sendRequest)
        
    }
}

extension SearchTableViewController: UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
