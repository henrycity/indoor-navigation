//
//  ViewController.swift
//  MobileDevProject
//
//  Created by Alexander van den Herik; Daniel Wilson; Leendert Eloff; Tri Tran
//  Copyright © 2017 Alexander van den Herik. All rights reserved.
//

import CoreLocation
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var compassButton: UIButton!
    @IBOutlet weak var beaconButton1: UIButton!
    @IBOutlet weak var beaconButton2: UIButton!
    @IBOutlet weak var beaconButton3: UIButton!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var mapImage: UIView!
    
    var beaconInfo: [BeaconInfo] = []
    var currentHeading : Double = 0
    var locationManager: CLLocationManager!
    var nearestBeaconCoordinate: CGPoint!
    var allowRotate: Bool = true
   
    override func viewDidLoad() {
        super.viewDidLoad()
        beaconInfo = [ BeaconInfo(value: 832, button: beaconButton1, coordinate: CGPoint(x: 91, y: 143)),
                       BeaconInfo(value: 748, button: beaconButton2, coordinate: CGPoint(x: 214, y: 187)),
                       BeaconInfo(value: 771, button: beaconButton3, coordinate: CGPoint(x: 138, y: 226))]
        
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
            for myBeacon in beaconInfo {
                if (myBeacon.value == beacons[0].minor) {
                    myBeacon.button.backgroundColor = UIColor.blue
                    nearestBeaconCoordinate = myBeacon.coordinate
                } else {
                    myBeacon.button.backgroundColor = UIColor.red
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // change in heading in degrees since last code run
        let adjustmentToRotate = (newHeading.magneticHeading - currentHeading)
        // make sure to save the heading for next code run
        currentHeading = newHeading.magneticHeading
        
        if (allowRotate){
            // change in heading in radians for some reason who decided this was ideal
            let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / -180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
            // animate while rotating cause it looks smooooooooth
            UIView.animate(withDuration: 0.5) {
                self.mapView.transform = rotated
            }
        } else {
            // change in heading in radians for some reason who decided this was ideal
            let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / 180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
            // animate while rotating cause it looks smooooooooth
            UIView.animate(withDuration: 0.5) {
                self.compassButton.transform = rotated
            }
        }
    }
    
    @IBAction func buttonPress(sender: UIButton) {
        if nearestBeaconCoordinate != nil {
            switch sender {
            // TODO: fix the fromPoints but right now I don't think we have anything for what beacon we're closest to
            case beaconButton1:
                addLine(fromPoint: nearestBeaconCoordinate, toPoint: beaconInfo[0].coordinate)
            case beaconButton2:
                addLine(fromPoint: nearestBeaconCoordinate, toPoint: beaconInfo[1].coordinate)
            case beaconButton3:
                addLine(fromPoint: nearestBeaconCoordinate, toPoint: beaconInfo[2].coordinate)
            case compassButton:
                if(allowRotate){
                    // set boolean used by location manager to not rotate map
                    allowRotate = false
                    // reset map
                    self.mapView.transform.rotated(by: -(CGFloat(currentHeading) * CGFloat.pi) / -180)
                    // set to zero because the rotations assume change in heading
                    currentHeading = 0
                } else {
                    allowRotate = false
                    // reset compass button
                    self.compassButton.transform.rotated(by: -(CGFloat(currentHeading) * CGFloat.pi) / 180)
                    currentHeading = 0
                }
            default:
                print("Unknown button")
                return
            }
        }
    
    }
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        
        // if we want to draw multiple points just addLine to each new CGPoint
        // we should want to but theres no easy way to work that out
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        
        // line style
        line.strokeColor = UIColor.green.cgColor
        line.lineWidth = 1
        // if we have multiple points to draw to in the future this sets the style of the corners
        line.lineJoin = kCALineJoinRound
        
        self.mapImage.layer.addSublayer(line)
    }
}
