//
//  ViewController.swift
//  LightStop
//
//  Created by Monisha Dash on 3/15/17.
//  Copyright © 2017 sjsu. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FBSDKLoginKit
import FBSDKShareKit
import Alamofire
import Material

//MARK: HandleMapSearch Protocol
//protocol HandleMapSearch: class {
//    func dropPinZoomIn(placemark:MKPlacemark)
//}

//MARK: MapViewController Class
class MapViewController: UIViewController, MKMapViewDelegate {
    
    //MARK: - Properties
    var locationManager = CLLocationManager()
    var selectedPin: MKPlacemark?                           //search
    var resultSearchController: UISearchController?=nil
    var fbName:String?
    var email: String?
    var profile = Profile()
    let button = UIButton.init(type: .custom)
    let fbLoginManager:FBSDKLoginManager = FBSDKLoginManager()
    var dict : [String : AnyObject]!


    //MARK: - IBOutlets
    @IBOutlet weak var btnLogin: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize location manager
        self.locationManager = CLLocationManager.init()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.delegate = self
        
        //User location authorization
        let status = CLLocationManager.authorizationStatus()
        if(status == .notDetermined || status == .denied || status == .authorizedWhenInUse){
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingHeading()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode(rawValue:2)!
        mapView.setUserTrackingMode(.follow, animated: true)
        
        //search bar
        let locationSearchTable = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationSearchTable") as? LocationSearchTable
        locationSearchTable?.mapView = mapView
        
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController!.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController!.hidesNavigationBarDuringPresentation = false
        resultSearchController!.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable?.handleMapSearchDelegate = self
    }

    //MARK: - IBActions
    @IBAction func Loginbtn(_ sender: Any) {
        //let fbLoginManager:FBSDKLoginManager = FBSDKLoginManager()
        //create a new button
        //let button = UIButton.init(type: .custom)
        //set image for button
        button.setImage(UIImage(named: "fblogin.png"), for: UIControlState.normal)
        //button.setTitle("Login", for: UIControlState.normal)
        //add function for button
        button.addTarget(self, action: #selector(MapViewController.fbButtonPressed), for: UIControlEvents.touchUpInside)
        //set frame
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 31)
        
        let barButton = UIBarButtonItem(customView: button)
        //assign button to navigationbar
        self.navigationItem.rightBarButtonItem = barButton
        
        fbLoginManager.logIn(withReadPermissions: ["public_profile","email"], from: self)
        {(result,error) in
            if(error == nil)
            {
                let fbresult:FBSDKLoginManagerLoginResult = result!
                if(fbresult.grantedPermissions != nil)
                {
                    if(fbresult.grantedPermissions.contains("email"))
                    {
                        self.getUserData()
                        
                    }
                    
                }
                
            }
            
        }
    }
    
    //MARK: - Custom Methods
    func fbButtonPressed() {
        print("Share to fb")
        self.fbName = self.dict["first_name"] as? String
        if(self.fbName != "Login"){
            self.fbLoginManager.logOut()
            
        }
        
        
    }
    
    // get current Date and Time
    func getCurrentDate() -> String {
        //get current date and time
        let date = Date()
        var calendar = Calendar.current
        
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        let components = calendar.dateComponents([.month,.day,.year], from: date)
        
        print("Current Date and Time \(date)")
        return "\(components.month!)-\(components.day!)-\(components.year!)"
    }
    
    // get current Hour and Minute
    func getCurrentTime(date: Date) ->String {
        
        var calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour,.minute], from: date)
        
        //get current Time (hour and minutes)
        let currenthour = components.hour
        let currentminutes = components.minute
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        print("Current Hour: \(String(describing: currenthour)), Current Minute: \(String(describing: currentminutes))")
        
        return "\(currenthour!):\(currentminutes!)"
    }
    
    //get Facebook User Data
    func getUserData(){
        
        if((FBSDKAccessToken.current()) != nil){
            
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"id, name, first_name,last_name,picture.type(large),email"]).start(completionHandler: {(connection,result,error)->Void in
            
                if (error == nil){
                    self.dict = result as! [String : AnyObject]
                    print(result!)
                    print(self.dict)
                }
                
                self.profile.data["date"]=self.getCurrentDate()
                self.profile.data["time"] = self.getCurrentTime(date: Date())
                self.profile.data["first_name"]=self.dict["first_name"]
                self.profile.data["last_name"]=self.dict["last_name"]
                self.profile.data["name"]=self.dict["name"]
                self.profile.data["email"]=self.dict["email"]
                
                self.fbName = self.dict["first_name"] as? String
                self.button.setTitle(self.fbName, for: UIControlState.normal)
                self.button.setTitleColor(UIColor.blue, for: UIControlState.normal)
                let parameters: Parameters = self.profile.data
                
                //send data to server using Alamofire
                Alamofire.request("http://localhost:3000/api/profile", method: .post, parameters:parameters, encoding:JSONEncoding.default).responseString{
                    response in
                    print(response.request as Any)
                    print(response.response as Any)
                    print(response.data as Any)
                    print(response.result)
                    
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                    }
                }
            })
        }
    }
}

//MARK: - CLLocationManagerDelegate
extension MapViewController : CLLocationManagerDelegate {
    
    private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    private func locationManager( manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.first != nil {
            print("location:: (location)")
        }
    }
    
    private func locationManager( manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: (error)")
    }
    
}

//MARK: - HandleMapSearch Protocol
extension MapViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKMapItem){
        
        // cache the pin
        selectedPin = placemark.placemark
        // clear existing pins
        
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.placemark.coordinate
        annotation.title = placemark.name
        
        if let city = placemark.placemark.locality,
            let state = placemark.placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}

