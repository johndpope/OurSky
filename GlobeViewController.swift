//
//  GlobeViewController.swift
//  HelloEarth_Swift
//
//  Created by 王迺瑜 on 2016/10/6.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit
import WhirlyGlobe

class GlobeViewController: UIViewController, WhirlyGlobeViewControllerDelegate, MaplyViewControllerDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    
    private var theViewC: MaplyBaseViewController?
    private var vectorDict: [String:AnyObject]?
    var userDefault = NSUserDefaults.standardUserDefaults()
    var friendStatus: [[String:AnyObject]] = []
    var fromSpecificFriend: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an empty globe and add it to the view
        theViewC = WhirlyGlobeViewController()
        guard let theViewC = theViewC else {return}
        self.view.addSubview(theViewC.view)
        theViewC.view.frame = self.view.bounds
        addChildViewController(theViewC)
        
        self.view.bringSubviewToFront(backButton)
        
        let globeViewC = theViewC as? WhirlyGlobeViewController
        
        if let globeViewC = globeViewC {
            globeViewC.delegate = self
        }
        
        // we want a black background for a globe, a white background for a map.
        theViewC.clearColor = (globeViewC != nil) ? UIColor.blackColor() : UIColor.whiteColor()
        
        // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
        theViewC.frameInterval = 2
        
        // set up the data source
        
        if let tileSource = MaplyMBTileSource(MBTiles: "geography-class_medres") {
            let layer = MaplyQuadImageTilesLayer(coordSystem: tileSource.coordSys, tileSource: tileSource)
            layer.handleEdges = (globeViewC != nil)
            layer.coverPoles = (globeViewC != nil)
            layer.requireElev = false
            layer.waitLoad = false
            layer.drawPriority = 0
            layer.singleLevelLoading = false
            theViewC.addLayer(layer)
        }
        
        // start up over Taiwan
        if let globeViewC = globeViewC {
            
            globeViewC.height = 1.0
            
            if fromSpecificFriend == false {
                
                guard
                    let user = UserManager.shared.currentUser,
                    let userLat = user.latitude as? Float,
                    let userLng = user.longitude as? Float
                    else {return}
                
            
            globeViewC.animateToPosition(MaplyCoordinateMakeWithDegrees(userLng, userLat), time: 1.0)
            
            } else {
                
                let lat = friendStatus[0]["latitude"] as? Double ?? 0.0
                let lng = friendStatus[0]["longitude"] as? Double ?? 0.0
                globeViewC.animateToPosition(MaplyCoordinateMakeWithDegrees(Float(lng), Float(lat)), time: 1.0)
                
            }
        }
        
        vectorDict = [
            kMaplyColor: UIColor.whiteColor(),
            kMaplySelectable: true,
            kMaplyVecWidth: 4.0]
        
        // add the countries
        addCountries()
        addFriendMarkers()
        
    }
    
    
    private func addCountries() {
        // handle this in another thread
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        dispatch_async(queue) {
            let allOutlines = NSBundle.mainBundle().pathsForResourcesOfType("geojson", inDirectory: nil)
            
            for outline in allOutlines {
                if let jsonData = NSData(contentsOfFile: outline),
                    wgVecObj = MaplyVectorObject(fromGeoJSON: jsonData) {
                    
                    if let attrs = wgVecObj.attributes, vecName = attrs["ADMIN"]
                        as? NSObject {
                        wgVecObj.userObject = vecName
                        wgVecObj.selectable = true
                        
                        // add the outline to our view
                        self.theViewC?.addVectors([wgVecObj], desc: self.vectorDict)
                        
                        //Show countries' name
                        
                        //                        if vecName.description.characters.count > 0 {
                        //                            let label = MaplyScreenLabel()
                        //                            label.layoutImportance = 10
                        //                            label.text = vecName.description
                        //                            label.loc = wgVecObj.center()
                        //                            label.selectable = true
                        //                            self.theViewC?.addScreenLabels([label],
                        //                                                           desc: [
                        //                                                            kMaplyFont: UIFont.boldSystemFontOfSize(14.0),
                        //                                                            kMaplyTextOutlineColor: UIColor.blackColor(),
                        //                                                            kMaplyTextOutlineSize: 2.0,
                        //                                                            kMaplyColor: UIColor.whiteColor()
                        //                                ])
                        //                        }
                    }
                }
                
            }
        }
    }
    
    
    private func addFriendMarkers() {
        
        guard
            let user = UserManager.shared.currentUser,
            let userLat = user.latitude as? Float,
            let userLng = user.longitude as? Float
            else {return}
        
        let userLocation = [MaplyCoordinateMakeWithDegrees(userLng, userLat)]
        let userIcon = UIImage(named: "self_pin")
        
        let userMarker = userLocation.map { cap -> MaplyScreenMarker in
            let marker = MaplyScreenMarker()
            let userObject: [AnyObject] = ["You", ""]
            marker.userObject = userObject
            marker.image = userIcon
            marker.loc = cap
            marker.size = CGSizeMake(40, 40)
            return marker
        }
        
        let friendIcon = UIImage(named: "friend_pin")
        
        for friend in friendStatus {
            
            let friendLat = Float(friend["latitude"] as? Double ?? 0.0)
            let friendLng = Float(friend["longitude"] as? Double ?? 0.0)
            let location = MaplyCoordinateMakeWithDegrees(friendLng, friendLat)
            
            let marker = MaplyScreenMarker()
            let userObject: [AnyObject] = [friend["name"]!, friend["online"]!]
            marker.userObject = userObject
            marker.image = friendIcon
            marker.loc = location
            marker.size = CGSizeMake(40, 40)
            
            
            theViewC?.addScreenMarkers([marker], desc: nil)
            
        }
        
        theViewC?.addScreenMarkers(userMarker, desc: nil)
        
    }
    
    private func addAnnotationWithTitle(title: String, subtitle: String, loc:MaplyCoordinate) {
        theViewC?.clearAnnotations()
        
        let a = MaplyAnnotation()
        a.title = title
        a.subTitle = subtitle
        
        theViewC?.addAnnotation(a, forPoint: loc, offset: CGPointZero)
    }
    
    func globeViewController(viewC: WhirlyGlobeViewController, didTapAt coord: MaplyCoordinate) {
        let subtitle = NSString(format: "(%.2fN, %.2fE)", coord.y*57.296,coord.x*57.296) as String
        addAnnotationWithTitle("Coordinate: ", subtitle: subtitle, loc: coord)
    }
    
    // Unified method to handle the selection
    private func handleSelection(selectedObject: NSObject) {
        if let selectedObject = selectedObject as? MaplyVectorObject {
            
            let loc = selectedObject.center()
            let countryName = selectedObject.userObject as? String ?? ""
            addAnnotationWithTitle("Country", subtitle: countryName, loc: loc)
            
        }
        else if let selectedObject = selectedObject as? MaplyScreenMarker {
            
            guard let userObject = selectedObject.userObject as? [AnyObject] else {return}
            let name = userObject[0] as? String ?? ""
            let online = userObject[1] as? String ?? ""
            addAnnotationWithTitle( name, subtitle: online, loc: selectedObject.loc)
            
        }
    }
    
    // This is the version for a globe
    func globeViewController(viewC: WhirlyGlobeViewController, didSelect selectedObj: NSObject) {
        handleSelection(selectedObj)
    }
}

