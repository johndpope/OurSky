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
    
    @IBOutlet weak var typeField: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func save(sender: AnyObject) {
        
        if let user = currentUser {
            
            user.phoneNumber = typeField.text
            UserManager.shared.updateUserInfo(user.identifier, withNewUser: user)
            
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        typeField.delegate = self
        
        guard let user = currentUser else {return}
        
        if let phoneNumber = user.phoneNumber {
            
            typeField.text = phoneNumber
            
        }
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
    
}
