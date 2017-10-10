//
//  LightStopData.swift
//  LightStop
//
//  Created by Clara Chen on 3/22/17.
//  Copyright © 2017 sjsu. All rights reserved.
//  

//  Dictionary Data prepared to send to the backend server

import Foundation
import Alamofire


class LightStopData {
    
    //MARK: - Properties
    var data: Parameters = [
        "date":"",
        "time":"",
        "lat":"",
        "lon":"",
        "user":""
    ]
    
    var dataCount: Parameters = [
        "id" : "",
        "value" : 0,
    ]
}
