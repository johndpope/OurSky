//
//  EarthViewController.swift
//  MainProject2
//
//  Created by 王迺瑜 on 2016/10/2.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit
import SceneKit

class EarthViewController: UIViewController {
    @IBOutlet weak var sceneKitView: SCNView!
    
    let scene = SCNScene()
    let node = SCNNode()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sceneKitView.scene = scene
        sceneKitView.backgroundColor = UIColor.blackColor()
        sceneKitView.autoenablesDefaultLighting = true
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor(white: 0.67, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        node.geometry = SCNSphere(radius: 0.8)
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "earth_NASA")
        node.geometry?.firstMaterial?.doubleSided = true
        scene.rootNode.addChildNode(node)
        
        let action = SCNAction.rotateByAngle(360 * CGFloat((M_PI)/180.0), aroundAxis: SCNVector3(x:0, y:1, z:0), duration: 30)
        let repeatAction = SCNAction.repeatActionForever(action)
        node.runAction(repeatAction)
        
        
    }
    
    
}

