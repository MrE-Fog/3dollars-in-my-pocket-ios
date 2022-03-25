import UIKit

import RxSwift
import NMapsMap
import ReactorKit

final class HomeViewController: BaseVC, View, HomeCoordinator {
    weak var coordinator: HomeCoordinator?
    private let homeView = HomeView()
    private let homeReactor = HomeReactor(
        storeService: StoreService(),
        advertisementService: AdvertisementService(),
        locationManager: LocationManager.shared,
        mapService: MapService(),
        userDefaults: UserDefaultsUtil()
    )
  
    var mapAnimatedFlag = false
    var previousOffset: CGFloat = 0
    var markers: [NMFMarker] = []
    fileprivate let transition = SearchTransition()
  
    static func instance() -> UINavigationController {
        let viewController = HomeViewController(nibName: nil, bundle: nil).then {
            $0.tabBarItem = UITabBarItem(
                title: nil,
                image: R.image.ic_home(),
                tag: TabBarTag.home.rawValue
            )
        }
        
        return UINavigationController(rootViewController: viewController).then {
            $0.isNavigationBarHidden = true
            $0.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    override func loadView() {
        self.view = self.homeView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coordinator = self
        self.reactor = self.homeReactor
        self.initilizeShopCollectionView()
        self.initilizeNaverMap()
        self.homeReactor.action.onNext(.tapCurrentLocationButton)
    }
    
    override func bindEvent() {
        self.homeView.addressButton.rx.tap
            .asDriver()
            .do(onNext: { _ in
                GA.shared.logEvent(event: .search_button_clicked, page: .home_page)
            })
            .drive(onNext: { [weak self] in
                self?.coordinator?.showSearchAddress()
            })
            .disposed(by: self.eventDisposeBag)
                
        self.homeView.tossButton.rx.tap
            .asDriver()
            .do(onNext: { _ in
                GA.shared.logEvent(event: .toss_button_clicked, page: .home_page)
            })
            .drive(onNext: { [weak self] in
                self?.coordinator?.goToToss()
            })
            .disposed(by: self.eventDisposeBag)
        
        self.homeReactor.pushStoreDetailPublisher
            .asDriver(onErrorJustReturn: -1)
            .drive(onNext: { [weak self] storeId in
                self?.coordinator?.pushStoreDetail(storeId: storeId)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.homeReactor.presentVisitPublisher
            .asDriver(onErrorJustReturn: Store())
            .drive(onNext: { [weak self] store in
                self?.coordinator?.presentVisit(store: store)
            })
            .disposed(by: self.eventDisposeBag)
        
        self.homeReactor.showErrorAlertPublisher
            .asDriver(onErrorJustReturn: BaseError.unknown)
            .drive(onNext: { [weak self] error in
                if let locationError = error as? LocationError {
                    self?.handleLocationError(locationError: locationError)
                } else {
                    self?.coordinator?.showErrorAlert(error: error)
                }
            })
            .disposed(by: self.eventDisposeBag)
                
        self.homeReactor.openURLPublisher
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] url in
                self?.coordinator?.openURL(url: url)
            })
            .disposed(by: self.eventDisposeBag)
    }
    
    func bind(reactor: HomeReactor) {
        // Bind Action
        self.homeView.researchButton.rx.tap
            .map { Reactor.Action.tapResearchButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.homeView.currentLocationButton.rx.tap
            .map { Reactor.Action.tapCurrentLocationButton }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        self.homeView.storeCollectionView.rx.itemSelected
            .map { Reactor.Action.tapStore(index: $0.row) }
            .bind(to: reactor.action)
            .disposed(by: self.disposeBag)
        
        if let layout
            = self.homeView.storeCollectionView.collectionViewLayout as? HomeStoreFlowLayout {
            layout.currentIndex
                .map { Reactor.Action.selectStore(index: $0) }
                .bind(to: reactor.action)
                .disposed(by: self.disposeBag)
        }
        
        // Bind State
        reactor.state
            .map { $0.storeCellTypes }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(
                self.homeView.storeCollectionView.rx.items
            ) { collectionView, row, storeCellType -> UICollectionViewCell in
                let indexPath = IndexPath(row: row, section: 0)
                
                switch storeCellType {
                case .store(let store):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: HomeStoreCell.registerId,
                        for: indexPath
                    ) as? HomeStoreCell else {
                        return BaseCollectionViewCell()
                    }
                    
                    cell.bind(store: store)
                    cell.visitButton.rx.tap
                        .map { Reactor.Action.tapVisitButton(index: row) }
                        .bind(to: self.homeReactor.action)
                        .disposed(by: cell.disposeBag)
                    return cell
                    
                case .advertisement(let advertisement):
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: HomeAdvertisementCell.registerId,
                        for: indexPath
                    ) as? HomeAdvertisementCell else {
                        return BaseCollectionViewCell()
                    }
                    
                    cell.bind(advertisement: advertisement)
                    return cell
                    
                case .empty:
                    guard let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: HomeEmptyStoreCell.registerId,
                        for: indexPath
                    ) as? HomeEmptyStoreCell else {
                        return BaseCollectionViewCell()
                    }
                    
                    return cell
                }
            }
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.address }
            .asDriver(onErrorJustReturn: "")
            .distinctUntilChanged()
            .drive(self.homeView.addressButton.rx.title(for: .normal))
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { $0.isHiddenResearchButton }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(self.homeView.rx.isResearchButtonHidden)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .compactMap { $0.cameraPosition }
            .asDriver(onErrorJustReturn: CLLocation(latitude: 0, longitude: 0))
            .drive(self.homeView.rx.cameraPosition)
            .disposed(by: self.disposeBag)
        
        reactor.state
            .map { ($0.selectedIndex, $0.storeCellTypes) }
            .asDriver(onErrorJustReturn: (nil, []))
            .drive(onNext: { [weak self] selectedIndex, storeCellTypes in
                self?.selectMarker(selectedIndex: selectedIndex, storeCellTypes: storeCellTypes)
            })
            .disposed(by: self.disposeBag)
        
        reactor.state
            .compactMap { $0.selectedIndex }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] selectedIndex in
                self?.homeView.storeCollectionView.selectItem(
                    at: IndexPath(row: selectedIndex, section: 0),
                    animated: true,
                    scrollPosition: .left
                )
            })
            .disposed(by: self.disposeBag)
    }
    
    private func initilizeShopCollectionView() {
        self.homeView.storeCollectionView.rx
            .setDelegate(self)
            .disposed(by: self.eventDisposeBag)
    }
    
    private func initilizeNaverMap() {
        self.homeView.mapView.addCameraDelegate(delegate: self)
    }
    
    private func selectMarker(selectedIndex: Int?, storeCellTypes: [StoreCellType]) {
        self.clearMarker()
        
        for index in storeCellTypes.indices {
            if case .store(let store) = storeCellTypes[index] {
                let marker = NMFMarker()
                
                marker.position = NMGLatLng(lat: store.latitude, lng: store.longitude)
                if index == selectedIndex {
                    marker.iconImage = NMFOverlayImage(name: "ic_marker")
                    marker.width = 30
                    marker.height = 40
                } else {
                    marker.iconImage = NMFOverlayImage(name: "ic_marker_store_off")
                    marker.width = 24
                    marker.height = 24
                }
                marker.mapView = self.homeView.mapView
                marker.touchHandler = { [weak self] _ in
                    self?.homeReactor.action.onNext(.selectStore(index: index))
                    return true
                }
                self.markers.append(marker)
            }
        }
    }

    private func clearMarker() {
        for marker in self.markers {
            marker.mapView = nil
        }
    }
  
    private func handleLocationError(locationError: LocationError) {
        if locationError == .denied {
            self.coordinator?.showDenyAlert()
        } else {
            AlertUtils.show(controller: self, title: nil, message: locationError.errorDescription)
        }
    }
}

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = CGFloat(272)
        let offsetHelper: CGFloat = self.previousOffset > scrollView.contentOffset.x ? -50 : 50
        let proportionalOffset = (scrollView.contentOffset.x + offsetHelper) / pageWidth
        
        self.previousOffset = scrollView.contentOffset.x
        
        var selectedIndex = Int(proportionalOffset.rounded())
        if selectedIndex < 0 {
            selectedIndex = 0
        }
    }
}

