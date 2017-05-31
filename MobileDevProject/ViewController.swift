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

    @IBOutlet weak var mapRotatingSwitch: UISwitch!

    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var compassImage: UIImageView!

    var beaconInfo: [BeaconInfo] = []
    var beaconsArray: [CLBeacon] = []

    var nearestBeacon: BeaconInfo!
    var navigatingBeacon: BeaconInfo! // this is the beacon that the user chose to navigate to
    var isNavigating: Bool = false

    var mapHeading: Double = 0
    var compassHeading: Double = 0
    var mapIsRotating: Bool = false

    var locationManager: CLLocationManager!

    var lineShapeLayer: CAShapeLayer!
    var circleShapeLayer: CAShapeLayer!
    var circleShapeDrawn: Bool = false
    var beacon1: CLBeacon!  // these three variables are all used by calcXY
    var beacon2: CLBeacon!  // stored globally to allow them to persist between calls
    var cgPoint: CGPoint!   // this means we can better handle loss of signal

    override func viewDidLoad() {
        super.viewDidLoad()
        compassImage.backgroundColor = UIColor.clear
        compassImage.isOpaque = true
        mapRotatingSwitch.setOn(false, animated: true)
        beaconInfo = [ BeaconInfo(value: 832, button: beaconButton1, coordinate: CGPoint(x: 412.5, y: 179.5)),
                       BeaconInfo(value: 748, button: beaconButton2, coordinate: CGPoint(x: 500.5, y: 111)),
                       BeaconInfo(value: 771, button: beaconButton3, coordinate: CGPoint(x: 482.5, y: 278.5)) ]
        let tapGesture = UILongPressGestureRecognizer(target: self,
                                                      action: #selector(ViewController.handleLongPress(_:)))
        tapGesture.minimumPressDuration = 1.2
        beaconButton1.addGestureRecognizer(tapGesture)
        beaconButton1.addGestureRecognizer(tapGesture)
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }

    func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .began { return }
        print("Long pressed")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func mapRotatingSwitchPress(_ sender: UISwitch) {
        mapIsRotating = !mapIsRotating
        if mapHeading != 0 {
            let rotation = (CGFloat(mapHeading) * CGFloat.pi) / 180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
            self.mapView.transform = rotated
            // set currentHeading to 0 so when rotation gets disabled the mapView will stay on 0
            mapHeading = 0
        }
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
            for beacon in beaconInfo {
                if beacon.value == beacons[0].minor {
                    var buttonColour: UIColor
                    let greenAmount = (255 - (CGFloat(beacons[0].accuracy) * 40))
                    buttonColour = UIColor.init(red: 0, green: CGFloat(greenAmount/255), blue: 0, alpha: 1)
                    beacon.button.backgroundColor = buttonColour
                    nearestBeacon = beacon
                } else {
                    beacon.button.backgroundColor = UIColor.red
                }

                if isNavigating {
                    if beacons[0].minor == navigatingBeacon.value && beacons[0].proximity == CLProximity.immediate {
                        // we have arrived
                        isNavigating = false
                        print("123223")
                    } else {
                        addLine(fromPoint: nearestBeacon, toPoint: navigatingBeacon)
                        updateCircle(fromPoint: nearestBeacon, toPoint: navigatingBeacon)
                    }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if mapIsRotating {
            // Hide the compass
            self.compassImage.alpha = 0

            // change in heading in degrees since last code run
            let adjustmentToRotate = (newHeading.magneticHeading - mapHeading)
            // make sure to save the heading for next code run
            mapHeading = newHeading.magneticHeading

            // change in heading in radians for some reason who decided this was ideal
            let rotation = (CGFloat(adjustmentToRotate) * CGFloat.pi) / -180
            let transform = mapView.transform
            let rotated = transform.rotated(by: rotation)
            // animate while rotating cause it looks smooth
            UIView.animate(withDuration: 0.5) {
                self.mapView.transform = rotated
            }
        } else {
            // Make compass visible again
            self.compassImage.alpha = 1

            /* Rotate the compass */
            // change in heading in degrees since last code run
            let adjustmentToRotate = (newHeading.magneticHeading - compassHeading)
            // make sure to save the heading for next code run
            compassHeading = newHeading.magneticHeading
            let rotationCompass = (CGFloat(adjustmentToRotate) * CGFloat.pi) / -180
            let transformCompass = compassImage.transform
            let rotatedCompass = transformCompass.rotated(by: rotationCompass)
            // animate while rotating cause it looks smooooooooth
            UIView.animate(withDuration: 0.5) {
                self.compassImage.transform = rotatedCompass
            }
        }
    }

    @IBAction func buttonPress(sender: UIButton) {
        if nearestBeacon != nil {
            var selectedBeacon: BeaconInfo
            switch sender {
            case beaconButton1:
                selectedBeacon = beaconInfo[0]
            case beaconButton2:
                selectedBeacon = beaconInfo[1]
            case beaconButton3:
                selectedBeacon = beaconInfo[2]
            default:
                print("Unknown button")
                return
            }
            addLine(fromPoint: nearestBeacon, toPoint: selectedBeacon)
            updateCircle(fromPoint: nearestBeacon, toPoint: selectedBeacon)
            navigatingBeacon = selectedBeacon
            isNavigating = true
        }
    }

    func addLine(fromPoint start: BeaconInfo, toPoint end: BeaconInfo) {
        print(start)
        print(end)
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
    }

    func updateCircle(fromPoint start: BeaconInfo, toPoint end: BeaconInfo) {
        if self.circleShapeDrawn {
            self.mapView.layer.sublayers?.remove(at: (self.mapView.layer.sublayers?.count)! - 2)
        }

        self.circleShapeLayer = CAShapeLayer()

        //Calculate where the circle needs to be drawn
        let circleCordinates = self.calcXY(firstBeacon: start, secondBeacon: end)
        let circlePath = UIBezierPath(arcCenter: circleCordinates, radius: CGFloat(7),
                                      startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)

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

    func calcXY(firstBeacon: BeaconInfo, secondBeacon: BeaconInfo) -> CGPoint {
        /// if theres not enough beacons return the previous point if possible
        if beaconsArray.count <= 1 && cgPoint != nil {
            return cgPoint
        } else if beaconsArray.count <= 1 {
            // if there was never a previous point return a zeroed coordinate
            return CGPoint.zero
        }

        // line style
        lineShapeLayer.strokeColor = UIColor.green.cgColor
        lineShapeLayer.lineWidth = 3
        // if we have multiple points to draw to in the future this sets the style of the corners
        lineShapeLayer.lineJoin = kCALineJoinRound

        /// find the beacons
        for beacon in beaconsArray where beacon.minor == firstBeacon.value {
            beacon1 = beacon
        }
        for beacon in beaconsArray where beacon.minor == secondBeacon.value {
            beacon2 = beacon
        }

        /// if either beacon has disappeared return the previous CGPoint if possible
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
