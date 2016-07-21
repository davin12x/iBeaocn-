

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
    let testData = DataSet(dataType: .Classification, inputDimension: 1, outputDimension: 1)
   

    var fireBaseDatabse = FIRDatabase.database().reference()
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
    var _heatZone:String?
    var _udi:String!
    var _minor:String!
    var datas = DataSet(dataType: DataSetType.Classification, inputDimension: 1, outputDimension: 1)
    //  Create an SVM classifier and train
    let svm = SVMModel(problemType: .C_SVM_Classification, kernelSettings:
        KernelParameters(type: .RadialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.0))
    
    
    
    
    //Define  x,y Region for each beacons distance need to update  dynamically 
    //if any beacon come in same cooridnate algo will give nan or some other values
    
    //First beacon position and distance from it
    struct first{
        var x = 0.0;
        var y = 0.0;
        var distance = 3.0;
    }
    //Second beacon position and distance from it
    struct second{
        var x = 0.2;
        var y = 3.2;
        var distance = 5.0;
    }
    //Third beacon position and distance from it
    struct third{
        var x = 3.20;
        var y = 3.10;
        var distance = 5.0;
    }
    
    //Projects Loads from here
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.beaconManager.delegate = self
        self.beaconManager.requestAlwaysAuthorization()
        self.beaconManager.avoidUnknownStateBeacons = true
        self.fireBaseDatabse = FIRDatabase.database().reference()
        
        
        
        //This is used to convert outer model file to string and put it into documents directory . Which is useless
        //
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
        socket.delegate = self
        socket.connect()
        var i = 0;
        var j = 1;
        
        
        var dd = [String]()
        var hey = [String]()
        
        for elements in yourArray.reverse() {
            if j == 565{
                break;
            }
            
            trainClassfier(yourArray[j], output: Int(yourArray[i]))
            
            i += 2
            j += 2
           
        }
        
        
       
        svm.train(datas)
        print("Data trained")
        
        let testData = DataSet(dataType: .Classification, inputDimension: 1, outputDimension: 1)
        do {
            try testData.addTestDataPoint(input: [0.3117])
        }
        catch {
            print("Invalid data set created")
        }
        
        svm.predictValues(testData)
        
        var classLabel : Int
        do {
            try classLabel = testData.getClass(0)
            try print(classLabel)
        }
        catch {
            print("Error in prediction")
        }
    }
    

    
    //will make path to documents
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
       
        //To start region of USB beacon
       // self.beaconManager.startRangingBeaconsInRegion(self.beaconRegions)
        
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
            // here "jsonData" is the dictionary encoded in JSON data
            //  print(jsonData)
            var dataString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            socket.writeString(dataString!)
        } catch let error as NSError {
            print(error)
        }
    
    }

    func beaconManager(manager: AnyObject, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        
        let iBeacon = "7A26A0CC-7C1B-4FF2-AE4B-C049CDF8EEF8"
        let usbBeacons = "19D5F76A-FD04-5AA3-B16E-E93277163AF6"
        
        //To fileter the beacons
        for CLBeacon in beacons {
            if CLBeacon.proximityUUID.UUIDString == iBeacon {
                //print(CLBeacon.proximityUUID.UUIDString)
            } else {
                print("usb beacon uid\(CLBeacon.proximityUUID.UUIDString)")
            }
        }
        
        //To calculate distance with RSSI
        func calculateAccuracyWithRSSI(rssi:Double)->Double {
            
            //formula adapted from David Young's Radius Networks Android iBeacon Code
            if (rssi == 0) {
                return -1.0; // if we cannot determine accuracy, return -1.
            }
            let txPower = -70;
            let ratio = rssi*1.0/Double(txPower);
            if (ratio < 1.0) {
                return pow(ratio,10);
            }
            else {
                let accuracy =  (0.89976) * pow(ratio,7.7095) + 0.111;
                return accuracy
            }
        }
    
        //Will return position of object in x,y format
        func getTrilateration()->(x:Double,y:Double) {
            var position1 = first();
            var position2 = second();
            var position3 = third();
            
            var xa = position1.x;
            var ya = position1.y;
            var xb = position2.x;
            var yb = position2.y;
            var xc = position3.x;
            var yc = position3.y;
            var ra = position1.distance;
            var rb = position2.distance;
            var rc = position3.distance;
            
            var S = (pow(xc, 2.0) - pow(xb, 2.0) + pow(yc, 2.0) - pow(yb, 2.0) + pow(rb, 2.0) - pow(rc, 2.0)) / 2.0;
            var T = (pow(xa, 2.0) - pow(xb, 2.0) + pow(ya, 2.0) - pow(yb, 2.0) + pow(rb, 2.0) - pow(ra, 2.0)) / 2.0;
            var y = ((T * (xb - xc)) - (S * (xb - xa))) / (((ya - yb) * (xb - xc)) - ((yc - yb) * (xb - xa)));
            var x = ((y * (ya - yb)) - T) / (xb - xa);
            return(x,y)
            
        }
        
        if let nearestBeacon = beacons.last {
            if beacons.count > 0 {
                let nearestBeacon:CLBeacon = beacons[0] as CLBeacon
                uID.text = nearestBeacon.proximityUUID.UUIDString
                minVal.text = String(nearestBeacon.minor)
                maxVale.text = String(nearestBeacon.rssi)
                distance.text = String(nearestBeacon.accuracy)
                
                var minor:Int
                var major:Int
                
                minor = nearestBeacon.minor as Int
                major = nearestBeacon.major as Int
                
                let timestamps = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .MediumStyle)
                
               // print(nearestBeacon.accuracy)
                print(nearestBeacon.accuracy)
                print(scaleFunction(nearestBeacon.accuracy))
            
                
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
                        try print(classLabel)
                    }
                    catch {
                        print("Error in prediction")
                    }
                }
            
                
                //Passing accuracy
                //getHeatZone(nearestBeacon.accuracy)
                