extension HomeViewController: SearchAddressDelegate {
    func selectAddress(location: (Double, Double), name: String) {
        let location = CLLocation(latitude: location.0, longitude: location.1)
        
        self.homeReactor.action.onNext(.changeMapLocation(location))
        self.homeReactor.action.onNext(.tapResearchButton)
    }
}

extension HomeViewController: StoreDetailDelegate {
    func popup(store: Store) {
        self.homeReactor.action.onNext(.updateStore(store: store))
    }
}

extension HomeViewController: NMFMapViewCameraDelegate {
    func mapView(
        _ mapView: NMFMapView,
        cameraWillChangeByReason reason: Int,
        animated: Bool
    ) {
        if reason == NMFMapChangedByGesture {
            let mapLocation = CLLocation(
                latitude: mapView.cameraPosition.target.lat,
                longitude: mapView.cameraPosition.target.lng
            )
            let distance = mapView
                .contentBounds
                .boundsLatLngs[0]
                .distance(to: mapView.contentBounds.boundsLatLngs[1])
            
            self.homeReactor.action.onNext(.changeMaxDistance(maxDistance: distance / 3))
            self.homeReactor.action.onNext(.changeMapLocation(mapLocation))
        }
    }
    
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        if reason == NMFMapChangedByGesture {
            let mapLocation = CLLocation(
                latitude: mapView.cameraPosition.target.lat,
                longitude: mapView.cameraPosition.target.lng
            )
            let distance = mapView
                .contentBounds
                .boundsLatLngs[0]
                .distance(to: mapView.contentBounds.boundsLatLngs[1])
            
            self.homeReactor.action.onNext(.changeMaxDistance(maxDistance: distance / 3))
            self.homeReactor.action.onNext(.changeMapLocation(mapLocation))
        }
    }
}

extension HomeViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.transition.transitionMode = .present
        self.transition.maskView.frame = self.homeView.addressContainerView.frame
        
        return self.transition
    }
    
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.transition.transitionMode = .dismiss
        self.transition.maskOriginalFrame = self.homeView.addressContainerView.frame
        
        return self.transition
    }
}

extension HomeViewController: VisitViewControllerDelegate {
    func onSuccessVisit(store: Store) {
        self.homeReactor.action.onNext(.updateStore(store: store))
    }
}