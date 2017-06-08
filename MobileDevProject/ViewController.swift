//
//  ViewController.swift
//  MobileDevProject
//
//  Created by Alexander van den Herik; Daniel Wilson; Leendert Eloff; Tri Tran
//  Copyright © 2017 Alexander van den Herik. All rights reserved.
//

import CoreLocation
import AudioToolbox
import UIKit
import XLActionController

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

    // these three variables are all used by calcXY
    // stored globally to allow them to persist between calls
    // this means we can better handle loss of signal
    var tempBeacon1: CLBeacon! //beacon to temporarily store a beacon from the beacons array to get the accuracy
    var tempBeacon2: CLBeacon!
    var circleCordinates: CGPoint! //the x and y cordinates where the circle(location indicator) needs to be drawn
    var lastScale: CGFloat!
    var lastPoint: CGPoint!

    override func viewDidLoad() {
        super.viewDidLoad()
        compassImage.backgroundColor = UIColor.clear
        compassImage.isOpaque = true
        mapRotatingSwitch.setOn(false, animated: true)
        beaconInfo = [ BeaconInfo(value: 832, button: beaconButton1, coordinate: CGPoint(x: 412.5, y: 179.5)),
                       BeaconInfo(value: 748, button: beaconButton2, coordinate: CGPoint(x: 500.5, y: 111)),
                       BeaconInfo(value: 771, button: beaconButton3, coordinate: CGPoint(x: 482.5, y: 278.5)) ]
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        self.mapView.addGestureRecognizer(pinchGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func handlePinch(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            lastScale = 1.0
            self.lastPoint = sender.location(in: mapView)
        }
        if sender.numberOfTouches > 1 {
            let point: CGPoint = sender.location(in: mapView)
            let scale: CGFloat = 1.0 - (lastScale - sender.scale)
            mapView.transform = mapView.transform.scaledBy(x: scale, y: scale)
            mapView.transform = mapView.transform.translatedBy(x: point.x - lastPoint.x, y: point.y - lastPoint.y)
            lastScale = sender.scale
            lastPoint = sender.location(in: mapView)
        }
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
            var count: Int = 0
            for beacon in beaconInfo {
                var buttonColour: UIColor
                var colourAmount: CGFloat = 255
                if count < beacons.count { /// Prevent index out of bounds
                    colourAmount = (255 - (CGFloat(beacons[count].accuracy) * 40))
                }
                count += 1
                if beacon.value == beacons[0].minor {
                    buttonColour = UIColor.init(red: 0, green: CGFloat(colourAmount/255), blue: 0, alpha: 1)
                    beacon.button.backgroundColor = buttonColour
                    nearestBeacon = beacon
                } else {
                    buttonColour = UIColor.init(red: CGFloat(colourAmount/255), green: 0, blue: 0, alpha: 1)
                    beacon.button.backgroundColor = buttonColour
                }

                if isNavigating {
                    if beacons[0].minor == navigatingBeacon.value && beacons[0].proximity == CLProximity.near {
                        // we have arrived
                        isNavigating = false
                        // vibrate
                        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

                        // show alert
                        let alertController = UIAlertController(title: "Room Finder", message:
                            "You have arrived!", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default))
                        self.present(alertController, animated: true, completion: nil)

                        // clear circle and line
                        self.lineShapeLayer.removeFromSuperlayer()
                        self.circleShapeLayer.removeFromSuperlayer()
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
        let actionController = RoomActionController()
        switch sender {
            case beaconButton1:
                navigatingBeacon = beaconInfo[0]
                actionController.headerData = RoomHeaderData(name: "Meeting Rooms",
                    availability: "Available", capacity: "Capacity: 15 people", area: "Area: 20m2")
                actionController.addAction(Action(ActionData(title: "Show Direction",
                        image:UIImage(named: "back-arrow")!),
                        style: .default,
                        handler: { _ in
                            self.startNavigating()
                        }
                ))
                present(actionController, animated: true, completion: nil)
            case beaconButton2:
                navigatingBeacon = beaconInfo[1]
                actionController.headerData = RoomHeaderData(name: "Kitchen",
                    availability: "Busy", capacity: "Capacity: 20 people", area: "Area: 30m2")
                actionController.addAction(Action(ActionData(title: "Show Direction",
                        image:UIImage(named: "back-arrow")!),
                        style: .default,
                        handler: { _ in
                            self.startNavigating()
                        }
                ))
                present(actionController, animated: true, completion: nil)
            case beaconButton3:
                navigatingBeacon = beaconInfo[2]
                actionController.headerData = RoomHeaderData(name: "Office Rooms",
                    availability: "Available", capacity: "Capacity: 10 people", area: "Area: 15m2")
                actionController.addAction(Action(ActionData(title: "Show Direction",
                    image:UIImage(named: "back-arrow")!),
                    style: .default,
                    handler: { _ in
                        self.startNavigating()
                    }
                ))
                present(actionController, animated: true, completion: nil)
            default:
                print("Unknown button")
                return
        }
    }

    func startNavigating() {
        if self.nearestBeacon != nil {
            self.addLine(fromPoint: self.nearestBeacon, toPoint: self.navigatingBeacon)
            self.updateCircle(fromPoint: self.nearestBeacon, toPoint: self.navigatingBeacon)
            self.isNavigating = true
        }
    }

    func addLine(fromPoint start: BeaconInfo, toPoint end: BeaconInfo) {
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
        if self.self.circleShapeLayer != nil {
            self.self.circleShapeLayer.removeFromSuperlayer()
        } else {
            self.self.circleShapeLayer = CAShapeLayer()
        }

        //Calculate where the circle needs to be drawn
        let circleCordinates = self.calcXY(firstBeacon: start, secondBeacon: end)
        let circlePath = UIBezierPath(arcCenter: circleCordinates, radius: CGFloat(7),
                                      startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)

        self.circleShapeLayer.path = circlePath.cgPath
        //change the fill color
        self.circleShapeLayer.fillColor = UIColor.init(red:0.26, green:0.52, blue:0.96, alpha:1.0).cgColor
        //you can change the stroke color
        self.circleShapeLayer.strokeColor = UIColor.white.cgColor
        //you can change the line width
        self.circleShapeLayer.lineWidth = 3.0

        //Add circle to the layer
        self.mapView.layer.addSublayer(self.circleShapeLayer)
    }

    func calcXY(firstBeacon: BeaconInfo, secondBeacon: BeaconInfo) -> CGPoint {
        // if theres not enough beacons return the previous point if possible
        // else the new cordinates can not be calculated
        if beaconsArray.count <= 1 && circleCordinates != nil {
            return circleCordinates
        } else if beaconsArray.count <= 1 {
            // if there was never a previous point return a zeroed coordinate
            return CGPoint.zero
        }

        // line style
        lineShapeLayer.strokeColor = UIColor.init(red:0.00, green:0.70, blue:0.99, alpha:1.0).cgColor
        lineShapeLayer.lineWidth = 3
        // if we have multiple points to draw to in the future this sets the style of the corners
        lineShapeLayer.lineJoin = kCALineJoinRound

        /// find the beacons
        for beacon in beaconsArray where beacon.minor == firstBeacon.value {
            tempBeacon1 = beacon
        }
        for beacon in beaconsArray where beacon.minor == secondBeacon.value {
            tempBeacon2 = beacon
        }

        /// if either beacon has disappeared return the previous CGPoint if possible
        if (tempBeacon1 == nil || tempBeacon2 == nil) && circleCordinates != nil {
            return circleCordinates
        }
        if (tempBeacon1.accuracy == -1 || tempBeacon2.accuracy == -1) && circleCordinates != nil {
            return circleCordinates
        }

        let distance = CGFloat(tempBeacon1.accuracy/(tempBeacon1.accuracy + tempBeacon2.accuracy))
        let x = ((secondBeacon.coordinate.x - firstBeacon.coordinate.x)*distance + firstBeacon.coordinate.x)
        let y = ((secondBeacon.coordinate.y - firstBeacon.coordinate.y)*distance + firstBeacon.coordinate.y)
        circleCordinates = CGPoint.init(x: x, y: y)

        return circleCordinates
    }
}