//                writeDataToServer(1,timeStamp: timestamps,deviceID:deviceID,beaconID: nearestBeacon.proximityUUID.UUIDString,
//                                  major: major,minor:minor)
                
                
      //          postToFirebase(nearestBeacon.proximityUUID.UUIDString, rssi: String(nearestBeacon.rssi), accuracy: String(nearestBeacon.accuracy), minor: String(nearestBeacon.minor), zoneType: _heatZone!)
            }
           
        }
    }
    
    func postToFirebase(uid:String,rssi:String,accuracy:String,minor:String,zoneType:String){
        let information = ["heat":zoneType,
                           "rssi":rssi,
                           "accuracy":accuracy]
        _udi = uid
        _minor = minor
        
        var beaconIdAndMinorValue = "\(uid)-\(minor)"
        self.fireBaseDatabse.child(beaconIdAndMinorValue).child(zoneType).childByAutoId().setValue(information)
    }
    
    @IBAction func onOnePressed(sender: AnyObject) {
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
        _heatZone = "1"
    }
    
    @IBAction func onTwoPressed(sender: AnyObject) {
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
          _heatZone = "2"
    }
    
    
    @IBAction func onThreePressed(sender: AnyObject) {
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
          _heatZone = "3"
    }
    
    @IBAction func onFourPressed(sender: AnyObject) {
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
          _heatZone = "4"
    }
    
    
    @IBAction func onFivePressed(sender: AnyObject) {
        self.beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
          _heatZone = "5"
    }
    
    @IBAction func onStopPressed(sender:AnyObject) {
    
        self.beaconManager.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    @IBAction func onDeletePressed(sender:AnyObject) {
        var id = "\(_udi)-\(_minor)"
        print(id)
         self.fireBaseDatabse.child("7A26A0CC-7C1B-4FF2-AE4B-C049CDF8EEF8-4").child(_heatZone!).removeValue()
    }
    
    func trainClassfier(first:Double,output:Int) -> Void {
        //Training
       
        do {
                try datas.addDataPoint(input: [first], output:output)
        }
        catch {
            print("Invalid data set created")
        }
    }
    

    func addAccuracy(acc:Double) {
        
        do {
           try testData.addTestDataPoint(input: [0.4858])
            print("Add ac")
        }
        catch {
            print("Invalid data set created")
        }
        
    }
    
    func getHeat() {
        
       // realSVM.predictValues(testData)
        var classLabel : Int
        do {
            try classLabel = testData.getClass(0)
            try print(classLabel)
        }
        catch {
    
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




