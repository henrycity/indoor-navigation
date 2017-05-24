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
    var nearestBeacon: BeaconInfo!
    var isRotating: Bool = false
    var lineShapeLayer: CAShapeLayer!
    var beaconsArray: [CLBeacon] = []
    var beacon1: CLBeacon
    var beacon2: CLBeacon
    
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
        beaconInfo = [ BeaconInfo(value: 771, button: beaconButton1, coordinate: CGPoint(x: 91, y: 143)),
                       BeaconInfo(value: 748, button: beaconButton2, coordinate: CGPoint(x: 214, y: 187)),
                       BeaconInfo(value: 832, button: beaconButton3, coordinate: CGPoint(x: 138, y: 226))]
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
            beaconsArray = beacons
            for myBeacon in beaconInfo {
                if (myBeacon.value == beacons[0].minor) {
                    myBeacon.button.backgroundColor = UIColor.blue
                    nearestBeacon = myBeacon
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
        
        if nearestBeacon != nil {
            switch sender {
                case beaconButton1:
                    addLine(fromPoint: nearestBeacon, toPoint: beaconInfo[0])
                case beaconButton2:
                    addLine(fromPoint: nearestBeacon, toPoint: beaconInfo[1])
                case beaconButton3:
                    addLine(fromPoint: nearestBeacon, toPoint: beaconInfo[2])
                default:
                    print("Unknown button")
                    return
            }
        }
    }
    
    func addLine(fromPoint start: BeaconInfo, toPoint end: BeaconInfo) {
        while true{
            // If lineShapeLayer already exist, redraw the whole layer
            if lineShapeLayer != nil {
                lineShapeLayer.removeFromSuperlayer()
            } else {
                lineShapeLayer = CAShapeLayer()
            }
            let linePath = UIBezierPath()
            
            // if we want to draw multiple points just addLine to each new CGPoint
            // we should want to but theres no easy way to work that out
            linePath.move(to: start.coordinate)
            linePath.addLine(to: end.coordinate)
            lineShapeLayer.path = linePath.cgPath
            
            // line style
            lineShapeLayer.strokeColor = UIColor.green.cgColor
            lineShapeLayer.lineWidth = 1
            // if we have multiple points to draw to in the future this sets the style of the corners
            lineShapeLayer.lineJoin = kCALineJoinRound
            
            //Code below is to draw a circle to indicate where the user is
            //Calculate where the circle needs to be drawn
            let circleCordinates = calcXY(firstBeacon: start, secondBeacon: end)
            let circlePath = UIBezierPath(arcCenter: circleCordinates, radius: CGFloat(7), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
            let shapeLayer = CAShapeLayer()
            
            shapeLayer.path = circlePath.cgPath
            //change the fill color
            shapeLayer.fillColor = UIColor.red.cgColor
            //you can change the stroke color
            shapeLayer.strokeColor = UIColor.red.cgColor
            //you can change the line width
            shapeLayer.lineWidth = 3.0
            
            //Add the line and circle to the layer
            self.mapView.layer.addSublayer(lineShapeLayer)
            self.mapView.layer.addSublayer(shapeLayer)
        }
        
    }

    func calcXY(firstBeacon: BeaconInfo, secondBeacon: BeaconInfo) -> CGPoint{

        beacon1 = CLBeacon()
        beacon2 = CLBeacon()
        if (beaconsArray.isEmpty){ return CGPoint.zero}
        
        for beacon in beaconsArray{
            print(beacon1)
            if beacon.minor == firstBeacon.value{
                beacon1 = beacon
            }
        }
        
        for beacon in beaconsArray{
            if beacon.minor == secondBeacon.value{
                beacon2 = beacon
            }
        }
        
        let distance = CGFloat((beacon1.accuracy + beacon2.accuracy)/beacon1.accuracy)
        
        let x = ((secondBeacon.coordinate.x - firstBeacon.coordinate.x)*distance + firstBeacon.coordinate.x)
        let y = ((secondBeacon.coordinate.y - firstBeacon.coordinate.y)*distance + firstBeacon.coordinate.y)
    
        let cgPoint = CGPoint.init(x: x, y: y)
        return cgPoint
    }
}
