//
//  GlobeViewController.swift
//  HelloEarth_Swift
//
//  Created by 王迺瑜 on 2016/10/6.
//  Copyright © 2016年 王迺瑜. All rights reserved.
//

import UIKit


class GlobeViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    
    private var theViewC: MaplyBaseViewController?
    private var vectorDict: [String:AnyObject]?
    var userDefault = NSUserDefaults.standardUserDefaults()
    
    var friendLocations: [[String: Float]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an empty globe and add it to the view
        theViewC = WhirlyGlobeViewController()
        self.view.addSubview(theViewC!.view)
        theViewC!.view.frame = self.view.bounds
        addChildViewController(theViewC!)
        
        self.view.bringSubviewToFront(backButton)
        
        let globeViewC = theViewC as? WhirlyGlobeViewController
        
        // we want a black background for a globe, a white background for a map.
        theViewC!.clearColor = (globeViewC != nil) ? UIColor.blackColor() : UIColor.whiteColor()
        
        // and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
        theViewC!.frameInterval = 2
        
        // set up the data source
        
        if let tileSource = MaplyMBTileSource(MBTiles: "geography-class_medres") {
            let layer = MaplyQuadImageTilesLayer(coordSystem: tileSource.coordSys, tileSource: tileSource)
            layer.handleEdges = (globeViewC != nil)
            layer.coverPoles = (globeViewC != nil)
            layer.requireElev = false
            layer.waitLoad = false
            layer.drawPriority = 0
            layer.singleLevelLoading = false
            theViewC!.addLayer(layer)
        }
        
        // start up over Taiwan
        if let globeViewC = globeViewC {
            globeViewC.height = 1.0
            globeViewC.animateToPosition(MaplyCoordinateMakeWithDegrees(121.597366, 25.105497), time: 1.0)
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
                    // the admin tag from the country outline geojson has the country name ­ save
                    //                    guard  let attrs = wgVecObj.attributes, vecName = attrs.objectForKey("ADMIN")
                    if   let attrs = wgVecObj.attributes, vecName = attrs["ADMIN"]
                        as? NSObject {
                        wgVecObj.userObject = vecName
                        
                        // add the outline to our view
                        self.theViewC?.addVectors([wgVecObj], desc: self.vectorDict)
                        
                        // If you ever intend to remove these, keep track of the MaplyComponentObjects above.
                        
                        if vecName.description.characters.count > 0 {
                            let label = MaplyScreenLabel()
                            label.layoutImportance = 10
                            label.text = vecName.description
                            label.loc = wgVecObj.center()
                            label.selectable = true
                            self.theViewC?.addScreenLabels([label],
                                                           desc: [
                                                            kMaplyFont: UIFont.boldSystemFontOfSize(14.0),
                                                            kMaplyTextOutlineColor: UIColor.blackColor(),
                                                            kMaplyTextOutlineSize: 2.0,
                                                            kMaplyColor: UIColor.whiteColor()
                                ])
                        }
                    }
                }
                
            }
        }
    }
    
    
    private func addFriendMarkers() {
        
        guard
            let userInfo = userDefault.objectForKey("UserInfo"),
            let userLatD = userInfo["latitude"] as? Double,
            let userLngD = userInfo["longitude"] as? Double
            else {return}
        
        let userLat = Float(userLatD)
        let userLng = Float(userLngD)
        let userLocation = [MaplyCoordinateMakeWithDegrees(userLng, userLat)]
        let userIcon = UIImage(named: "star-24@2x")
        
        let userMarker = userLocation.map { cap -> MaplyScreenMarker in
            let marker = MaplyScreenMarker()
            marker.image = userIcon
            marker.loc = cap
            marker.size = CGSizeMake(40, 40)
            return marker
        }
        
        var allLocations: [MaplyCoordinate] = []
        
        for friendLocation in friendLocations {
            
            guard
                let friendLat = friendLocation["latitude"],
                let friendLng = friendLocation["longitude"]
                else {return}
            let location = MaplyCoordinateMakeWithDegrees(friendLng, friendLat)
            allLocations.append(location)
            
        }
        
        let friendIcon = UIImage(named: "marker-24@2x")
        let friendMarkers = allLocations.map { cap -> MaplyScreenMarker in
            let marker = MaplyScreenMarker()
            marker.image = friendIcon
            marker.loc = cap
            marker.size = CGSizeMake(40, 40)
            return marker
            
        }
        
        theViewC?.addScreenMarkers(friendMarkers, desc: nil)
        theViewC?.addScreenMarkers(userMarker, desc: nil)
        
    }
    
}

