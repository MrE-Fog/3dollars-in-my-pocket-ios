//
//  LocationManager.swift
//  3dollar-in-my-pocket
//
//  Created by Hyun Sik Yoo on 2021/09/25.
//  Copyright © 2021 Macgongmon. All rights reserved.
//

import RxSwift
import CoreLocation

protocol LocationManagerProtocol {
    
    func getCurrentLocation() -> Observable<CLLocation>
}

class LocationManager: NSObject, LocationManagerProtocol {
    
    static let shared = LocationManager()
    private var manager = CLLocationManager()
    fileprivate var locationPublisher = PublishSubject<CLLocation>()
    
    override init() {
        super.init()
        
        self.manager.delegate = self
    }
    
    func getCurrentLocation() -> Observable<CLLocation> {
        if CLLocationManager.locationServicesEnabled() {
            if CLLocationManager.authorizationStatus() == .notDetermined {
                self.manager.requestWhenInUseAuthorization()
            } else {
                self.locationPublisher = PublishSubject<CLLocation>()
                self.manager.startUpdatingLocation()
            }
            
            return self.locationPublisher
        } else {
            return .error(LocationError.disableLocationService)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .denied, .restricted:
            self.locationPublisher.onError(LocationError.denied)
        case .authorizedAlways, .authorizedWhenInUse:
            self.manager.startUpdatingLocation()
        case .notDetermined:
            self.manager.requestWhenInUseAuthorization()
        default:
            self.locationPublisher.onError(LocationError.unknown)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        self.manager.stopUpdatingLocation()
        
        guard let lastLocation = locations.last else { return }
        
        self.locationPublisher.onNext(lastLocation)
        self.locationPublisher.onCompleted()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                self.locationPublisher.onError(LocationError.denied)
            case .locationUnknown:
                self.locationPublisher.onError(LocationError.unknownLocation)
            default:
                self.locationPublisher.onError(LocationError.unknown)
            }
        } else {
            self.locationPublisher.onError(LocationError.unknown)
        }
    }
}
