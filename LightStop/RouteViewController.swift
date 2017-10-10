//
//  RouteViewController.swift
//  LightStop
//
//  Created by Monisha Dash on 3/17/17.
//  Copyright © 2017 sjsu. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation
import CoreMotion
import Alamofire
import SwiftyJSON
import LiquidFloatingActionButton
import Speech

class RouteViewController: UIViewController, MKMapViewDelegate, SFSpeechRecognizerDelegate, UIPopoverPresentationControllerDelegate{
    
    //MARK: - Properties
    var loggedLocation: Location?
    let lid: String? = UIDevice.current.identifierForVendor!.uuidString  //keep deviceID as location ID in database
    var latitude: String?
    var longitude: String?
    var managedObjectModel : NSManagedObjectContext?
    var appUserData = AppUserData()
    
    //Core Data Convenience Singleton -
    var sharedContext: NSManagedObjectContext {
        //this singleton pack the Core Data Stack in a convenient method: this returns the managed object context
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    //Device properties
    var deviceId: String? = UIDevice.current.identifierForVendor!.uuidString  //deviceID
    var deviceType:String? = "iOS"
    
    //Location Tracking Properties
    var locationManager = CLLocationManager()
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
    
    //Motion Tracking Properties (Accelerometer)
    var motionManager:CMMotionManager = CMMotionManager()
    var currentAccelerometerAccelerationX:String? = nil
    var currentAccelerometerAccelerationY:String? = nil
    var currentAccelerometerAccelerationZ:String? = nil
    var currentAccelerometerTimestamp_sinceReboot: String? = nil
    
    var gyroTimestamp_sinceReboot:String? = nil
    var gyroRotationX:String? = nil
    var gyroRotationY:String? = nil
    var gyroRotationZ:String? = nil
    
    //Floating Button properties
    var cells = [LiquidFloatingCell]()
    //var cells = [LiquidFloatingActionButton]() // datasource
    var floatingActionButton: LiquidFloatingActionButton!
    
    //SpeechRecoginzer properties
    private let mySpeechRecognizer =  SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var mySpeechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var mySpeechRecognitionTask: SFSpeechRecognitionTask?
    private let myAudioEngine = AVAudioEngine()
    
    //MARK: - IBOutlets SpeechRecoginzer
    @IBOutlet weak var routeMap: MKMapView!
    
    var destination:MKMapItem?
    
    //    var locationManager: CLLocationManager = CLLocationManager()
    var userLocation:CLLocation?
    
    //MARK: - App LifeCycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mySpeechRecognizer?.delegate = self
        
        // Creating Floating Button
        createFloatingButtons()
        
        //        //Siri Authorization
        //        INPreferences.requestSiriAuthorization({status in
        //            // Handle errors here
        //        })
        
        //Print out Device Info
        print("=====================")
        print("Device Info:")
        print("=====================")
        print("Device ID: \(String(describing: deviceId))")
        print("Device Type: \(String(describing: deviceType))")
        print("Location Service is On!!!")
        
        //Start Location Service
        routeMap.delegate = self
        routeMap.showsUserLocation = true
        routeMap.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.requestLocation()
        
        // get direction of the route and print the navigation instruction
        getDirections()
        
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
        
        //print("Current Date and Time \(date)")
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
        
        return "\(date), \(currenthour!):\(currentminutes!)"
    }
    
    // Method to show the route
    func showRoute(_ response: MKDirectionsResponse) {
        
        for route in response.routes {
            routeMap.add(route.polyline,level: MKOverlayLevel.aboveRoads)
            
            for step in route.steps {
                print(step.instructions)
            }
        }
        guard (currentLocation != nil) else {print("exiting"); return}
        let region = MKCoordinateRegionMakeWithDistance(currentLocation!.coordinate,2000, 2000)
        
        routeMap.setRegion(region, animated: true)
    }
    
    //MARK: - Collect Sensor Data -
    
