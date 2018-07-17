//
//  NearbyLocationsMapViewController.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 22.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import UIKit
import MapKit

class NearbyLocationsMapViewController: UIViewController {
    
    // MARK: - Assets
    
    /* Outlets */
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var focusUserLocationButton: UIBarButtonItem!
    @IBOutlet weak var focusBookmarkedLocationButton: UIBarButtonItem!
    
    
    /* Properties */
    
    var weatherLocationMapAnnotations: [WeatherLocationMapAnnotation]!
    
    private var selectedBookmarkedLocation: WeatherInformationDTO?
    private var previousRegion: MKCoordinateRegion?
    
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = navigationItem.title?.capitalized
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectedBookmarkedLocation = WeatherDataManager.shared.bookmarkedWeatherDataObjects?.first?.weatherInformationDTO
        
        configure()
        prepareMapAnnotations()
        focusOnAvailableLocation()
    }
    
    
    // MARK: - Private Helpers
    
    private func prepareMapAnnotations() {
        weatherLocationMapAnnotations = [WeatherLocationMapAnnotation]()
        
        let bookmarkedLocationAnnotations: [WeatherLocationMapAnnotation]? = WeatherDataManager.shared.bookmarkedWeatherDataObjects?.compactMap {
            guard let weatherDTO = $0.weatherInformationDTO else { return nil }
            return WeatherLocationMapAnnotation(weatherDTO: weatherDTO)
            }
        weatherLocationMapAnnotations.append(contentsOf: bookmarkedLocationAnnotations ?? [WeatherLocationMapAnnotation]())
        
        let nearbyocationAnnotations = WeatherDataManager.shared.nearbyWeatherDataObject?.weatherInformationDTOs?.compactMap {
            return WeatherLocationMapAnnotation(weatherDTO: $0)
        }
        weatherLocationMapAnnotations.append(contentsOf: nearbyocationAnnotations ?? [WeatherLocationMapAnnotation]())
        
        mapView.addAnnotations(weatherLocationMapAnnotations)
    }
    
    private func focusOnAvailableLocation() {
        if let previousRegion = previousRegion {
            mapView.setRegion(previousRegion, animated: true)
            return
        }
        guard LocationService.shared.locationPermissionsGranted, LocationService.shared.currentLocation != nil else {
            focusMapOnSelectedBookmarkedLocation()
            return
        }
        focusMapOnUserLocation()
    }
    
    private func focusMapOnUserLocation() {
        if LocationService.shared.locationPermissionsGranted, let currentLocation = LocationService.shared.currentLocation {
            let region = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 15000, 15000)
            mapView.setRegion(region, animated: true)
            focusUserLocationButton.image = UIImage(named: "LocateUserActiveIcon")
        }
    }
    
    private func focusMapOnSelectedBookmarkedLocation() {
        guard let selectedLocation = selectedBookmarkedLocation else {
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: selectedLocation.coordinates.latitude, longitude: selectedLocation.coordinates.longitude)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 15000, 15000)
        mapView.setRegion(region, animated: true)
        focusBookmarkedLocationButton.image = UIImage(named: "LocateFavoriteActiveIcon")
    }
    
    private func configure() {
        navigationController?.navigationBar.styleStandard(withBarTintColor: .nearbyWeatherStandard, isTransluscent: false, animated: true)
        navigationController?.navigationBar.addDropShadow(offSet: CGSize(width: 0, height: 1), radius: 10)
        
        focusUserLocationButton.tintColor = .white
        
        let locationAvailable = LocationService.shared.locationPermissionsGranted
        focusUserLocationButton.isEnabled = locationAvailable
        focusUserLocationButton.tintColor = locationAvailable ? .white : .gray
        
        focusBookmarkedLocationButton.tintColor = .white
    }
    
    private func triggerFocusOnBookmarkedLocationAlert() {
        let optionsAlert: UIAlertController = UIAlertController(title: NSLocalizedString("OpenWeatherMapCityFilterTVC_FocusOnBookmarkedLocation", comment: ""), message: nil, preferredStyle: .alert)
        
        guard let bookmarkedWeatherDataObjects = WeatherDataManager.shared.bookmarkedWeatherDataObjects?.compactMap({
            return $0.weatherInformationDTO
        }) else {
            return
        }
        
        bookmarkedWeatherDataObjects.forEach { weatherInformationDTO in
            let location = CLLocationCoordinate2D(latitude: weatherInformationDTO.coordinates.latitude, longitude: weatherInformationDTO.coordinates.longitude)
            let action = UIAlertAction(title: weatherInformationDTO.cityName, style: .default, handler: { paramAction in
                let region = MKCoordinateRegionMakeWithDistance(location, 15000, 15000)
                self.selectedBookmarkedLocation = weatherInformationDTO
                DispatchQueue.main.async {
                    self.mapView.setRegion(region, animated: true)
                    self.focusBookmarkedLocationButton.image = UIImage(named: "LocateFavoriteActiveIcon")
                }
            })
            optionsAlert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
        optionsAlert.addAction(cancelAction)
        
        present(optionsAlert, animated: true, completion: nil)
    }
    
    
    // MARK: - IBActions
    
    @IBAction func focusUserLocationButtonTapped(_ sender: UIBarButtonItem) {
        triggerMapTypeAlert()
    }
    
    @IBAction func focusBookmarkedLocationButtonTapped(_ sender: UIBarButtonItem) {
        triggerFocusOnBookmarkedLocationAlert()
    }
    
    // MARK: - Helpers
    
    private func triggerMapTypeAlert() {
        let mapTypes: [MKMapType] = [.standard, .satellite, .hybrid]
        let mapTypeTitles: [MKMapType: String] = [.standard: R.string.localizable.map_type_standard(),
                                                  .satellite: R.string.localizable.map_type_satellite(),
                                                  .hybrid: R.string.localizable.map_type_hybrid()]
        
        let optionsAlert = UIAlertController(title: R.string.localizable.select_list_type().capitalized, message: nil, preferredStyle: .alert)
        mapTypes.forEach { mapTypeCase in
            let action = UIAlertAction(title: mapTypeTitles[mapTypeCase], style: .default, handler: { _ in
                DispatchQueue.main.async {
                    self.mapView.mapType = mapTypeCase
                }
            })
            if mapTypeCase == self.mapView.mapType {
                action.setValue(true, forKey: "checked")
            }
            optionsAlert.addAction(action)
        }
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        optionsAlert.addAction(cancelAction)
        
        present(optionsAlert, animated: true, completion: nil)
    }
}

