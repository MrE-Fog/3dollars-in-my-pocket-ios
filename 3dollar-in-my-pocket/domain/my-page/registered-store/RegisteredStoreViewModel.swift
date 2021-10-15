import RxSwift
import RxCocoa
import CoreLocation

class RegisteredStoreViewModel: BaseViewModel {
  
  let input = Input()
  let output = Output()
  let storeService: StoreServiceProtocol
  let userDefaults: UserDefaultsUtil
  
  var stores: [StoreCard] = [] {
    didSet {
      self.output.stores.accept(stores)
    }
  }
  var totalCount: Int?
  var nextCursor: Int?
  var currentLocation: CLLocation?
  
  struct Input {
    let fetchStores = PublishSubject<CLLocation?>()
    let tapStore = PublishSubject<Int>()
    let loadMore = PublishSubject<Int>()
  }
  
  struct Output {
    let stores = PublishRelay<[StoreCard]>()
    let isHiddenFooter = PublishRelay<Bool>()
    let goToStoreDetail = PublishRelay<Int>()
  }
  
  
  init(
    storeService: StoreServiceProtocol,
    userDefaults: UserDefaultsUtil
  ) {
    self.storeService = storeService
    self.userDefaults = userDefaults
    super.init()
    
    self.input.fetchStores
      .do(onNext: { [weak self] location in
        self?.currentLocation = location
      })
      .map { ($0, self.totalCount, self.nextCursor) }
      .bind(onNext: self.fetchRegisteredStores)
      .disposed(by: self.disposeBag)
    
    self.input.tapStore
      .map { self.stores[$0].id }
      .bind(to: self.output.goToStoreDetail)
      .disposed(by: disposeBag)
    
    self.input.loadMore
      .filter(self.hasNextPage(currentIndex:))
      .map { _ in (self.currentLocation, self.totalCount, self.nextCursor) }
      .bind(onNext: self.fetchRegisteredStores)
      .disposed(by: disposeBag)
  }
  
  func fetchRegisteredStores(location: CLLocation?, totalCount: Int?, nextCursor: Int?) {
    self.output.isHiddenFooter.accept(false)
    guard let location = location else { return }
    self.storeService.getReportedStore(
      currentLocation: location,
      totalCount: totalCount,
      cursor: nextCursor
    )
      .subscribe(
        onNext: { [weak self] pagination in
          guard let self = self else { return }
          let newStores = pagination.contents.map(StoreCard.init)
          
          self.totalCount = pagination.totalElements
          self.nextCursor = pagination.nextCursor
          self.stores += newStores
          self.output.isHiddenFooter.accept(true)
        },
        onError: self.showErrorAlert.accept(_:)
      )
      .disposed(by: disposeBag)
  }
  
  private func hasNextPage(currentIndex: Int) -> Bool {
    return self.stores.count - 1 == currentIndex
      && self.nextCursor != -1
  }
}
