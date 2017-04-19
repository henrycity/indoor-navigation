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
    
    @IBOutlet weak var beacon1: UIButton!
    @IBOutlet weak var beacon2: UIButton!
    @IBOutlet weak var beacon3: UIButton!

    var currentHeading : Double = 0

    var locationManager: CLLocationManager!
    
    @IBOutlet weak var viewView: UIView!
   
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
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
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
        // change in heading in degrees since last code run
        let adjustmentToRotate = (newHeading.magneticHeading - currentHeading)
        // make sure to save the heading for next code run
        currentHeading = newHeading.magneticHeading
        
        // display heading in text because why not
        
        // change in heading in radians for some reason who decided this was ideal
        let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / -180
        let transform = viewView.transform
        let rotated = transform.rotated(by: rotation)
        // animate while rotating cause it looks smooooooooth
        UIView.animate(withDuration: 0.5) {
            self.viewView.transform = rotated
        }
    }
}


