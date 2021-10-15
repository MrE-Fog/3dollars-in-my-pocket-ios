import UIKit

class CategoryCell: BaseCollectionViewCell {
  
  static let registerId = "\(CategoryCell.self)"
  
  let newLabel = UILabel().then {
    $0.text = "new"
    $0.font = .semiBold(size: 12)
    $0.textColor = .white
    $0.textAlignment = .center
    $0.backgroundColor = R.color.red()
    $0.layer.masksToBounds = true
    $0.layer.cornerRadius = 9
    $0.layer.shadowColor = UIColor(r: 255, g: 92, b: 67, a: 0.5).cgColor
    $0.layer.shadowOffset = CGSize(width: 2, height: 2)
  }
  
  let categoryImage = UIImageView()
  
  let categoryLabel = UILabel().then {
    $0.font = UIFont(name: "AppleSDGothicNeoEB00", size: 14)
    $0.textColor = .black
  }
  
  
  override func setup() {
    self.backgroundColor = .white
    self.layer.cornerRadius = 17
    self.addSubViews(
      self.newLabel,
      categoryImage,
      categoryLabel
    )
  }
  
  override func bindConstraints() {
    self.newLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(-9)
      make.height.equalTo(18)
      make.width.equalTo(32)
    }
    
    self.categoryImage.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(10 * RatioUtils.heightRatio)
    }
    
    self.categoryLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.categoryImage.snp.bottom).offset(4)
    }
  }
  
  func bind(category: StoreCategory) {
    self.categoryLabel.text = category.name
    self.categoryImage.image = category.image
    self.newLabel.isHidden = category != .DALGONA
  }
}