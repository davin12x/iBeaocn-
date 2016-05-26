//
//  AppDelegate.swift
//  Beacons
//
//  Created by Lalit on 2016-05-14.
//  Copyright © 2016 Bagga. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, ESTBeaconManagerDelegate {

    var window: UIWindow?
    var locationManager : CLLocationManager?
    var lastProximity: CLProximity?
    
    let uuidString = "7A26A0CC-7C1B-4FF2-AE4B-C049CDF8EEF8"
    let beaconIdentifier = "monitored region"
    
    //Init beaconManager
    let beaconManager = ESTBeaconManager()
    
    


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        
        self.beaconManager.delegate = self
        
        self.beaconManager.requestAlwaysAuthorization()
        
        
        
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!
        
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, identifier: beaconIdentifier)
        
        //Start Moitoring
        self.beaconManager.startMonitoringForRegion(beaconRegion)
        
        //To run app from Delegate call below method
        //initLocationManager()
        
        // to show notifications
        UIApplication.sharedApplication().registerUserNotificationSettings(
            UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        
        return true
    }
    
    func initLocationManager() {
        
        let beaconUUID:NSUUID = NSUUID(UUIDString: uuidString)!
        let beaconRegion:CLBeaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, identifier: beaconIdentifier)
        locationManager = CLLocationManager()
        
        self.locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        locationManager!.startMonitoringForRegion(beaconRegion)
        locationManager!.startRangingBeaconsInRegion(beaconRegion)
                locationManager!.startUpdatingLocation();
        
//        //To Notify
//                if(application.respondsToSelector("registerUserNotificationSettings:")) {
//                    application.registerUserNotificationSettings(
//                        UIUserNotificationSettings(
//                            forTypes: UIUserNotificationType.Alert ,
//                            categories: nil
//                        )
//                    )
//                }
    }
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        let notification = UILocalNotification()
        notification.alertBody =
            "Your gate closes in 47 minutes. " +
            "Current security wait time is 15 minutes, " +
            "and it's a 5 minute walk from security to the gate. " +
        "Looks like you've got plenty of time!"
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    

}
extension AppDelegate:CLLocationManagerDelegate{
    
    
    
    func sendLocalNotificationWithMessage (message:String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        NSLog("didRangeBeacons");
        
        var message:String = ""
        
        if(beacons.count > 0) {
    
        let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
            
            if(nearestBeacon.proximity == lastProximity ||
                nearestBeacon.proximity == CLProximity.Unknown) {
                return;
            }
            lastProximity = nearestBeacon.proximity;
            
            print(nearestBeacon.accuracy)
            
            
            switch nearestBeacon.proximity {
            case CLProximity.Far:
                message = "You are far away from the beacon"
            case CLProximity.Near:
                message = "You are near the beacon"
            case CLProximity.Immediate:
                message = "You are in the immediate proximity of the beacon"
            case CLProximity.Unknown:
                return
            }
        } else {
            message = "No beacons are nearby"
        }
        
        NSLog("%@", message)
        sendLocalNotificationWithMessage(message)
    }
    
}


