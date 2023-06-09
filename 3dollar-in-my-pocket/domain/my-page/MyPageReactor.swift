import ReactorKit
import RxSwift

final class MyPageReactor: BaseReactor, Reactor {
    enum Action {
        case viewDidLoad
        case refresh
        case tapMyMedal
        case tapVisitHistory(row: Int)
        case tapBookmarkMore
        case tapBookmark(row: Int)
    }
    
    enum Mutation {
        case setUser(User)
        case updateNickname(String)
        case updateMedal(medal: Medal)
        case setVisitHistories([VisitHistory])
        case setBookmarks([StoreProtocol])
        case appendBookmark(StoreProtocol)
        case deleteBookamrk(storeId: String)
        case endRefresh
        case pushMyMedal(Medal)
        case pushStoreDetail(storeId: Int)
        case pushFoodTruckDetail(storeId: String)
        case pushBookmarkList(userName: String)
        case showErrorAlert(Error)
    }
    
    struct State {
        var user: User
        var visitHistories: [VisitHistory]
        var bookmarks: [StoreProtocol]
        @Pulse var endRefreshing: Void?
        @Pulse var pushStoreDetail: Int?
        @Pulse var pushMyMedal: Medal?
        @Pulse var pushBookmarkList: String?
        @Pulse var pushFoodTruckDetail: String?
    }
    
    let initialState: State
    private let userService: UserServiceProtocol
    private let visitHistoryService: VisitHistoryServiceProtocol
    private let bookmarkService: BookmarkServiceProtocol
    private let globalState: GlobalState
    private let size = 5
    
    init(
        userService: UserServiceProtocol,
        visitHistoryService: VisitHistoryServiceProtocol,
        bookmarkService: BookmarkServiceProtocol,
        globalState: GlobalState,
        state: State = State(user: User(), visitHistories: [], bookmarks: [])
    ) {
        self.userService = userService
        self.visitHistoryService = visitHistoryService
        self.bookmarkService = bookmarkService
        self.globalState = globalState
        self.initialState = state
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .merge([
                self.fetchMyActivityInfo(),
                self.fetchVisitHistories(),
                self.fetchBookmarks()
            ])
            
        case .refresh:
            let refreshData = Observable.merge([
                self.fetchMyActivityInfo(),
                self.fetchVisitHistories(),
                self.fetchBookmarks()
            ])
            
            return .concat([
                refreshData,
                .just(.endRefresh)
            ])
            
        case .tapMyMedal:
            let currentMedal = self.currentState.user.medal
            
            return .just(.pushMyMedal(currentMedal))
            
        case .tapVisitHistory(let row):
            guard !self.currentState.visitHistories.isEmpty else { return .empty() }
            let tappedVisitHistory = self.currentState.visitHistories[row]
            
            return .just(.pushStoreDetail(storeId: tappedVisitHistory.storeId))
            
        case .tapBookmarkMore:
            return .just(.pushBookmarkList(userName: self.currentState.user.name))
            
        case .tapBookmark(let row):
            guard !self.currentState.bookmarks.isEmpty else { return .empty() }
            let tappedBookmark = self.currentState.bookmarks[row]
            
            switch tappedBookmark.storeCategory {
            case .streetFood:
                return .just(.pushStoreDetail(storeId: Int(tappedBookmark.id) ?? 0))
                
            case .foodTruck:
                return .just(.pushFoodTruckDetail(storeId: tappedBookmark.id))
                
            case .unknown:
                return .empty()
            }
        }
    }
    
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        return .merge([
            mutation,
            self.globalState.deleteBookmarkStore
                .flatMap { storeIds -> Observable<Mutation> in
                        .merge(storeIds.map { .just(.deleteBookamrk(storeId: $0)) })
                },
            self.globalState.addBookmarkStore
                .map { .appendBookmark($0) },
            self.globalState.updateNickname
                .map { .updateNickname($0) },
            self.globalState.updateMedal
                .map { .updateMedal(medal: $0) }
        ])
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setUser(let user):
            newState.user = user
            
        case .updateNickname(let nickname):
            newState.user.name = nickname
            
        case .updateMedal(let medal):
            newState.user.medal = medal
            
        case .setVisitHistories(let visitHistories):
            newState.visitHistories = visitHistories
            
        case .setBookmarks(let stores):
            newState.bookmarks = stores
            
        case .appendBookmark(let store):
            newState.bookmarks.append(store)
            
        case .deleteBookamrk(let storeId):
            if let targetIndex = newState.bookmarks.firstIndex(where: { $0.id == storeId }) {
                newState.bookmarks.remove(at: targetIndex)
            }
            
        case .endRefresh:
            newState.endRefreshing = ()
            
        case .pushMyMedal(let medal):
            newState.pushMyMedal = medal
            
        case .pushStoreDetail(let storeId):
            newState.pushStoreDetail = storeId
            
        case .pushFoodTruckDetail(let storeId):
            newState.pushFoodTruckDetail = storeId
            
        case .pushBookmarkList(let userName):
            newState.pushBookmarkList = userName
            
        case .showErrorAlert(let error):
            self.showErrorAlertPublisher.accept(error)
        }
        
        return newState
    }
    
    private func fetchMyActivityInfo() -> Observable<Mutation> {
        return self.userService.fetchUserActivity()
            .map { .setUser($0) }
            .catch { .just(.showErrorAlert($0)) }
    }
    
    private func fetchVisitHistories() -> Observable<Mutation> {
        return self.visitHistoryService.fetchVisitHistory(cursor: nil, size: self.size)
            .map { $0.contents.map { VisitHistory(response: $0) } }
            .map { .setVisitHistories($0) }
            .catch { .just(.showErrorAlert($0)) }
    }
    
    private func fetchBookmarks() -> Observable<Mutation> {
        return self.bookmarkService.fetchMyBookmarks(cursor: nil, size: self.size)
            .map { .setBookmarks($0.bookmarkFolder.bookmarks) }
            .catch { .just(.showErrorAlert($0)) }
    }
}
