//
//  AppUserData.swift
//  LightStop
//
//  Created by Clara Chen on 3/30/17.
//  Copyright © 2017 sjsu. All rights reserved.
//

import Foundation
import MapKit
import Alamofire

class AppUserData{
    
    //MARK: - Properties
    var data:Parameters = [
        "loggingTime":"",
        "locationLatitude":"",
        "locationLongitude":"",
        "locationSpeed":"",
        "accelerometerAccelerationX":"",
        "accelerometerAccelerationY":"",
        "accelerometerAccelerationZ":"",
        "gyroRotationX":"",
        "gyroRotationY":"",
        "gyroRotationZ":"",
    ]
    
    var dataCount:Parameters = [
        "id":"",
        "value":0,
    ]
    
    func getRandomUserData() -> Parameters{
        do {
            if let file = Bundle.main.url(forResource: "dataRandom", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let parsedData = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [Dictionary<String, String>]
                if let object = parsedData as? [[String: String]] {
                    // json is a dictionary
                    let randomNum:UInt32 = arc4random_uniform(6) // range is 0 to 99
                    let ranData = object[Int(randomNum)]
                    self.data["loggingTime"] = ranData["loggingTime"]
                    self.data["deviceID"] = ranData["deviceID"]
                    self.data["locationLatitude"] = ranData["locationLatitude"]
                    self.data["locationLongitude"] = ranData["locationLongitude"]
                    self.data["locationSpeed"] = ranData["locationSpeed"]
                    self.data["accelerometerAccelerationX"] = ranData["accelerometerAccelerationX"]
                    self.data["accelerometerAccelerationY"] = ranData["accelerometerAccelerationY"]
                    self.data["accelerometerAccelerationZ"] = ranData["accelerometerAccelerationZ"]
                    self.data["gyroRotationX"] = ranData["gyroRotationX"]
                    self.data["gyroRotationY"] = ranData["gyroRotationY"]
                    self.data["gyroRotationZ"] = ranData["gyroRotationZ"]
                    return self.data
                } else {
                    print("JSON is invalid")
                }
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
        return self.data
    }
}
