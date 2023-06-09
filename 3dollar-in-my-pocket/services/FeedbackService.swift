import Alamofire
import RxSwift

protocol FeedbackServiceProtocol {
    func fetchFeedbackTypes(storeType: StoreType) -> Observable<[BossStoreFeedbackMeta]>
    
    func fetchBossStoreFeedbacks(
        storeType: StoreType,
        bossStoreId: String
    ) -> Observable<[BossStoreFeedback]>
    
    func sendFeedbacks(
        storeType: StoreType,
        bossStoreId: String,
        feedbackTypes: [BossStoreFeedbackType]
    ) -> Observable<Void>
}

struct FeedbackService: FeedbackServiceProtocol {
    private let networkManager = NetworkManager()
    
    func fetchFeedbackTypes(storeType: StoreType) -> Observable<[BossStoreFeedbackMeta]> {
        let urlString = HTTPUtils.url + "/api/v1/feedback/\(storeType.targetType)/types"
        
        return self.networkManager.createGetObservable(
            class: [BossStoreFeedbackTypeResponse].self,
            urlString: urlString,
            headers: HTTPUtils.jsonHeader()
        )
        .map { $0.map(BossStoreFeedbackMeta.init(response:))}
    }
    
    func fetchBossStoreFeedbacks(
        storeType: StoreType,
        bossStoreId: String
    ) -> Observable<[BossStoreFeedback]> {
        let urlString = HTTPUtils.url
        + "/api/v1/feedback/\(storeType.targetType)/target/\(bossStoreId)/full"
        
        return self.networkManager.createGetObservable(
            class: [BossStoreFeedbackCountWithRatioResponse].self,
            urlString: urlString,
            headers: HTTPUtils.defaultHeader()
        )
        .map { $0.map(BossStoreFeedback.init(response:)) }
    }
    
    func sendFeedbacks(
        storeType: StoreType,
        bossStoreId: String,
        feedbackTypes: [BossStoreFeedbackType]
    ) -> Observable<Void> {
        let urlString = HTTPUtils.url
        + "/api/v1/feedback/\(storeType.targetType)/target/\(bossStoreId)"
        let parameters = ["feedbackTypes": feedbackTypes.map { $0.rawValue }]
        
        return .create { observer in
            HTTPUtils.defaultSession.request(
                urlString,
                method: .post,
                parameters: parameters,
                encoder: JSONParameterEncoder.default,
                headers: HTTPUtils.defaultHeader()
            ).responseData { response in
                if response.isSuccess() {
                    observer.onNext(())
                    observer.onCompleted()
                } else {
                    observer.processAPIError(response: response)
                }
            }
            
            return Disposables.create()
        }
    }
}
