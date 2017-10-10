/*
 * Copyright (C) 2015 - 2017, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.com>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import Material
import MapKit
import CoreLocation
import CoreMotion
import CoreData
import FBSDKLoginKit
import FBSDKShareKit
import Alamofire
import SwiftyJSON
import Speech

//MARK: HandleMapSearch Protocol
protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKMapItem)
}

class RootViewController: UIViewController, MKMapViewDelegate, FABMenuDelegate, UIPopoverPresentationControllerDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var mapView: MKMapView!

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
    internal var tableView: UserTableView!
    internal var searchBar: SearchBar?
    var locationSearchTable:LocationSearchTable?
    
    // FAB Menu
    fileprivate let fabMenuSize = CGSize(width: 56, height: 56)
    fileprivate let bottomInset: CGFloat = 24
    fileprivate let rightInset: CGFloat = 24
    fileprivate var fabButton: FABButton!
    fileprivate var fabMenu: FABMenu!
    
    // FAB Menu Items
    fileprivate var notesFABMenuItem: FABMenuItem!
    fileprivate var remindersFABMenuItem: FABMenuItem!
    
    var loggedLocation: Location?
    let lid: String? = UIDevice.current.identifierForVendor!.uuidString  //keep deviceID as location ID in database
    var latitude: String?
    var longitude: String?
    var managedObjectModel : NSManagedObjectContext?
    var appUserData = AppUserData()
    
    //  Core Data Convenience Singleton -
    var sharedContext: NSManagedObjectContext {
        //this singleton pack the Core Data Stack in a convenient method: this returns the managed object context
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //  Device properties
    var deviceId: String? = UIDevice.current.identifierForVendor!.uuidString  //deviceID
    var deviceType:String? = "iOS"
    
    //  Location Tracking Properties
    var currentLatitude: String? = nil
    var currentLongtitude: String? = nil
    var currentSpeed: String? = nil
    var currentCourse:String? = nil
    var currentLocation: CLLocation? = nil
    var loggingTime:String? = nil
    var locationHeadingTimestamp_since1970:String? = nil
    
    var startLocation: CLLocation? = nil
    var previousLocation: CLLocation!
    var timer: Timer?
    var startTrackingFlag: Bool = false // flag if Location is tracking or not
    
    var locationHeadingX:String? = nil
    var locationHeadingY:String? = nil
    var locationHeadingZ:String? = nil
    var locationHeadingAccuracy:String? = nil
    
    //  Motion Tracking Properties (Accelerometer)
    var motionManager:CMMotionManager = CMMotionManager()
    var currentAccelerometerAccelerationX:String? = nil
    var currentAccelerometerAccelerationY:String? = nil
    var currentAccelerometerAccelerationZ:String? = nil
    var currentAccelerometerTimestamp_sinceReboot: String? = nil
    
    var gyroTimestamp_sinceReboot:String? = nil
    var gyroRotationX:String? = nil
    var gyroRotationY:String? = nil
    var gyroRotationZ:String? = nil
    
    // SpeechRecoginzer properties
    private let mySpeechRecognizer =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var mySpeechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var mySpeechRecognitionTask: SFSpeechRecognitionTask?
    private let myAudioEngine = AVAudioEngine()
    var destination:MKMapItem?
    var userLocation:CLLocation?
    
    // Cards Properties
    fileprivate var card: Card!
    fileprivate var card2: Card!

    fileprivate var toolbar: Toolbar!
    fileprivate var toolbarLogin: Toolbar!
    fileprivate var moreButton: IconButton!
    
    fileprivate var contentView: UILabel!
    
    fileprivate var bottomBar: Bar!
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var dateLabel: UILabel!
    fileprivate var favoriteButton: IconButton!
    
    // Predictions
    var prediction = "0.0"
    
    let interval = 5.0
    
    //MARK: - View Life Cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare FAB Menu
        prepareFABButton()
        prepareNotesFABMenuItem()
        prepareRemindersFABMenuItem()
        prepareFABMenu()
        prepareSearchBar()
        
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
        
        // From RouteViewController
        //Print out Device Info
        print("=====================")
        print("Device Info:")
        print("=====================")
        print("Device ID: \(String(describing: deviceId))")
        print("Device Type: \(String(describing: deviceType))")
        print("Location Service is On!!!")
        
        //Start Location Service
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.requestLocation()
    }
    
    //MARK: - Custom Methods
    func fbButtonPressed() {
        print("Share to fb")
        self.fbName = self.dict["first_name"] as? String
        if(self.fbName != "Login"){
            self.fbLoginManager.logOut()
        }
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
    
    @IBAction func mapTapped(_ sender: UIButton) {
        self.searchBar?.textField.resignFirstResponder()
    }
    
}

//MARK: - CLLocationManagerDelegate
extension RootViewController : CLLocationManagerDelegate {
    
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

//MARK: - FAB Button Methods
extension RootViewController {
    fileprivate func prepareFABButton() {
        fabButton = FABButton(image: Icon.cm.add, tintColor: .white)
        fabButton.pulseColor = .white
        fabButton.backgroundColor = Color.red.base
    }
    
    fileprivate func prepareFABMenu() {
        fabMenu = FABMenu()
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [notesFABMenuItem, remindersFABMenuItem]
        fabMenu.delegate = self

        view.layout(fabMenu)
            .size(fabMenuSize)
            .bottom(bottomInset)
            .right(rightInset)
    }
    
    fileprivate func prepareNotesFABMenuItem() {
        notesFABMenuItem = FABMenuItem()
        notesFABMenuItem.title = "Login"
        notesFABMenuItem.fabButton.image = Icon.cm.pen
        notesFABMenuItem.fabButton.tintColor = .white
        notesFABMenuItem.fabButton.pulseColor = .white
        notesFABMenuItem.fabButton.backgroundColor = Color.green.base
        notesFABMenuItem.fabButton.addTarget(self, action: #selector(handleNotesFABMenuItem(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareRemindersFABMenuItem() {
        remindersFABMenuItem = FABMenuItem()
        remindersFABMenuItem.title = "Predictions"
        remindersFABMenuItem.fabButton.image = Icon.cm.bell
        remindersFABMenuItem.fabButton.tintColor = .white
        remindersFABMenuItem.fabButton.pulseColor = .white
        remindersFABMenuItem.fabButton.backgroundColor = Color.blue.base
        remindersFABMenuItem.fabButton.addTarget(self, action: #selector(handlePredictionsFABMenuItem(button:)), for: .touchUpInside)

    }
}

extension RootViewController {
    @objc
    fileprivate func handleNotesFABMenuItem(button: UIButton) {
        //transition(to: LoginViewController())
        //let fbLoginManager:FBSDKLoginManager = FBSDKLoginManager()
        //create a new button
        //let button = UIButton.init(type: .custom)
        //set image for button
//        button.setImage(UIImage(named: "fblogin.png"), for: UIControlState.normal)
//        //button.setTitle("Login", for: UIControlState.normal)
//        //add function for button
//        button.addTarget(self, action: #selector(MapViewController.fbButtonPressed), for: UIControlEvents.touchUpInside)
//        //set frame
//        button.frame = CGRect(x: 0, y: 0, width: 100, height: 31)
//        
//        let barButton = UIBarButtonItem(customView: button)
//        //assign button to navigationbar
//        self.navigationItem.rightBarButtonItem = barButton
        
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
                        // Show Prediction Card
                        // Prepare Cards
                        self.prepareDateFormatter()
                        self.prepareToolbarLogin()
                        self.prepareImageCardLogin()
                    }
                    
                }
                
            }
            
        }

        fabMenu.close()
        fabMenu.fabButton?.animate(Motion.rotation(angle: 0))
    }
    
    @objc
    fileprivate func handlePredictionsFABMenuItem(button: UIButton) {
        //transition(to: LoginViewController())
        fabMenu.close()
        fabMenu.fabButton?.animate(Motion.rotation(angle: 0))
        
        // Handle sending request for Prediction
        getPrediction()
        // Handle getting response for Predictoins
        
        // Add Materials Card
    }
}

extension RootViewController {
    @objc
    open func fabMenuWillOpen(fabMenu: FABMenu) {
        fabMenu.fabButton?.animate(Motion.rotation(angle: 45))

        print("fabMenuWillOpen")
    }
    
    @objc
    open func fabMenuDidOpen(fabMenu: FABMenu) {
        print("fabMenuDidOpen")
    }
    
    @objc
    open func fabMenuWillClose(fabMenu: FABMenu) {
        fabMenu.fabButton?.animate(Motion.rotation(angle: 0))

        print("fabMenuWillClose")
    }
    
    @objc
    open func fabMenuDidClose(fabMenu: FABMenu) {
        print("fabMenuDidClose")
    }
    
    @objc
    open func fabMenu(fabMenu: FABMenu, tappedAt point: CGPoint, isOutside: Bool) {
        print("fabMenuTappedAtPointIsOutside", point, isOutside)
        
        guard isOutside else {
            return
        }
        
        // Do something ...
    }
}

//MARK: - SearchBar Delegate
extension RootViewController: SearchBarDelegate {
    internal func prepareSearchBar() {
        // Access the searchBar.
        guard let searchBar = searchBarController?.searchBar else {
            return
        }
        self.searchBar = searchBar
        self.searchBar?.delegate = self
        self.searchBar?.placeholder = "Search for Places..."
        
        //search bar
        self.locationSearchTable = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LocationSearchTable") as? LocationSearchTable
        self.locationSearchTable?.mapView = mapView
        self.tableView = self.locationSearchTable!.tableView as! UserTableView

    }
    
    func searchBar(searchBar: SearchBar, didClear textField: UITextField, with text: String?) {
        tableView.removeFromSuperview()
        //self.searchBar?.textField.resignFirstResponder()
    }
    
    func searchBar(searchBar: SearchBar, didChange textField: UITextField, with text: String?) {
        view.layout(tableView).edges()
        
        
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController!.searchResultsUpdater = locationSearchTable
        definesPresentationContext = true
        locationSearchTable?.handleMapSearchDelegate = self
        
        guard   let mapView = mapView,
            let searchBarText = text
            else {return}
        
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.locationSearchTable?.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

//MARK: - HandleMapSearch Protocol
extension RootViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKMapItem){
        self.searchBar?.textField.text = placemark.placemark.title
        
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
        
        tableView.removeFromSuperview()
        self.searchBar?.textField.resignFirstResponder()
        
        self.destination = placemark
        // get direction of the route and print the navigation instruction
        getDirections()
    }
}

//MARK: - RouteViewControllers Methods
extension RootViewController {
    
    // Method to get direction and show route from current location to destination and
    // collect location data periodically
    func getDirections() {
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination!
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            
            if error != nil {
                print("Error getting directions")
            } else {
                if let response = response {
                    self.showRoute(response: response)
                    
                    //start updating location
                    self.locationManager.startUpdatingLocation()
                    
                    //start timer to collect data periodically
                    print("Update Location Starting...")
                    self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(RouteViewController.getDataTimer), userInfo: nil, repeats: true)
                }
            }
        }
        
        print("Acceleration : \(String(describing: currentAccelerometerAccelerationX)), \(String(describing: currentAccelerometerAccelerationY)), \(String(describing: currentAccelerometerAccelerationZ))")
        print("Gyroscope : \(String(describing: gyroRotationX)), \(String(describing: gyroRotationY)), \(String(describing: gyroRotationZ))")
    }
    
    //MARK: - Location Methods -
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //userLocation = locations[0]
        
        //Get user initial current location
        getUserCurrentLocaiton(locations: locations)
        
        //Get user current speed
        let currentSpeed = manager.location?.speed
        print("User Current Speed ==> ", currentSpeed ?? String())
        
        // get direction of the route and print the navigation instruction
        // self.getDirections()
        
        //TESTING : get data from nodejs sever
        print("TESTING: Post data from Nodejs server!")
        if(currentAccelerometerAccelerationX != nil){
            self.postDataToServer()
            
        }else {
            assignAccelerometerDataToZero()
            assignGyroDataToZero()
            postDataToServer()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    // Method to Get initial users' current location data
    func getUserCurrentLocaiton(locations: [CLLocation]){
        //location value to save in DB periodically
        currentLocation = locations.last!
        
        // location values for app procedures
        let newLocation: CLLocation = locations.last!
        // let oldLocation: CLLocation = locations.first!
        
        currentLatitude = String(format: "%+.6f", newLocation.coordinate.latitude)
        currentLongtitude = String(format: "%+.6f", newLocation.coordinate.longitude)
        
        if(startLocation == nil){
            startLocation = newLocation
        }
        // print("Current Initial Location:  \(currentLatitude) , \(currentLongtitude) ")
    }
    
    //Method to get location value and save periodically
    func getDataTimer() {
        self.locationManager.requestLocation()
        let locationTime = getCurrentTime(date:Date())
        //Get user information
        let currentTime:String = getCurrentTime(date:Date())
        let currentDate:String = getCurrentDate()
        loggingTime = "Date: " + currentDate + " " + "Time: " + currentTime
        
        print("TESTING for CM Motion")
        self.startAccelerometers()
        getDeviceMotionData()
        getGyroscopeData()
        
        print("Location Data:")
        print("Current Latitude: \(String(describing: currentLocation?.coordinate.latitude))")
        print("Current Longitude: \(String(describing: currentLocation?.coordinate.longitude))")
        print("Logging time: \(String(describing: loggingTime))")
        //print("Location Time: \(locationTime)")
        
        print("Current time of current Location \(locationTime)")
        //get lat/lng value and date time here
        print("Current Location saving in DB...")
        
        saveLocationToCoreData(String(describing: currentLocation?.coordinate.latitude), longitude: String(describing: currentLocation?.coordinate.longitude))
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
    // return current date and time
    func getCurrentTime(date: Date) ->String {
        
        var calendar = Calendar.current
        
        let components = calendar.dateComponents([.hour,.minute], from: date)
        
        //get current Time (hour and minutes)
        let currenthour = components.hour
        let currentminutes = components.minute
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        //print("Current Hour: \(currenthour), Current Minute: \(currentminutes)")
        print("Current Hour: \(String(describing: currenthour)), Current Minute: \(String(describing: currentminutes))")
        
//        return "\(date), \(currenthour!):\(currentminutes!)"
        return "\(currenthour!):\(currentminutes!)"

    }
    
    // Method to show the route
    func showRoute(response: MKDirectionsResponse) {
        
        for route in response.routes {
            mapView.add(route.polyline,level: MKOverlayLevel.aboveRoads)
            
            for step in route.steps {
                print(step.instructions)
            }
        }
        guard (currentLocation != nil) else {print("exiting"); return}
        let region = MKCoordinateRegionMakeWithDistance(currentLocation!.coordinate,2000, 2000)
        
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: - Collect Sensor Data -
    
    // get Acceleration data
    func startAccelerometers(){
        //check if Accelerometer is available
        if self.motionManager.isAccelerometerAvailable {
            self.motionManager.accelerometerUpdateInterval = self.interval  //60.Hz
            self.motionManager.startAccelerometerUpdates()
            
            //configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: self.interval , repeats: true, block: {_ in
                (self.timer)?.invalidate()
                //Get the accelerometer data
                if let data = self.motionManager.accelerometerData{
                    self.currentAccelerometerAccelerationX = String(describing:data.acceleration.x)
                    self.currentAccelerometerAccelerationY = String(describing:data.acceleration.y)
                    self.currentAccelerometerAccelerationZ = String(describing:data.acceleration.z)
                } else {
                    self.assignAccelerometerDataToZero()
                }
            })
            
            let accelerometerCollectTime = self.getCurrentTime(date: Date())
            print("Accelerometer Data Collection Time \(accelerometerCollectTime)")
            //print("Accelerometer X = \(self.motionManager.accelerometerData?.acceleration.x)")
        }
        
        //Add the timer to the current loop
        //RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
        //print("Accelerometer X = \(self.currentAccelerometerAccelerationX)")
    }
    
    //get Device Motion Data
    func getDeviceMotionData() {
        //check if the device motion sensor is available
        print(self.motionManager.isDeviceMotionAvailable)
        if self.motionManager.isDeviceMotionAvailable{
            self.motionManager.deviceMotionUpdateInterval = self.interval  //60Hz
            self.motionManager.startDeviceMotionUpdates(to: .main) {
                [weak self] (data: CMDeviceMotion?, error: Error?) in
                if let x = data?.userAcceleration.x,
                    x < -2.5 {
                    self?.navigationController?.popViewController(animated: true)
                }
                
                print("Device Motion \(String(describing: data?.userAcceleration.x))")
                //Gyro Data
                print("Device Rotation \(String(describing: data?.rotationRate.x)) \(String(describing: data?.rotationRate.y)) \(String(describing: data?.rotationRate.z))")
            }
        }
    }
    
    //Adding GyroData
    func getGyroscopeData() {
        //check if the Gyroscop sensor is available
        print(self.motionManager.isGyroAvailable)
        if self.motionManager.isGyroAvailable{
            self.motionManager.deviceMotionUpdateInterval = self.interval  //60Hz
            self.motionManager.startDeviceMotionUpdates()
            
            self.motionManager.startGyroUpdates(to: .main) {
                [weak self] (gyroData: CMGyroData?, error: Error?) in
                //self?.outputRotationData(gyroData?.rotationRate)
                if ((error) != nil) {
                    print("\(String(describing: error))")
                }
                else {
                    if ((gyroData?.rotationRate) != nil) {
                        self?.gyroRotationX = String(format: "%.4f",(gyroData?.rotationRate.x)!)
                        self?.gyroRotationY = String(format: "%.4f",(gyroData?.rotationRate.y)!)
                        self?.gyroRotationZ = String(format: "%.4f",(gyroData?.rotationRate.z)!)
                        
                    } else {
                        self?.assignGyroDataToZero()
                    }
                    
                }
            }
            let gyroDataTime = self.getCurrentTime(date: Date())
            print("Time of Gyro Data Collection: \(gyroDataTime)")
            print("GyroRotation X \(String(describing: gyroRotationX))")
        }
    }
    
    //Assign GyroData to Zero if GyroData is Nil (for error handling)
    func assignGyroDataToZero(){
        self.gyroRotationX = "0"
        self.gyroRotationY = "0"
        self.gyroRotationZ = "0"
    }
    
    //Assign AccelerometerData to zero if Accelerometer Data is Nil (for error Handling)
    func assignAccelerometerDataToZero(){
        self.currentAccelerometerAccelerationX = "0"
        self.currentAccelerometerAccelerationY = "0"
        self.currentAccelerometerAccelerationZ = "0"
    }
    
    //MapView setup
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 5.0
        return renderer
    }
    
    //Save location data to CoreData
    fileprivate func saveLocationToCoreData(_ latitude:String, longitude:String){
        
        //Save location value in Local Database - Construct Dictionary for new location
        let newLocationDictionary: [String: String] = [
            Location.Keys.Lid : lid!,
            Location.Keys.Latitude: latitude,
            Location.Keys.Longitude: longitude
        ]
        
        //We create a new location in local database and assign to property
        //This is done to be able to pass the location to other view controller
        self.loggedLocation = Location(dictionary: newLocationDictionary as [String: AnyObject], context: self.sharedContext)
        
        //Save added or modified data to MySQL database
        CoreDataStackManager.sharedInstance().saveContext()
        print("========> Saved Location Data in CoreData!!!!!!")
        return
    }
    
    //MARK: - ALAMOFIRE SET UP -
    
    //Save data (user+Location) to NodeJS server
    func postDataToServer(){
        var endpoint:String?
        
        endpoint="http://34.208.35.110:3000/api/devicedata"
        //  endpoint = "http://localhost:3000"
        self.locationManager.requestLocation()
        
        //get lat/lng value and date time here
        print("Current Location saving in DB.. \(String(describing: currentLocation))")
        
        //save those data to DB here
        print("Saving Data in MongoDB...")
        
        //Prepare parameters to send to Server
        prepareParameters()
        
        let parameters: Parameters = appUserData.data
        
        //Send data to Server using Alamofire
        Alamofire.request(endpoint!, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseString{ response in
            print("Response Request ==> \(String(describing: response.request))")   // original URL Request
            print("Response Response ==> \(String(describing: response.response))") // HTTP URL response
            print("Response Data==> \(String(describing: response.data))")          // server data
            print("Response Result==> \(response.result)")      // result of response serialization
            
            //print(response.result.value!)
            print(response.data!)
            
            if(response.response?.statusCode == 200){
                print("Success to send data. Status code: \(String(describing: response.response?.statusCode))")
                if let JSON = response.result.value {
                    
                    print("JSON: \(JSON)")
                    self.appUserData.data["comment"] = ""
                }
                
            } else {
                print("Failed to send data to server. Status Code: \(String(describing: response.response?.statusCode))")
            }
        }
        
        //print("TEST===> Get Data from Server")
        //self.getDataFromServer(user: "Carlos")
    }
    
    //prepare the parameters to post
    func prepareParameters(){
        appUserData.data["deviceID"] = deviceId
        appUserData.data["loggingTime"] = loggingTime
        appUserData.data["locationLatitude"] = currentLocation!.coordinate.latitude
        appUserData.data["locationLongitude"] = currentLocation!.coordinate.longitude
        appUserData.data["locationSpeed"] = currentLocation!.speed
        appUserData.data["locationCourse"] = currentLocation!.course
        appUserData.data["accelerometerAccelerationX"] = currentAccelerometerAccelerationX!
        appUserData.data["accelerometerAccelerationY"] = currentAccelerometerAccelerationY!
        appUserData.data["accelerometerAccelerationZ"] = currentAccelerometerAccelerationZ!
        appUserData.data["gyroTimestamp_sinceReboot"] = "1488880954.000009"  // Hardcoded data
        appUserData.data["gyroRotationX"] = gyroRotationX == nil ? "0.0": gyroRotationX
        appUserData.data["gyroRotationY"] = gyroRotationY == nil ? "0.0": gyroRotationY
        appUserData.data["gyroRotationZ"] = gyroRotationZ == nil ? "0.0": gyroRotationZ
    }
    
    //MARK: Test: Get data from Node.js server
    func getDataFromServer(user:String){
        var endpoint:String?
        endpoint="http://54.67.97.22:3000/api/devicedata"
        
        //Get data from Server using Alamofire
        Alamofire.request(endpoint!, method:.get, encoding: JSONEncoding.default).responseJSON {
            response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print("JSON: \(json)")
                var userList = ""
                let comma = ","
                
                for i in json {
                    if i.1["value"] > 0 {
                        if userList == "" {
                            userList = "\(i.1["_id"].stringValue)"
                        } else {
                            userList = userList + "\(comma) \(i.1["_id"].stringValue)"
                        }
                    }
                }
                self.showServerResponseData(userList:userList)
                print("User List: \(userList)")
                
            case .failure(let error):
                print(error)
                print("Failed Get Data from Server")
            }
        }
    }
    
    //Get Prediction Request from Server
    func getPrediction() {
        var endpoint:String?
        
        //url for getting prediction
        endpoint="http://34.208.35.110:3000/api/prediction"
        var newdata = appUserData.getRandomUserData()
        let parameters: Parameters = newdata
        
        //Send data to Server using Alamofire
        Alamofire.request(endpoint!, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            print("Response Request ==> \(String(describing: response.request))")   // original URL Request
            print("Response Response ==> \(String(describing: response.response))") // HTTP URL response
            print("Response Data==> \(String(describing: response.data))")          // server data
            print("Response Result==> \(response.result)")      // result of response serialization
            
            //print(response.result.value!)
            print(response.data!)
            
            if(response.response?.statusCode == 200){
                print("Success to send prediction request. Status code: \(String(describing: response.response?.statusCode))")
                if let result = response.result.value {
                    
                    let JSON = result as! NSDictionary
                    print(JSON)
                    print("Prediction: \(String(describing: JSON["message"]))")
                    self.prediction = JSON["message"] as! String
                    
                    // Show Prediction Card
                    // Prepare Cards
                    self.prepareDateFormatter()
                    self.prepareDateLabel()
                    self.prepareFavoriteButton()
                    self.prepareMoreButton()
                    self.prepareToolbar()
                    self.prepareContentView(message: self.prediction)
                    self.prepareBottomBar()
                    self.prepareImageCard()

                    // DO SOMETHING ABOUT RESULT
//                    self.performSegue(withIdentifier: "predictionPopOver", sender: self)
//                    self.appUserData.data["comment"] = ""
                }
            } else {
                print("Failed to send data to server. Status Code: \(String(describing: response.response?.statusCode))")
            }
        }
        
//        //Testing
//        print("POPOVER TESTING")
//        self.performSegue(withIdentifier: "predictionPopOver", sender: self)
//        print("PREDICTION RESULT IS READY")
    }
    
    //MARK: - Navigation -
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "predictionPopOver"{
            let destination = segue.destination
            destination.preferredContentSize = CGSize(width: 100, height: 100)
            if let predictionPopOver = destination.popoverPresentationController {
                predictionPopOver.delegate = self
                predictionPopOver.sourceView = self.view
                predictionPopOver.sourceRect = CGRect(x:self.view.bounds.midX, y: self.view.bounds.midY,width: 315,height: 230)
                predictionPopOver.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
            }
        }
    }
    
    private func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle: UIModalPresentationStyle){
        return
    }
    
    func showServerResponseData(userList:String){
        
        //Alert Controller
        let alertController =  UIAlertController(title: "NodeJs Server Data Results", message: "Users datapoints: \(userList)", preferredStyle: .alert)
        
        // Alert Actions (1)
        let cancelAction = UIAlertAction(title: "Done", style: .cancel) { (action) in
            print(action)
        }
        
        //Add Alerts to Alert Controller
        alertController.addAction(cancelAction)
        
        //Present Alert
        present(alertController, animated: true) {
            print("Alert View for User Name was presented")
        }
    }
    
    //Method to show the request alert
    func predictionRequestAlert(){
        let alert = UIAlertController(title: "Prediction Request", message: "Recording..", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title:"Send", style: .default, handler: {(action:UIAlertAction!) in  self.getPrediction()}))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {(action:UIAlertAction!) in print("you have pressed the Cancel button")}))
        self.present(alert, animated: true, completion: nil)
    }
}

//MARK: - CLLocationManager Delegate -
extension RouteViewController : CLLocationManagerDelegate {
    
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

//MARK: - CARD Methods -
extension RootViewController {
    fileprivate func prepareDateFormatter() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }
    
    fileprivate func prepareDateLabel() {
        dateLabel = UILabel()
        dateLabel.font = RobotoFont.regular(with: 12)
        dateLabel.textColor = Color.grey.base
        dateLabel.text = dateFormatter.string(from: Date())
    }
    
    fileprivate func prepareFavoriteButton() {
        favoriteButton = IconButton(image: Icon.favorite, tintColor: Color.red.base)
    }
    
    fileprivate func prepareMoreButton() {
        moreButton = IconButton(image: Icon.cm.moreVertical, tintColor: Color.grey.base)
    }
    
    fileprivate func prepareToolbar() {
        toolbar = Toolbar(rightViews: [moreButton])
        
        toolbar.title = "PREDICTION"
        toolbar.titleLabel.textAlignment = .left
        
        toolbar.detail = "Machine Learning Neural Networks"
        toolbar.detailLabel.textAlignment = .left
        toolbar.detailLabel.textColor = Color.grey.base
    }
    
    fileprivate func prepareToolbarLogin() {
        toolbarLogin = Toolbar()
        toolbarLogin.title = "Carlos"
        toolbarLogin.titleLabel.textAlignment = .center
    }
    
    fileprivate func prepareContentView(message:String) {
        contentView = UILabel()
        contentView.numberOfLines = 0
        contentView.text = "Vehicle Speed:  \(message)"
        contentView.font = RobotoFont.regular(with: 20)
    }
    
    fileprivate func prepareBottomBar() {
        bottomBar = Bar()
        
        bottomBar.leftViews = [favoriteButton]
        bottomBar.rightViews = [dateLabel]
    }
    
    fileprivate func prepareImageCard() {
        card = Card()
        
        card.toolbar = toolbar
        card.toolbarEdgeInsetsPreset = .square3
        card.toolbarEdgeInsets.bottom = 8
        card.toolbarEdgeInsets.right = 16
        
        card.contentView = contentView
        card.contentViewEdgeInsetsPreset = .wideRectangle3
        
        card.bottomBar = bottomBar
        card.bottomBarEdgeInsetsPreset = .wideRectangle2
        
        // Add Swipe Gesture Recongnizer
        
        // Recognizer
        let swipeRec = UISwipeGestureRecognizer()
        swipeRec.addTarget(self, action: "swipedCard")
        
        // View
        card.addGestureRecognizer(swipeRec)
        card.isUserInteractionEnabled = true

        
        view.layout(card).horizontally(left: 20, right: 20).center()
    }
    
    fileprivate func prepareImageCardLogin() {
        card2 = Card()
        
        card2.toolbar = toolbarLogin
        card2.toolbarEdgeInsetsPreset = .square3
        card2.toolbarEdgeInsets.bottom = 8
        card2.toolbarEdgeInsets.right = 16
        
        card2.contentView = contentView
        card2.contentViewEdgeInsetsPreset = .wideRectangle3
        
        card2.bottomBar = bottomBar
        card2.bottomBarEdgeInsetsPreset = .wideRectangle2
        
        view.layout(card2).horizontally(left: 20, right: 250)
        view.layout(card2).vertically(top: 50, bottom: 550)
        
    }
    
    func swipedCard(){
        card.removeFromSuperview()
    }
}
