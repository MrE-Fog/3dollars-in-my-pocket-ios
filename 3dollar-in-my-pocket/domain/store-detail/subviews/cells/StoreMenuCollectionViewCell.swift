import UIKit

import RxSwift
import RxCocoa

final class StoreMenuCollectionViewCell: BaseCollectionViewCell {
    static let registerId = "\(StoreMenuCollectionViewCell.self)"
    static let estimatedHeight: CGFloat = 200
    
    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .bold(size: 16)
        $0.textColor = Color.black
        $0.text = "store_detail_menu".localized
    }
    
    private let countLabel = UILabel().then {
        $0.font = .medium(size: 16)
        $0.textColor = Color.black
    }
    
    private let menuStackView = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .equalSpacing
        $0.backgroundColor = .clear
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.addSubViews([
            self.containerView,
            self.titleLabel,
            self.countLabel,
            self.menuStackView
        ])
    }
    
    override func bindConstraints() {
        self.containerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(12)
            make.bottom.equalTo(self.menuStackView).offset(16)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(16)
            make.top.equalTo(self.containerView).offset(24)
        }
        
        self.countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.left.equalTo(self.titleLabel.snp.right).offset(2)
        }
        
        self.menuStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(14)
        }
        
        self.snp.makeConstraints { make in
            make.top.equalTo(self.containerView).offset(-12).priority(.high)
            make.bottom.equalTo(self.containerView).priority(.high)
        }
    }
    
    func bind(store: Store) {
        self.countLabel.text
        = String(format: "store_detail_menu_format".localized, store.menus.count)
        self.clearMenuStackView()
        
        let subViews = self.generateMenuViews(
            categories: store.categories,
            menus: store.menus
        )
        
        for subView in subViews {
            self.menuStackView.addArrangedSubview(subView)
        }
    }
    
    private func clearMenuStackView() {
        self.menuStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    private func generateMenuViews(
        categories: [StreetFoodStoreCategory],
        menus: [Menu]
    ) -> [UIView] {
        var subViews: [UIView] = []
        let sortedCategories = categories.sorted { (category1, category2) -> Bool in
            let countOfCategory1 = menus.filter { $0.category == category1 }.count
            let countOfCategory2 = menus.filter { $0.category == category2 }.count
            
            return countOfCategory1 > countOfCategory2
        }
        
        for category in sortedCategories {
            let categoryView = StoreDetailMenuCategoryView()
            var menuSubViews: [UIView] = []
            
            for menu in menus {
                if menu.category == category && !menu.name.isEmpty {
                    let menuView = StoreDetailMenuView()
                    
                    menuView.bind(menu: menu)
                    menuSubViews.append(menuView)
                }
            }
            categoryView.bind(category: category, isEmpty: menuSubViews.isEmpty)
            subViews.append(categoryView)
            subViews += menuSubViews
        }
        
        return subViews
    }
}
