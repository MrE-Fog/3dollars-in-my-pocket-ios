import UIKit
import CoreLocation

import ReactorKit
import RxSwift
import RxCocoa

final class StoreDetailReactor: BaseReactor, Reactor {
    enum Action {
        case viewDidLoad
        case tapDeleteRequest
        case tapBookmark
        case tapCurrentLocation
        case tapShare
        case tapVisitHistory
        case tapEditStore
        case tapAddPhoto
        case tapWriteReview
        case tapEditReview(row: Int)
        case tapPhoto(row: Int)
        case registerPhoto(UIImage)
        case deleteReview(row: Int)
        case tapVisit
    }
    
    enum Mutation {
        case setStore(Store)
        case setCurrentLocation(CLLocation)
        case setBookmark(Bool)
        case moveCamera(CLLocation)
        case appendPhotos([Image])
        case deletePhoto(photoId: Int)
        case addReview(Review)
        case deleteReview(row: Int)
        case presentDeleteModal(storeId: Int)
        case shareToKakao(store: Store)
        case presentVisitHistories(histories: [VisitHistory])
        case pushModify(store: Store)
        case presentAddPhotoActionSheet(storeId: Int)
        case presentReviewModal(storeId: Int, review: Review?)
        case presentPhotoDetail(storeId: Int, index: Int)
        case presentPhotoList(storeId: Int)
        case presentVisit(store: Store)
        case showLoading(isShow: Bool)
        case showErrorAlert(error: Error)
        case showToast(message: String)
    }
    
    struct State {
        var currentLocation: CLLocation
        var store: Store
        var userId: Int
    }
    
    let initialState: State
    let presentDeleteModalPublisher = PublishRelay<Int>()
    let shareToKakaoPublisher = PublishRelay<Store>()
    let presentVisitHistoriesPublisher = PublishRelay<[VisitHistory]>()
    let pushModifyPublisher = PublishRelay<Store>()
    let presentAddPhotoActionSheetPublisher = PublishRelay<Int>()
    let presentPhotoDetailPublisher = PublishRelay<(Int, Int, [Image])>()
    let presentPhotoListPublisher = PublishRelay<Int>()
    let presentReviewModalPublisher = PublishRelay<(Int, Review?)>()
    let presentVisitPublisher = PublishRelay<Store>()
    let moveCameraPublisher = PublishRelay<CLLocation>()
    
    private let storeId: Int
    private var userDefaults: UserDefaultsUtil
    private let locationManager: LocationManagerProtocol
    private let storeService: StoreServiceProtocol
    private let reviewService: ReviewServiceProtocol
    private let bookamrkService: BookmarkServiceProtocol
    private let gaManager: AnalyticsManagerProtocol
    private let globalState: GlobalState
    
