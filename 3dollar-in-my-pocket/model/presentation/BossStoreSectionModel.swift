import RxDataSources

struct BossStoreSectionModel: Equatable {
    var items: [Item]
}

extension BossStoreSectionModel: SectionModelType {
    typealias Item = SectionItemType
    
    enum SectionItemType: Equatable {
        case overview(BossStore)
        case info(snsUrl: String?, introduction: String?, imageUrl: String?)
        case menu(BossStoreMenu)
        case moreMenu([BossStoreMenu])
        case emptyMenu
        case appearanceDay([BossStoreAppearanceDay])
        case feedbacks([BossStoreFeedback])
    }
    
    init(original: BossStoreSectionModel, items: [Item]) {
        self = original
        self.items = items
    }
    
    init(store: BossStore) {
        self.items = [.overview(store)]
    }
    
    init(snsUrl: String?, introduction: String?, imageUrl: String?) {
        self.items = [.info(snsUrl: snsUrl, introduction: introduction, imageUrl: imageUrl)]
    }
    
    init(menus: [BossStoreMenu], showTotalMenus: Bool) {
        if menus.isEmpty {
            self.items = [.emptyMenu]
        } else if menus.count < 6 {
            self.items = menus.map { SectionItemType.menu($0) }
        } else {
            if showTotalMenus {
                self.items = menus.map { SectionItemType.menu($0) }
            } else {
                var sectionItemTypes = menus[..<5].map { SectionItemType.menu($0) }
                let moreItemType = SectionItemType.moreMenu(Array(menus[5...]))
                
                sectionItemTypes.append(moreItemType)
                self.items = sectionItemTypes
            }
        }
    }
    
    init(appearanceDays: [BossStoreAppearanceDay]) {
        self.items = [SectionItemType.appearanceDay(appearanceDays)]
    }
    
    init(feedbacks: [BossStoreFeedback]) {
        self.items = [SectionItemType.feedbacks(feedbacks)]
    }
}
