

//
//  ViewController.swift
//  Beacons
//
//  Created by Lalit on 2016-05-14.
//  Copyright © 2016 Bagga. All rights reserved.
// Ref //https://gist.github.com/kdzwinel/8235348

import UIKit
import CoreLocation
import Firebase
import KontaktSDK
import Starscream
import Foundation

class ViewController: UIViewController,ESTBeaconManagerDelegate,WebSocketDelegate{
    
    
    let beaconManager = ESTBeaconManager()
    var fileMgr = NSFileManager()
    var yourArray = [Double]()
    let filemgr = NSFileManager.defaultManager()
    var socket = WebSocket(url: NSURL(string: "ws://192.168.0.23:54321")!)
    var scanned: Double?
   
    
    //Device ID
    var deviceID =  UIDevice.currentDevice().identifierForVendor!.UUIDString
   
    //Add Beacon ID
    let beaconRegion = CLBeaconRegion(
        proximityUUID: NSUUID(UUIDString: "7A26A0CC-7C1B-4FF2-AE4B-C049CDF8EEF8")!,
        identifier: "IBEACONS")
    
    @IBOutlet weak var minVal: UILabel!
    @IBOutlet weak var uID: UILabel!
    @IBOutlet weak var maxVale: UILabel!
    @IBOutlet weak var distance: UILabel!
    
    var beacons: [CLBeacon] = []
    var locationBuilder = EILLocationBuilder()
    var _heatZone:String?
    var _udi:String!
    var _minor:String!
    
    //  Create an SVM classifier and train
    var datas = DataSet(dataType: DataSetType.Classification, inputDimension: 1, outputDimension: 1)
    let svm = SVMModel(problemType: .C_SVM_Classification, kernelSettings:
        KernelParameters(type: .RadialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.0))
    let testData = DataSet(dataType: .Classification, inputDimension: 1, outputDimension: 1)
    
    
    
    //Projects Loads from here
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        self.beaconManager.avoidUnknownStateBeacons = true
        socket.delegate = self
        socket.connect()
        
        
        //This is used to convert outer model file to string and put it into documents directory
        if let path = NSBundle.mainBundle().pathForResource("datas", ofType: "txt"){
            let fm = NSFileManager()
            let exists = fm.fileExistsAtPath(path)
            var items = 0
            if(exists){
                do {
                    
                    var text = try  String(contentsOfFile: path)
                    var brokeByLines = text.componentsSeparatedByString(" ")
                    
                    for items in brokeByLines {
                        
                        let trimmedString = items.stringByTrimmingCharactersInSet(
                            NSCharacterSet.whitespaceAndNewlineCharacterSet()
                        )
                    
                        if trimmedString != "" {
                            yourArray.append(Double(trimmedString)!)
                        }
                        
                    }
      
                } catch let error as NSError {
                    print(error)
                }
            }
        }
        
        
        var i = 0;
        var j = 1;
        //Create data for training
        for elements in yourArray.reverse() {
            if j == 565{
                break;
            }
            trainClassfier(yourArray[j], output: Int(yourArray[i]))
            i += 2
            j += 2
           
        }
        
        //Train Svm
        svm.train(datas)
    }
    

    
    //will make path to documents
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    
    func websocketDidConnect(ws: WebSocket) {
        print("websocket is connected")
    }
    
    
    func websocketDidDisconnect(ws: WebSocket, error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
            //socket.connect();
        } else {
            print("websocket disconnected")
            //socket.connect();
        }
    }
    
    func websocketDidReceiveMessage(ws: WebSocket, text: String) {
        print("Received text: \(text)")
    }
    
    func websocketDidReceiveData(ws: WebSocket, data: NSData) {
        print("Received data: \(data.length)")
    }
    
    //This methods will pass data to server
    func writeDataToServer(heatZone:Int, timeStamp:String, deviceID:String,
                           beaconID:String, major:Int,minor:Int) {
        
        let jsonObject: [String: AnyObject] = [
            "commandName": "SendDevicePosition",
            "commandParams":[
            "deviceId":deviceID,
                "beaconUUID":beaconID,
                "major":major,
                "minor":minor,
                "heatZone":1,
                "timeStamp":timeStamp
            ],
        ]
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: .PrettyPrinted)
            var dataString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            socket.writeString(dataString!)
        } catch let error as NSError {
            print(error)
        }
    
    }
    
    //Callback function of estimote beacon
    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        let iBeacon = "7A26A0CC-7C1B-4FF2-AE4B-C049CDF8EEF8"
        if let nearestBeacon = beacons.last {
            if beacons.count > 0 {
                let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
                uID.text = nearestBeacon.proximityUUID.UUIDString
                minVal.text = String(nearestBeacon.minor)
                distance.text = String(nearestBeacon.accuracy)
                
                var minor:Int
                var major:Int
                
                minor = nearestBeacon.minor as Int
                major = nearestBeacon.major as Int
                
                let timestamps = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .MediumStyle)
                if nearestBeacon.accuracy != -1 {
                    let testData = DataSet(dataType: .Classification, inputDimension: 1, outputDimension: 1)
                    do {
                        try testData.addTestDataPoint(input: [scaleFunction(nearestBeacon.accuracy)])
                    }
                    catch {
                        print("Invalid data set created")
                    }
                    
                    svm.predictValues(testData)
                    
                    var classLabel : Int
                    do {
                        try classLabel = testData.getClass(0)
                        maxVale.text = String("heatZone : \(classLabel)")
                        writeDataToServer(classLabel, timeStamp: timestamps, deviceID: deviceID, beaconID: nearestBeacon.proximityUUID.UUIDString,
                                          major: major, minor: minor)
                    }
                    catch {
                        print("Error in prediction")
                    }
                }
            }
           
        }
    }
    
    
    @IBAction func onOnePressed(sender: AnyObject) {
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
    }
    
    @IBAction func onStopPressed(sender:AnyObject) {
    
        self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func trainClassfier(first:Double,output:Int) -> Void {
        //Training data
       
        do {
                try datas.addDataPoint(input: [first], output:output)
        }
        catch {
            print("Invalid data set created")
        }
    }
    
    
    /***
     * get the scale value
     *
     * @param distance getting from Estimo sdk
     * @return
     */
    
    func scaleFunction(distance:Double) -> Double {
        //return y_lower + (y_upper - y_lower) * (value - y_min)/(y_max-y_min);
        return 0 + (1 - 0) * (distance - 1.591574057) / (24.48436747 - 1.591574057);
    }

}




