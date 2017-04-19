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
    @IBOutlet weak var compassReading: UILabel!
    
    @IBOutlet weak var majorReading2: UILabel!
    @IBOutlet weak var minorReading2: UILabel!
    @IBOutlet weak var rssiReading2: UILabel!
    @IBOutlet weak var accuracyReading2: UILabel!
    
    @IBOutlet weak var compassImg: UIImageView!
    
    var currentHeading : Double = 0
    
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        // this really upsets things if its allowed to happen
        //view.backgroundColor = UIColor.gray
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        let uuid = UUID(uuidString: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")!
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "MyBeacon")
        
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(in: beaconRegion)
        
        // start tracking heading
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    
    func update(beacons: [CLBeacon]) {
        self.majorReading.text = beacons[0].major.description
        self.minorReading.text = beacons[0].minor.description
        self.rssiReading.text = beacons[0].rssi.description
        
        // this needs some better handling, if beacon signal is lost it reports -1
        // also Apple themselves say we shouldn't do this but who listens to dev docs anyway
        self.accuracyReading.text = String(format: "%.1fm", beacons[0].accuracy)
        print(beacons[1].accuracy)
        
        self.majorReading2.text = beacons[1].major.description
        self.minorReading2.text = beacons[1].minor.description
        self.rssiReading2.text = beacons[1].rssi.description
        
        // this needs some better handling, if beacon signal is lost it reports -1
        // also Apple themselves say we shouldn't do this but who listens to dev docs anyway
        self.accuracyReading2.text = String(format: "%.1fm", beacons[1].accuracy)
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        
        if beacons.count > 1 {
            update(beacons: beacons)
            if beacons[0].minor == 748 && beacons[0].accuracy > 0 && beacons[0].accuracy <= 2 {
                //                let popOverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sbPopUpID") as! PopUpViewController
                //                self.addChildViewController(popOverVC)
                //                popOverVC.view.frame = self.view.frame
                //                self.view.addSubview(popOverVC.view)
                //                popOverVC.didMove(toParentViewController: self)
                print()
                let alert = UIAlertController(title: "Arrived!", message: "You arrived at your destination", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // change in heading in degrees since last code run
        let adjustmentToRotate = (newHeading.magneticHeading - currentHeading)
        // make sure to save the heading for next code run
        currentHeading = newHeading.magneticHeading
        
        // display heading in text because why not
        compassReading.text = String(format: "%.0f°", newHeading.magneticHeading)
        
        // change in heading in radians for some reason who decided this was ideal
        let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / 180
        let transform = compassImg.transform
        let rotated = transform.rotated(by: rotation)
        // animate while rotating cause it looks smooooooooth
        UIView.animate(withDuration: 0.5) {
            self.compassImg.transform = rotated
        }
    }
}


