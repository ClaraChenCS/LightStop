//
//  LocationSearchTable.swift
//  LightStop
//
//  Created by Monisha Dash on 3/15/17.
//  Copyright © 2017 sjsu. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class LocationSearchTable: UITableViewController {
    
    //MARK: - Properties
    var handleMapSearchDelegate:HandleMapSearch? = nil
    var matchingItems:[MKMapItem] = []
    var mapView: MKMapView? = nil
    
    //MARK: - Custom Methods -
    func parseAddress(selectedItem:MKPlacemark)->String{
        let firstSpace = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) ? " ":""
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
        
    }
    
    //MARK: - Navigation -
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let routeViewController = segue.destination as! RouteViewController
        let indexPath = self.tableView.indexPathForSelectedRow!
        let row = indexPath.row
        routeViewController.destination = matchingItems[row]
    }
}

//MARK: - UISearchResultsUpdating Protocol -
extension LocationSearchTable : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
//        guard   let mapView = mapView,
//                let searchBarText = searchController.searchBar.text
//                else {return}
//        
//        let request = MKLocalSearchRequest()
//        request.naturalLanguageQuery = searchBarText
//        request.region = mapView.region
//        
//        let search = MKLocalSearch(request: request)
//        search.start { response, _ in
//            guard let response = response else {
//                return
//            }
//            self.matchingItems = response.mapItems
//            self.tableView.reloadData()
//        }
    }
}

/// UITableViewDataSource.
extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)->Int{
        return matchingItems.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Prepares the cells within the tableView.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)->UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
}

/// UITableViewDelegate.
extension LocationSearchTable {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selecteditem = matchingItems[indexPath.row]
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selecteditem)
    }
}

