struct Store {
  
  let appearanceDays: [WeekDay]
  let categories: [StoreCategory]
  let distance: Int
  let images: [Image]
  let latitude: Double
  let longitude: Double
  let menus: [Menu]
  let paymentMethods: [PaymentType]
  let rating: Double
  var reviews: [Review]
  let storeId: Int
  let storeName: String
  let storeType: StoreType?
  let updatedAt: String
  let user: User
  let visitHistories: [VisitHistory]
  
  init(
    category: StoreCategory,
    latitude: Double,
    longitude: Double,
    storeName: String,
    menus: [Menu]
  ) {
    self.appearanceDays = []
    self.categories = [category]
    self.distance = -1
    self.storeId = -1
    self.images = []
    self.latitude = latitude
    self.longitude = longitude
    self.menus = menus
    self.paymentMethods = []
    self.rating = -1
    self.reviews = []
    self.storeName = storeName
    self.storeType = nil
    self.updatedAt = ""
    self.user = User()
    self.visitHistories = []
  }
  
  init(
    id: Int = -1,
    appearanceDays: [WeekDay],
    categories: [StoreCategory],
    latitude: Double,
    longitude: Double,
    menuSections: [MenuSection],
    paymentType: [PaymentType],
    storeName: String,
    storeType: StoreType?
  ) {
    self.appearanceDays = appearanceDays
    self.categories = categories
    self.distance = -1
    self.storeId = id
    self.images = []
    self.latitude = latitude
    self.longitude = longitude
    
    var menus: [Menu] = []
    for menuSection in menuSections {
      menus += menuSection.toMenu()
    }
    self.menus = menus
    self.paymentMethods = paymentType
    self.rating = -1
    self.reviews = []
    self.storeName = storeName
    self.storeType = storeType
    self.updatedAt = ""
    self.user = User()
    self.visitHistories = []
  }
  
  init() {
    self.appearanceDays = []
    self.categories = []
    self.distance = 0
    self.storeId = 0
    self.images = []
    self.latitude = 0
    self.longitude = 0
    self.menus = []
    self.paymentMethods = []
    self.rating = 0
    self.reviews = []
    self.storeName = ""
    self.storeType = nil
    self.updatedAt = ""
    self.user = User()
    self.visitHistories = []
  }
  
  init(response: StoreInfoResponse) {
    self.appearanceDays = []
    self.categories = response.categories
    self.distance = response.distance
    self.storeId = response.storeId
    self.images = []
    self.latitude = response.latitude
    self.longitude = response.longitude
    self.menus = []
    self.paymentMethods = []
    self.rating = response.rating
    self.reviews = []
    self.storeName = response.storeName
    self.storeType = nil
    self.updatedAt = ""
    self.user = User()
    self.visitHistories = []
  }
  
  init(response: StoreDetailResponse) {
    self.appearanceDays = response.appearanceDays
    self.categories = response.categories
    self.distance = response.distance
    self.storeId = response.storeId
    self.images = response.images.map(Image.init)
    self.latitude = response.latitude
    self.longitude = response.longitude
    self.menus = response.menus.map(Menu.init)
    self.paymentMethods = response.paymentMethods
    self.rating = response.rating
    self.reviews = response.reviews.map(Review.init)
    self.storeName = response.storeName
    self.storeType = response.storeType
    self.updatedAt = response.updatedAt
    self.user = User(response: response.user)
    self.visitHistories = response.visitHistories.map { VisitHistory(response: $0) }
  }
}