    init(
        storeId: Int,
        userDefaults: UserDefaultsUtil,
        locationManager: LocationManagerProtocol,
        storeService: StoreServiceProtocol,
        reviewService: ReviewServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        gaManager: AnalyticsManagerProtocol,
        globalState: GlobalState,
        state: State = State(
            currentLocation: CLLocation(latitude: 0, longitude: 0),
            store: Store(),
            userId: 0
        )
    ) {
        self.storeId = storeId
        self.userDefaults = userDefaults
        self.locationManager = locationManager
        self.storeService = storeService
        self.reviewService = reviewService
        self.bookamrkService = bookmarkService
        self.gaManager = gaManager
        self.globalState = globalState
        self.initialState = State(
            currentLocation: state.currentLocation,
            store: state.store,
            userId: userDefaults.userId
        )
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            if !self.userDefaults.shareLink.isEmpty {
                self.userDefaults.shareLink = ""
            }
            
            return .concat([
                .just(.showLoading(isShow: true)),
                self.locationManager.getCurrentLocation()
                    .flatMap { [weak self] location -> Observable<Mutation> in
                        guard let self = self else { return .error(BaseError.nilValue) }
                        
                        return .merge([
                            self.fetchStore(storeId: self.storeId, currentLocation: location),
                            .just(.setCurrentLocation(location))
                        ])
                    }
                    .catch { .just(.showErrorAlert(error: $0)) },
                .just(.showLoading(isShow: false))
            ])
            
        case .tapDeleteRequest:
            return .just(.presentDeleteModal(storeId: self.storeId))
            
        case .tapBookmark:
            let isBookmarked = self.currentState.store.isBookmarked
            let store = self.currentState.store
            
            if isBookmarked {
                return self.unBookmarkStore(storeId: store.id)
            } else {
                return self.bookmarkStore(store: store)
            }
            
        case .tapCurrentLocation:
            return self.locationManager.getCurrentLocation()
                .map { .moveCamera($0) }
                .catch { .just(.showErrorAlert(error: $0)) }
            
        case .tapShare:
            return .just(.shareToKakao(store: self.currentState.store))
            
        case .tapVisitHistory:
            return .just(.presentVisitHistories(histories: self.currentState.store.visitHistories))
            
        case .tapEditStore:
            return .just(.pushModify(store: self.currentState.store))
            
        case .tapAddPhoto:
            return .just(.presentAddPhotoActionSheet(storeId: self.storeId))
            
        case .tapWriteReview:
            return .just(.presentReviewModal(storeId: self.storeId, review: nil))
            
        case .tapEditReview(let row):
            let tappedReview = self.currentState.store.reviews[row]
            
            return .just(.presentReviewModal(
                storeId: self.storeId,
                review: tappedReview)
            )
            
        case .tapPhoto(let row):
            guard !self.currentState.store.images.isEmpty else { return .empty() }
            
            if row == 3 {
                return .just(.presentPhotoList(storeId: self.storeId))
            } else {
                return .just(.presentPhotoDetail(storeId: self.storeId, index: row))
            }
            
        case .registerPhoto(let photo):
            return .concat([
                .just(.showLoading(isShow: true)),
                self.savePhoto(storeId: self.storeId, photos: [photo]),
                .just(.showLoading(isShow: false))
            ])
            
        case .deleteReview(let row):
            return .concat([
                .just(.showLoading(isShow: true)),
                self.deleteReview(row: row),
                .just(.showLoading(isShow: false))
            ])
            
        case .tapVisit:
            return .just(.presentVisit(store: self.currentState.store))
        }
    }
    
    func transform(action: Observable<Action>) -> Observable<Action> {
        return .merge([
            action,
            self.globalState.updateStore
                .flatMap { storeProtocol -> Observable<Action> in
                    if let _ = storeProtocol as? Store {
                        return .just(.viewDidLoad)
                    } else {
                        return .empty()
                    }
                }
        ])
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return .merge([
            mutation,
            self.globalState.addStorePhotos
                .map { .appendPhotos($0) },
            self.globalState.deletedPhoto
                .map { .deletePhoto(photoId: $0) },
            self.globalState.addStoreReview
                .map { .addReview($0) }
        ])
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setStore(let store):
            newState.store = store
            
        case .setCurrentLocation(let location):
            newState.currentLocation = location
            
        case .setBookmark(let isBookmarked):
            newState.store.isBookmarked = isBookmarked
            
        case .moveCamera(let location):
            self.moveCameraPublisher.accept(location)
            
        case .appendPhotos(let photos):
            newState.store.images.insert(contentsOf: photos, at: 0)
            
        case .deletePhoto(let photoId):
            if let targetIndex = newState.store.images.firstIndex(where: {
                $0.imageId == photoId
            }) {
                newState.store.images.remove(at: targetIndex)
            }
            
        case .addReview(let review):
            newState.store.reviews.append(review)
            
        case .deleteReview(let row):
            newState.store.reviews.remove(at: row)
            
        case .presentDeleteModal(let storeId):
            self.presentDeleteModalPublisher.accept(storeId)
            
        case .shareToKakao(let store):
            self.shareToKakaoPublisher.accept(store)
            
        case .presentVisitHistories(let histories):
            self.presentVisitHistoriesPublisher.accept(histories)
            
        case .pushModify(let store):
            self.pushModifyPublisher.accept(store)
            
        case .presentAddPhotoActionSheet(let storeId):
            self.presentAddPhotoActionSheetPublisher.accept(storeId)
            
        case .presentReviewModal(let storeId, let review):
            self.presentReviewModalPublisher.accept((storeId, review))
            
        case .presentPhotoDetail(let storeId, let index):
            self.presentPhotoDetailPublisher.accept((storeId, index, state.store.images))
            
        case .presentPhotoList(let storeId):
            self.presentPhotoListPublisher.accept(storeId)
            
        case .presentVisit(let store):
            self.presentVisitPublisher.accept(store)
            
        case .showLoading(let isShow):
            self.showLoadingPublisher.accept(isShow)
            
        case .showErrorAlert(let error):
            self.showErrorAlertPublisher.accept(error)
            
        case .showToast(let message):
            self.showToastPublisher.accept(message)
        }
        
        return newState
    }
    
    private func fetchStore(
        storeId: Int,
        currentLocation: CLLocation
    ) -> Observable<Mutation> {
        return self.storeService.fetchStoreDetail(
            storeId: storeId,
            latitude: currentLocation.coordinate.latitude,
            longitude: currentLocation.coordinate.longitude,
            startDate: Date().addMonth(month: -1),
            endDate: Date()
        )
        .map { .setStore($0) }
    }
    
    private func savePhoto(storeId: Int, photos: [UIImage]) -> Observable<Mutation> {
        return self.storeService.savePhoto(storeId: self.storeId, photos: photos)
            .map { .appendPhotos($0) }
            .catch { .just(.showErrorAlert(error: $0)) }
    }
    
    private func deleteReview(row: Int) -> Observable<Mutation> {
        let targetReview = self.currentState.store.reviews[row]
        
        return self.reviewService.deleteReview(reviewId: targetReview.reviewId)
            .flatMap { [weak self] _ -> Observable<Mutation> in
                guard let self = self else { return .error(BaseError.nilValue) }
                
                return self.fetchStore(
                    storeId: self.storeId,
                    currentLocation: self.currentState.currentLocation
                )
            }
            .catch { .just(.showErrorAlert(error: $0)) }
    }
    
    private func bookmarkStore(store: Store) -> Observable<Mutation> {
        return self.bookamrkService.bookmarkStore(storeType: .streetFood, storeId: store.id)
            .do(onNext: { [weak self] _ in
                self?.globalState.addBookmarkStore.onNext(store)
            })
            .flatMap { _ -> Observable<Mutation> in
                return .merge([
                    .just(.setBookmark(true)),
                    .just(.showToast(message: "store_detail_bookmark_toast".localized))
                ])
            }
            .catch { .just(.showErrorAlert(error: $0)) }
    }
    
    private func unBookmarkStore(storeId: String) -> Observable<Mutation> {
        return self.bookamrkService.unBookmarkStore(storeType: .streetFood, storeId: storeId)
            .do(onNext: { [weak self] _ in
                self?.globalState.deleteBookmarkStore.onNext([storeId])
            })
            .flatMap { _ -> Observable<Mutation> in
                return .merge([
                    .just(.setBookmark(false)),
                    .just(.showToast(message: "store_detail_unbookmark_toast".localized))
                ])
            }
            .catch { .just(.showErrorAlert(error: $0)) }
    }
}