extension NearbyLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? WeatherLocationMapAnnotation else {
            return nil
        }
        
        var viewForCurrentAnnotation: WeatherLocationMapAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: kMapAnnotationViewIdentifier) as? WeatherLocationMapAnnotationView {
            viewForCurrentAnnotation = dequeuedAnnotationView
        } else {
            viewForCurrentAnnotation = WeatherLocationMapAnnotationView(frame: kMapAnnotationViewInitialFrame)
        }
        viewForCurrentAnnotation?.annotation = annotation
        viewForCurrentAnnotation?.configure(withTitle: annotation.title ?? "<Not Set>", subtitle: annotation.subtitle ?? "<Not Set>", fillColor: (annotation.isDayTime ?? true) ? .nearbyWeatherStandard : .nearbyWeatherNight, tapHandler: { [unowned self] sender in
            guard let weatherDTO = WeatherDataManager.shared.weatherDTO(forIdentifier: annotation.locationId) else {
                return
            }
            self.previousRegion = mapView.region
            
            let destinationViewController = WeatherDetailViewController.instantiateFromStoryBoard(withTitle: weatherDTO.cityName, weatherDTO: weatherDTO)
            let destinationNavigationController = UINavigationController(rootViewController: destinationViewController)
            destinationNavigationController.addVerticalCloseButton(withCompletionHandler: nil)
            self.navigationController?.present(destinationNavigationController, animated: true, completion: nil)
        })
        return viewForCurrentAnnotation
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        focusUserLocationButton.image = UIImage(named: "LocateUserInactiveIcon")
        focusBookmarkedLocationButton.image = UIImage(named: "LocateFavoriteInactiveIcon")
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if LocationService.shared.locationPermissionsGranted,
            let currentLocation = LocationService.shared.currentLocation,
            mapView.region.center.latitude == currentLocation.coordinate.latitude
                && mapView.region.center.longitude == currentLocation.coordinate.longitude {
            focusUserLocationButton.image = UIImage(named: "LocateUserActiveIcon")
        }
        if mapView.region.center.latitude == selectedBookmarkedLocation?.coordinates.latitude
            && mapView.region.center.longitude == selectedBookmarkedLocation?.coordinates.longitude {
            focusBookmarkedLocationButton.image = UIImage(named: "LocateFavoriteActiveIcon")
        }
    }
}
