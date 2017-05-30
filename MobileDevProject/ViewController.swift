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
    var circleShapeLayer: CAShapeLayer!
    var beaconsArray: [CLBeacon] = []
    var circleShapeDrawn: Bool = false
    var beacon1: CLBeacon!
    var beacon2: CLBeacon!
    var cgPoint: CGPoint!
    
    var isNavigating: Bool = false
    var navigatingBeacon: BeaconInfo!
    
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
                
                if(isNavigating){
                    if(beacons[0].minor == navigatingBeacon.value && beacons[0].proximity == CLProximity.immediate){
                        // we have arrived
                        isNavigating = false
                        print("123223")
                    }else{
                        addLine(fromPoint: nearestBeacon, toPoint: navigatingBeacon)
                        updateCircle(fromPoint: nearestBeacon, toPoint: navigatingBeacon)
                    }
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
            // animate while rotating cause it looks smooth
            UIView.animate(withDuration: 0.5) {
                self.mapView.transform = rotated
            }
        } else {
            // set the rotation of mapView back to 0
            let rotation = (CGFloat(currentHeading) * CGFloat.pi) / 180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
           
            UIView.animate(withDuration: 0.5) {
                self.mapView.transform = rotated
            }
            // set currentHeading to 0 so when rotation gets disabled the mapView will stay on 0
            currentHeading = 0
            
        }
    }
    
    @IBAction func buttonPress(sender: UIButton) {
        if nearestBeacon != nil {
            switch sender {
                case beaconButton1:
                    addLine(fromPoint: nearestBeacon, toPoint: beaconInfo[0])
                    updateCircle(fromPoint: nearestBeacon, toPoint: beaconInfo[0])
                    navigatingBeacon = beaconInfo[0]
                case beaconButton2:
                    addLine(fromPoint: nearestBeacon, toPoint: beaconInfo[1])
                    updateCircle(fromPoint: nearestBeacon, toPoint: beaconInfo[1])
                    navigatingBeacon = beaconInfo[1]
                case beaconButton3:
                    addLine(fromPoint: nearestBeacon, toPoint: beaconInfo[2])
                    updateCircle(fromPoint: nearestBeacon, toPoint: beaconInfo[2])
                    navigatingBeacon = beaconInfo[2]
                default:
                    print("Unknown button")
                    return
            }
            isNavigating = true
        }
    }
    
    func addLine(fromPoint start: BeaconInfo, toPoint end: BeaconInfo) {
        print(start)
        print(end)
        //Make seperate thread so everything else can continue
//        DispatchQueue.global(qos: .background).async {
            // If lineShapeLayer already exist, redraw the whole layer
            if self.lineShapeLayer != nil {
                self.lineShapeLayer.removeFromSuperlayer()
            } else {
                self.lineShapeLayer = CAShapeLayer()
            }
            let linePath = UIBezierPath()
            
            // if we want to draw multiple points just addLine to each new CGPoint
            // we should want to but theres no easy way to work that out
            linePath.move(to: start.coordinate)
            linePath.addLine(to: end.coordinate)
            self.lineShapeLayer.path = linePath.cgPath
            
            // line style
            self.lineShapeLayer.strokeColor = UIColor.green.cgColor
            self.lineShapeLayer.lineWidth = 1
            // if we have multiple points to draw to in the future this sets the style of the corners
            self.lineShapeLayer.lineJoin = kCALineJoinRound
            //Add the line to the layer
            self.mapView.layer.addSublayer(self.lineShapeLayer)
            
//            while true{
                //make the function wait for half a second so there is enough time to draw
//                usleep(1000000)
 
                //remove last layer so you don't get circleShapeLayers on top of eachother
        
//            }
//        }
    }
    
    func updateCircle(fromPoint start: BeaconInfo, toPoint end: BeaconInfo) {
        if self.circleShapeDrawn{
            self.mapView.layer.sublayers?.remove(at: (self.mapView.layer.sublayers?.count)! - 2)
        }
        
        self.circleShapeLayer = CAShapeLayer();
        
        //Calculate where the circle needs to be drawn
        let circleCordinates = self.calcXY(firstBeacon: start, secondBeacon: end)
        let circlePath = UIBezierPath(arcCenter: circleCordinates, radius: CGFloat(7), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        self.circleShapeLayer.path = circlePath.cgPath
        //change the fill color
        self.circleShapeLayer.fillColor = UIColor.red.cgColor
        //you can change the stroke color
        self.circleShapeLayer.strokeColor = UIColor.red.cgColor
        //you can change the line width
        self.circleShapeLayer.lineWidth = 3.0
        
        //Add circle to the layer
        self.mapView.layer.addSublayer(self.circleShapeLayer)
        self.circleShapeDrawn = true
    }

    func calcXY(firstBeacon: BeaconInfo, secondBeacon: BeaconInfo) -> CGPoint{

        if beaconsArray.count <= 1 && cgPoint != nil{
            return cgPoint
        }else if beaconsArray.count <= 1{
            return CGPoint.zero
        }
        
        for beacon in beaconsArray{
            if beacon.minor == firstBeacon.value{
                beacon1 = beacon
            }
        }
        
        for beacon in beaconsArray{
            if beacon.minor == secondBeacon.value{
                beacon2 = beacon
            }
        }
        if (beacon1 == nil || beacon2 == nil) && cgPoint != nil {
            return cgPoint
        }
        
        if (beacon1.accuracy == -1 || beacon2.accuracy == -1) && cgPoint != nil {
            return cgPoint
        }
        
        let distance = CGFloat(beacon1.accuracy/(beacon1.accuracy + beacon2.accuracy))
        let x = ((secondBeacon.coordinate.x - firstBeacon.coordinate.x)*distance + firstBeacon.coordinate.x)
        let y = ((secondBeacon.coordinate.y - firstBeacon.coordinate.y)*distance + firstBeacon.coordinate.y)
        cgPoint = CGPoint.init(x: x, y: y)
        
        return cgPoint
    }
}