    // get Acceleration data
    func startAccelerometers(){
        //check if Accelerometer is available
        if self.motionManager.isAccelerometerAvailable {
            self.motionManager.accelerometerUpdateInterval = 1.0/60.0  //60.Hz
            self.motionManager.startAccelerometerUpdates()
            
            //configure a timer to fetch the data.
            self.timer = Timer(fire: Date(), interval: (1.0/60.0), repeats: true, block: {_ in
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
            self.motionManager.deviceMotionUpdateInterval = 1.0/60.0  //60Hz
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
            self.motionManager.deviceMotionUpdateInterval = 1.0/60.0  //60Hz
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
        appUserData.data["gyroRotationX"] = gyroRotationX
        appUserData.data["gyroRotationY"] = gyroRotationY
        appUserData.data["gyroRotationZ"] = gyroRotationZ
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
        
        let parameters: Parameters = appUserData.data
        
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
                    
                    // DO SOMETHING ABOUT RESULT
                    self.performSegue(withIdentifier: "predictionPopOver", sender: self)
                    self.appUserData.data["comment"] = ""
                }
            } else {
                print("Failed to send data to server. Status Code: \(String(describing: response.response?.statusCode))")
            }
        }
        
        //Testing
        print("POPOVER TESTING")
        self.performSegue(withIdentifier: "predictionPopOver", sender: self)
        print("PREDICTION RESULT IS READY")
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
    
    //Method to creat floating button
    func createFloatingButtons(){
        cells.append(createButtonCell(iconName: "ic_future"))
        print("Buttons with images are added.");
        
        let floatingFrame = CGRect(x: self.view.frame.width - 56 - 16, y: self.view.frame.height - 56 - 16, width: 56, height: 56)
        let floatingButton = createButton(frame: floatingFrame,style: .up)
        self.view.addSubview(floatingButton)
        
        self.floatingActionButton = floatingButton
    }
    
    func createButtonCell(iconName: String) -> LiquidFloatingCell{
        print ("icon Name \(iconName)")
        if((UIImage(named: iconName)) != nil){
            return LiquidFloatingCell(icon: UIImage(named: iconName)!)
        }
        else {
            print("No icon image")
            return LiquidFloatingCell(icon: UIImage(named: "ic_future")!)
        }
    }
    
    func createButton(frame: CGRect,style:LiquidFloatingActionButtonAnimateStyle)->LiquidFloatingActionButton{
        let floatingActionButton = LiquidFloatingActionButton(frame: frame)
        
        floatingActionButton.animateStyle=style
        floatingActionButton.dataSource=self as LiquidFloatingActionButtonDataSource
        floatingActionButton.delegate=self as LiquidFloatingActionButtonDelegate
        print("Button Created");
        return floatingActionButton
    }
    
    // Method to get direction and show route from current location to destination and
    // collect location data periodically
    func getDirections() {
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination!
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: {(response, error) in
            
            if error != nil {
                print("Error getting directions")
            } else {
                self.showRoute(response!)
                
                //start updating location
                self.locationManager.startUpdatingLocation()
                
                //start timer to collect data periodically
                print("Update Location Starting...")
                self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(RouteViewController.getDataTimer), userInfo: nil, repeats: true)
            }
            
        })
        print("Acceleration : \(String(describing: currentAccelerometerAccelerationX)), \(String(describing: currentAccelerometerAccelerationY)), \(String(describing: currentAccelerometerAccelerationZ))")
        print("Gyroscope : \(String(describing: gyroRotationX)), \(String(describing: gyroRotationY)), \(String(describing: gyroRotationZ))")
    }
    
    
}

//MARK: - CLLocationManager Delegate -
extension RouteViewController {
    
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

//MARK: - LiquidFloatingActionButton Delegate -
extension RouteViewController: LiquidFloatingActionButtonDelegate{
    
    func liquidFloatingActionButton(_ liquidFloatingActionButton: LiquidFloatingActionButton, didSelectItemAtIndex index: Int){
        // Write Method to call the specific method related to floating buttons
        
        switch (index){
        case 0 :
            predictionRequestAlert()
            break
        default: break
        }
        print("button number \(index) did click")
        self.floatingActionButton.close()
    }
}

//MARK: - LiquidFloatingActionButton DataSource -
extension RouteViewController:LiquidFloatingActionButtonDataSource{
    
    func numberOfCells(_ liquidFloatingActionButton: LiquidFloatingActionButton) -> Int {
        return cells.count
    }
    
    func cellForIndex(_ index: Int) -> LiquidFloatingCell{
        return cells[index];
    }
}

