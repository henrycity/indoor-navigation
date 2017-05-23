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
    
    @IBOutlet weak var beaconButton1: UIButton!
    @IBOutlet weak var beaconButton2: UIButton!
    @IBOutlet weak var beaconButton3: UIButton!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var rotateButton: UIButton!
    
    var beaconInfo: [BeaconInfo] = []
    var currentHeading : Double = 0
    var locationManager: CLLocationManager!
    @IBOutlet weak var compassImage: UIImageView!
    var nearestBeaconCoordinate: CGPoint!
    var isRotating: Bool = false
    var lineShapeLayer: CAShapeLayer!
    
    @IBAction func rotateMap(_ sender: Any) {
        isRotating = !isRotating
        if isRotating {
            rotateButton.setTitle("Disable rotation", for: UIControlState.normal)
        } else {
            rotateButton.setTitle("Enable rotation", for: UIControlState.normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rotateButton.setTitle("Enable rotation", for: UIControlState.normal)
        compassImage.backgroundColor = UIColor.clear
        compassImage.isOpaque = true
        beaconInfo = [ BeaconInfo(value: 832, button: beaconButton1, coordinate: CGPoint(x: 107, y: 128)),
                       BeaconInfo(value: 748, button: beaconButton2, coordinate: CGPoint(x: 250, y: 167)),
                       BeaconInfo(value: 771, button: beaconButton3, coordinate: CGPoint(x: 165, y: 212))]
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
        let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: "LightCurb")
        
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
        if isRotating {
            // change in heading in degrees since last code run
            let adjustmentToRotate = (newHeading.magneticHeading - currentHeading)
            // make sure to save the heading for next code run
            currentHeading = newHeading.magneticHeading
            
            // change in heading in radians for some reason who decided this was    ideal
            let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / -180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
            // animate while rotating cause it looks smooooooooth
            UIView.animate(withDuration: 0.5) {
                self.mapView.transform = rotated
            }
        } else {
            // set the rotation of mapView back to 0
            let rotation = (CGFloat(currentHeading) * CGFloat.pi) / 180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
            
            self.mapView.transform = rotated
            
            // set currentHeading to 0 so when rotation gets disabled the mapView will stay on 0
            currentHeading = 0
        }
    }
    
    @IBAction func buttonPress(sender: UIButton) {
        if nearestBeaconCoordinate != nil {
            switch sender {
                case beaconButton1:
                    addLine(fromPoint: nearestBeaconCoordinate, toPoint: beaconInfo[0].coordinate)
                case beaconButton2:
                    addLine(fromPoint: nearestBeaconCoordinate, toPoint: beaconInfo[1].coordinate)
                case beaconButton3:
                    addLine(fromPoint: nearestBeaconCoordinate, toPoint: beaconInfo[2].coordinate)
                default:
                    print("Unknown button")
                    return
            }
        }
    }
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
        // If lineShapeLayer already exist, redraw the whole layer
        if lineShapeLayer != nil {
            lineShapeLayer.removeFromSuperlayer()
        } else {
            lineShapeLayer = CAShapeLayer()
        }
        let linePath = UIBezierPath()
        
        // if we want to draw multiple points just addLine to each new CGPoint
        // we should want to but theres no easy way to work that out
        linePath.move(to: start)
        linePath.addLine(to: end)
        lineShapeLayer.path = linePath.cgPath
        
        // line style
        lineShapeLayer.strokeColor = UIColor.green.cgColor
        lineShapeLayer.lineWidth = 1
        // if we have multiple points to draw to in the future this sets the style of the corners
        lineShapeLayer.lineJoin = kCALineJoinRound
        
        self.mapView.layer.addSublayer(lineShapeLayer)
    }
}
