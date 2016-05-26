

//
//  ViewController.swift
//  Beacons
//
//  Created by Lalit on 2016-05-14.
//  Copyright © 2016 Bagga. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController,ESTBeaconManagerDelegate{
    
    let beaconManager = ESTBeaconManager()
    let beaconRegion = CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "7A26A0CC-7C1B-4FF2-AE4B-C049CDF8EEF8")!,
        identifier: "IBEACONS")
    let beaconRegions = CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "19D5F76A-FD04-5AA3-B16E-E93277163AF6")!,
        identifier: "USB BEACON")
    
    @IBOutlet weak var minVal: UILabel!
    @IBOutlet weak var uID: UILabel!
    @IBOutlet weak var maxVale: UILabel!
    @IBOutlet weak var distance: UILabel!
    var beacons: [CLBeacon] = []
    var locationBuilder = EILLocationBuilder()
    
    let placesByBeacons = [
        "1000:5": [
            "Heavenly Sandwiches": 20, // read as: it's 50 meters from
            // "Heavenly Sandwiches" to the beacon with
            // major 6574 and minor 54631
            "Green & Green Salads": 150,
            "Mini Panini": 325
        ],
        "0:0": [
            "Heavenly Sandwiches": 250,
            
        ]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         self.beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func placesNearBeacon(beacon:CLBeacon) -> [String]? {
        
        let beaconKey = "\(beacon.major):\(beacon.minor)"
        if let places = self.placesByBeacons[beaconKey] {
            print(places.count)
            
            let sortedPlaces = Array(places).sort{$0.1 < $1.1}.map {$0.0}
            return sortedPlaces
           
        }
        return nil
    }
    
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
       
        
        if let nearestBeacon = beacons.first, places = placesNearBeacon(nearestBeacon) {
            
            
            if beacons.count > 0 {
                let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
                
                uID.text = nearestBeacon.proximityUUID.UUIDString
                minVal.text = String(nearestBeacon.minor.integerValue)
                maxVale.text = String(nearestBeacon.major.integerValue)
                distance.text = String(nearestBeacon.accuracy)
                //print(nearestBeacon.accuracy)
            }
            
           
        }
    }
    
    
    
    
    
    
    
}



