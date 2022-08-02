struct BossStore: StoreProtocol {
    let id: String
    let appearanceDays: [BossStoreAppearanceDay]
    let categories: [Categorizable]
    let distance: Int
    let location: Location?
    let menus: [BossStoreMenu]
    let name: String
    let openingTime: String?
    let imageURL: String?
    let status: OpenStatus
    let contacts: String?
    let snsUrl: String?
    let introduction: String?
    let feedbackCount: Int
    let feedbacks: [BossStoreFeedback]
    
    init(response: BossStoreAroundInfoResponse) {
        self.id = response.bossStoreId
        self.appearanceDays = []
        self.categories = response.categories.map(FoodTruckCategory.init(response: ))
        self.distance = response.distance
        self.location = Location(response: response.location)
        self.menus = []
        self.name = response.name
        self.openingTime = response.openStatus.openStartDateTime
        self.imageURL = nil
        self.status = OpenStatus(response: response.openStatus.status)
        self.contacts = nil
        self.snsUrl = nil
        self.introduction = nil
        self.feedbackCount = response.totalFeedbacksCounts
        self.feedbacks = []
    }
    
//    init(response: BossStoreInfoResponse) {
//        self.id = response.bossStoreId
//        self.appearanceDays
//        = response.appearanceDays.map(BossStoreAppearanceDay.init(response:))
//        self.categories = response.categories.map(FoodTruckCategory.init(response:))
//        self.distance = response.distance
//        self.location = Location(response: response.location)
//        self.menus = response.menus.map(BossStoreMenu.init(response: ))
//        self.name = response.name
//        self.openingTime = response.openStatus.openStartDateTime
//        self.imageURL = response.imageUrl
//        self.status = OpenStatus(response: response.openStatus.status)
//        self.contacts = response.contactsNumber
//        self.snsUrl = response.snsUrl
//        self.introduction = response.introduction
//        self.feedbackCount = 0
//    }
    
    init(response: BossStoreWithFeedbacksResponse) {
        self.id = response.store.bossStoreId
        self.appearanceDays
        = response.store.appearanceDays.map(BossStoreAppearanceDay.init(response:))
        self.categories = response.store.categories.map(FoodTruckCategory.init(response:))
        self.distance = response.store.distance
        self.location = Location(response: response.store.location)
        self.menus = response.store.menus.map(BossStoreMenu.init(response: ))
        self.name = response.store.name
        self.openingTime = response.store.openStatus.openStartDateTime
        self.imageURL = response.store.imageUrl
        self.status = OpenStatus(response: response.store.openStatus.status)
        self.contacts = response.store.contactsNumber
        self.snsUrl = response.store.snsUrl
        self.introduction = response.store.introduction
        self.feedbackCount = response.feedbacks.map { $0.count }.reduce(0, +)
        self.feedbacks = response.feedbacks.map(BossStoreFeedback.init(response:))
    }
    
    init() {
        self.id = ""
        self.appearanceDays = []
        self.categories = []
        self.distance = 0
        self.location = nil
        self.menus = []
        self.name = ""
        self.openingTime = nil
        self.imageURL = nil
        self.status = .open
        self.contacts = nil
        self.snsUrl = nil
        self.introduction = nil
        self.feedbackCount = 0
        self.feedbacks = []
    }
}

extension BossStore: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
