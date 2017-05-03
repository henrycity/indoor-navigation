//
//  ViewController.swift
//  MobileDevProject
//
//  Created by Alexander van den Herik on 4/11/17.
//  Copyright © 2017 Alexander van den Herik. All rights reserved.
//

import CoreLocation
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var majorReading: UILabel!
    @IBOutlet weak var minorReading: UILabel!
    @IBOutlet weak var rssiReading: UILabel!
    @IBOutlet weak var accuracyReading: UILabel!
    
    @IBOutlet weak var majorReading2: UILabel!
    @IBOutlet weak var minorReading2: UILabel!
    @IBOutlet weak var rssiReading2: UILabel!
    @IBOutlet weak var accuracyReading2: UILabel!
    
    @IBOutlet weak var compassReading: UILabel!
    @IBOutlet weak var compassImg: UIImageView!
    
    @IBOutlet weak var viewView: UIView!
    @IBOutlet weak var beacon1: UIButton!
    @IBOutlet weak var beacon2: UIButton!
    @IBOutlet weak var beacon3: UIButton!
    
    var locationManager: CLLocationManager!
    
    var currentHeading : Double = 0
    var lastBeacon1: CLBeacon!
    var lastBeacon2: CLBeacon!
    var resetBeaconInfo: Bool!
    
    @IBAction func debugResetBtnPress(_ sender: Any) {
        // set the last beacons to nil which is just null with a stupid name
        // which should let the debug screen redraw with its current beacons if it gets confused thanks to all the ifs
        resetBeaconInfo = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        let uuid = UUID(uuidString: "A4A4279F-091E-4DC7-BD3E-78DD4A0C763C")!
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "MyBeacon")
        
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        
        // start tracking heading
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    
    func updateDebugUI(beacons: [CLBeacon]) {
        /// this falls apart once we remember that we read more than two beacons but i've
        /// spent too long on all these ifs to give up
        // i hate big long chains of ifs like this but i don't know how best to do this in ios
        // or swift so it'll do for now probably
        
        if(((lastBeacon1 == nil || lastBeacon2 == nil) || resetBeaconInfo) && beacons.count > 1){
            /// this is the first launch with enough beacons detected
            printBeaconOne(beacon: beacons[0])
            printBeaconTwo(beacon: beacons[1])
            lastBeacon1 = beacons[0]
            lastBeacon2 = beacons[1]
            
            // make sure to set the reset to false or else we'll be sadder than we already are
            resetBeaconInfo = false
            return
        }
        
        // I really hope the order in the array is based on either signal strength or proximity
        // otherwise this is all a little wonky
        if(beacons.count > 1){
            if(beacons[0].minor == lastBeacon1.minor && beacons[1] == lastBeacon2.minor){
                /// if both beacons are the same and in the same order, print as usual
                printBeaconOne(beacon: beacons[0])
                printBeaconTwo(beacon: beacons[1])
                // save the two updated beacons
                lastBeacon1 = beacons[0]
                lastBeacon2 = beacons[1]
            } else if (beacons[0].minor == lastBeacon2.minor && beacons[1] == lastBeacon1.minor){
                /// if both beacons are the same but in a different order, print "reversed" to keep sanity
                printBeaconOne(beacon: beacons[1])
                printBeaconTwo(beacon: beacons[0])
                // save the two updated beacons but backwards
                lastBeacon1 = beacons[1]
                lastBeacon2 = beacons[0]
            } else {
                /// neither beacon is the same
                // print signal lost for both? I don't know what our logic should be here
                self.accuracyReading.text = "Signal Lost"
                self.accuracyReading2.text = "Signal Lost"
            }
            
        } else {
            /// we lost a beacon, work out which and mark somehow
            if(beacons[0].minor == lastBeacon1.minor){
                printBeaconOne(beacon: beacons[0])
                self.accuracyReading2.text = "Signal Lost"
                lastBeacon1 = beacons[0]
            } else if(beacons[0].minor == lastBeacon2.minor){
                printBeaconTwo(beacon: beacons[0])
                self.accuracyReading.text = "Signal Lost"
                lastBeacon2 = beacons[1]
            } else {
                /// i think we lost both beacons
                self.accuracyReading.text = "Signal Lost"
                self.accuracyReading2.text = "Signal Lost"
            }
        }
    }
    
    // I would much prefer UI objects but since I don't know how to make that a thing
    // in iOS we just need to deal with this, it shouldn't really be user-facing anyway
    func printBeaconOne(beacon: CLBeacon){
        self.majorReading.text = beacon.major.description
        self.minorReading.text = beacon.minor.description
        self.rssiReading.text = beacon.rssi.description
        self.accuracyReading.text = String(format: "%.1fm", beacon.accuracy)
    }
    func printBeaconTwo(beacon: CLBeacon){
        self.majorReading2.text = beacon.major.description
        self.minorReading2.text = beacon.minor.description
        self.rssiReading2.text = beacon.rssi.description
        self.accuracyReading2.text = String(format: "%.1fm", beacon.accuracy)
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        updateDebugUI(beacons: beacons)
        if beacons.count > 0 {
            if beacons[0].minor == 832{
                self.beacon1.backgroundColor = UIColor.blue
                self.beacon2.backgroundColor = UIColor.red
            }else if beacons[0].minor == 748{
                self.beacon1.backgroundColor = UIColor.red
                self.beacon2.backgroundColor = UIColor.blue
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // TODO : Test compass cause it may or may not be backwards now
        
        // change in heading in degrees since last code run
        let adjustmentToRotate = (newHeading.magneticHeading - currentHeading)
        // make sure to save the heading for next code run
        currentHeading = newHeading.magneticHeading
        
        // display heading in text because why not
        compassReading.text = String(format: "%.0f°", newHeading.magneticHeading)
        
        // change in heading in radians for some reason who decided this was ideal
        let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / 180
        
        
        let transformCom = compassImg.transform
        let rotatedCom = transformCom.rotated(by: rotation)
        UIView.animate(withDuration: 0.5) {
            self.compassImg.transform = rotatedCom
        }
        
        let transformMap = viewView.transform
        let rotatedMap = transformMap.rotated(by: rotation)
        UIView.animate(withDuration: 0.5) {
            self.viewView.transform = rotatedMap
        }
    }
}


