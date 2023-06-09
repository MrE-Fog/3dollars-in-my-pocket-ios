import UIKit

final class CategoryFilterCell: BaseCollectionViewCell {
    static let registerId = "\(CategoryFilterCell.self)"
    static let size = CGSize(
        width: (UIScreen.main.bounds.width - 48 - 22)/3,
        height: (UIScreen.main.bounds.width - 48 - 22)/3 + 9
    )
    
    private let newLabel = UILabel().then {
        $0.text = "new"
        $0.font = .semiBold(size: 12)
        $0.textColor = .white
        $0.textAlignment = .center
        $0.backgroundColor = Color.red
        $0.layer.masksToBounds = true
        $0.layer.cornerRadius = 9
        $0.layer.shadowColor = UIColor(r: 255, g: 92, b: 67, a: 0.5).cgColor
        $0.layer.shadowOffset = CGSize(width: 2, height: 2)
    }
    
    private let containerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 17
    }
    
    private let categoryImage = UIImageView()
    
    private let categoryLabel = UILabel().then {
        $0.font = .extraBold(size: 14)
        $0.textColor = .black
        $0.textAlignment = .center
    }
    
    override func setup() {
        self.backgroundColor = .clear
        self.addSubViews([
            self.containerView,
            self.newLabel,
            self.categoryImage,
            self.categoryLabel
        ])
    }
    
    override func bindConstraints() {
        self.newLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(18)
            make.width.equalTo(32)
        }
        
        self.containerView.snp.makeConstraints { make in
            make.top.equalTo(self.newLabel).offset(9)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(Self.size.width)
        }
        
        self.categoryImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.containerView).offset(10)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        self.categoryLabel.snp.makeConstraints { make in
            make.left.equalTo(self.containerView).offset(10)
            make.right.equalTo(self.containerView).offset(-10)
            make.top.equalTo(self.categoryImage.snp.bottom).offset(4)
        }
    }
    
    func bind(category: Categorizable) {
        if let streetFoodCategory = category as? StreetFoodCategory {
            self.categoryLabel.text = streetFoodCategory.name
            self.categoryImage.setImage(urlString: streetFoodCategory.imageUrl)
            self.newLabel.isHidden = !streetFoodCategory.isNew
        } else if let foodtruckCategory = category as? FoodTruckCategory {
            self.categoryLabel.text = foodtruckCategory.name
            self.categoryImage.setImage(urlString: foodtruckCategory.imageUrl)
            self.newLabel.isHidden = true
        }
    }
}
