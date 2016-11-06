//
//  PhoneNumberViewController.swift
//  OurSky
//
//  Created by 王迺瑜 on 2016/10/30.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit

class PhoneNumberViewController: UIViewController, UITextFieldDelegate {
    
    let currentUser = UserManager.shared.currentUser
    
    @IBOutlet weak var errorMessage: UILabel!
    
    @IBOutlet weak var typeField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func save(sender: AnyObject) {
        
        guard typeField.text?.characters.count < 14 else {
            
            errorMessage.text = "out of range"
            return

        }
  
        if let user = currentUser {
            
            user.phoneNumber = typeField.text
            UserManager.shared.updateUserInfo(user.identifier, withNewUser: user)
            
        }
        
        self.typeField.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: {() -> Void in
            
            print("Save phone number")
            
        })
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        typeField.delegate = self
        
        guard let user = currentUser else {return}
        
        if let phoneNumber = user.phoneNumber {
            
            typeField.text = phoneNumber
            
        }
        
    }
}

class CustomUITextField: UITextField {
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        
        if action == "paste:" {
            
            return false
            
        }
        
        return super.canPerformAction(action, withSender: sender)
    
    }
}