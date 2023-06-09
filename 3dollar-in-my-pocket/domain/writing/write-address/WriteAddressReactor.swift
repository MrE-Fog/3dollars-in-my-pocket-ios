import CoreLocation

import RxSwift
import RxCocoa
import ReactorKit

final class WriteAddressReactor: BaseReactor, Reactor {
    enum Action {
        case moveMapCenter(latitude: Double, longitude: Double)
        case tapCurrentLocation
        case tapSetAddress
        case tapConfirmAddress
    }
    
    enum Mutation {
        case setNearStores(stores: [Store])
        case moveCamera(latitude: Double, longitude: Double)
        case setAddressText(address: String)
        case pushAddressDetail(address: String, location: (Double, Double))
        case presentConfirmPopup(address: String)
        case showErrorAlert(Error)
    }
    
    struct State {
        var address = ""
        var nearStores: [Store] = []
        var cameraPosition: (Double, Double)?
    }
    
    let initialState = State()
    let pushWriteDetailPublisher = PublishRelay<(String, (Double, Double))>()
    let presentConfirmPopupPublisher = PublishRelay<String>()
    private let mapService: MapServiceProtocol
    private let storeService: StoreServiceProtocol
    private let locationManager: LocationManagerProtocol
    
    init(
        mapService: MapServiceProtocol,
        storeService: StoreServiceProtocol,
        locationManager: LocationManagerProtocol
    ) {
        self.mapService = mapService
        self.storeService = storeService
        self.locationManager = locationManager
        
        super.init()
        self.action.onNext(.tapCurrentLocation)
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case let .moveMapCenter(latitude, longitude):
            return .merge([
                self.fetchNearStores(latitude: latitude, longitude: longitude),
                self.fetchAddressFromLocation(latitude: latitude, longitude: longitude),
                .just(.moveCamera(latitude: latitude, longitude: longitude))
            ])
            
        case .tapCurrentLocation:
            return self.locationManager.getCurrentLocation()
                .flatMap { [weak self] location -> Observable<Mutation> in
                    guard let self = self else { return .just(.showErrorAlert(BaseError.unknown)) }
                    return .merge([
                        self.fetchNearStores(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        ),
                        self.fetchAddressFromLocation(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        ),
                        .just(.moveCamera(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude
                        ))
                    ])
                }
            
        case .tapSetAddress:
            return self.isStoreExistedNear()
            
        case .tapConfirmAddress:
            guard let location = self.currentState.cameraPosition else {
                let error = BaseError.custom("지도 위치가 올바르지 않습니다.")
                
                return .just(.showErrorAlert(error))
            }
            return .just(.pushAddressDetail(
                address: self.currentState.address,
                location: location
            ))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setNearStores(let stores):
            newState.nearStores = stores
            
        case .moveCamera(let latitude, let longitude):
            newState.cameraPosition = (latitude, longitude)
            
        case .setAddressText(let address):
            newState.address = address
            
        case .pushAddressDetail(let address, let location):
            self.pushWriteDetailPublisher.accept((address, location))
            
        case .presentConfirmPopup(let address):
            self.presentConfirmPopupPublisher.accept(address)
            
        case .showErrorAlert(let error):
            self.showErrorAlertPublisher.accept(error)
        }
        
        return newState
    }
    
    private func fetchNearStores(latitude: Double, longitude: Double) -> Observable<Mutation> {
        return self.storeService.searchNearStores(
            currentLocation: nil,
            mapLocation: CLLocation(latitude: latitude, longitude: longitude),
            distance: 200,
            category: nil,
            orderType: nil
        )
        .map { .setNearStores(stores: $0.map(Store.init)) }
        .catchError { .just(.showErrorAlert($0)) }
    }
    
    private func isStoreExistedNear() -> Observable<Mutation> {
        guard let cameraPosition = self.currentState.cameraPosition else {
            let error = BaseError.custom("지도의 위치가 올바르지 않습니다.")
            return .just(.showErrorAlert(error))
        }
        let mapLocataion = CLLocation(latitude: cameraPosition.0, longitude: cameraPosition.1)
        
        return self.storeService.isStoresExistedAround(
            distance: 10,
            mapLocation: mapLocataion
        )
        .map { $0.isExists }
        .map { isExists in
            if isExists {
                return .presentConfirmPopup(address: self.currentState.address)
            } else {
                return .pushAddressDetail(
                    address: self.currentState.address,
                    location: cameraPosition
                )
            }
        }
        .catchError { .just(.showErrorAlert($0)) }
    }
    
    private func fetchAddressFromLocation(
        latitude: Double,
        longitude: Double
    ) -> Observable<Mutation> {
        return self.mapService.getAddressFromLocation(latitude: latitude, longitude: longitude)
            .map { .setAddressText(address: $0) }
            .catchError { .just(.showErrorAlert($0)) }
    }
}
