import UIKit
import GoogleMobileAds
import NMapsMap

final class CategoryListView: BaseView {
  
  private let navigationView = UIView().then {
    $0.layer.cornerRadius = 20
    $0.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
    $0.layer.shadowOffset = CGSize(width: 0, height: 4)
    $0.layer.shadowColor = UIColor.black.cgColor
    $0.layer.shadowOpacity = 0.04
    $0.backgroundColor = .white
  }
  
  let backButton = UIButton().then {
    $0.setImage(R.image.ic_back_black(), for: .normal)
  }
  
  private let titleStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
  }
  
  private let categoryImage = UIImageView()
  
  private let categoryLabel = UILabel().then {
    $0.font = .bold(size: 16)
    $0.textColor = .black
  }
  
  private let scrollView = UIScrollView()
  
  private let containerView = UIView()
  
  let mapView = NMFMapView()
  
  let currentLocationButton = UIButton().then {
    $0.setImage(R.image.ic_current_location(), for: .normal)
  }
  
  private let categoryTitleLabel = UILabel().then {
    $0.font = UIFont(name: "AppleSDGothicNeo-Light", size: 24)
    $0.textColor = .black
    $0.numberOfLines = 0
  }
  
  let certificatedButton = CertificateButton()
  
  let orderFilterButton = OrderFilterButton()
  
  let storeTableView = UITableView().then {
    $0.tableFooterView = UIView()
    $0.rowHeight = CategoryListStoreCell.height
    $0.separatorStyle = .none
    $0.showsVerticalScrollIndicator = false
  }
  
  private let emptyImage = UIImageView().then {
    $0.image = R.image.img_empty()
    $0.isHidden = true
  }
  
  private let emptyLabel = UILabel().then {
    $0.text = R.string.localization.category_list_empty()
    $0.textColor = R.color.gray1()
    $0.font = .bold(size: 16)
    $0.isHidden = true
  }
  
  
  override func setup() {
    self.backgroundColor = R.color.gray0()
    self.titleStackView.addArrangedSubview(self.categoryImage)
    self.titleStackView.addArrangedSubview(self.categoryLabel)
    self.addSubViews([
      self.scrollView,
      self.navigationView,
      self.backButton,
      self.titleStackView
    ])
    
    self.scrollView.addSubview(self.containerView)
    self.containerView.addSubViews([
      self.mapView,
      self.currentLocationButton,
      self.categoryTitleLabel,
      self.certificatedButton,
      self.orderFilterButton,
      self.storeTableView,
      self.emptyImage,
      self.emptyLabel
    ])
  }
  
  override func bindConstraints() {
    self.navigationView.snp.makeConstraints { make in
      make.left.right.top.equalToSuperview()
      make.bottom.equalTo(self.safeAreaLayoutGuide.snp.top).offset(60)
    }
    
    self.backButton.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(24)
      make.bottom.equalTo(self.navigationView).offset(-21)
    }
    
    self.titleStackView.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalTo(self.backButton)
    }
    
    self.categoryImage.snp.makeConstraints { make in
      make.width.height.equalTo(32)
    }
    
    self.scrollView.snp.makeConstraints { make in
      make.left.equalToSuperview()
      make.right.equalToSuperview()
      make.top.equalTo(self.navigationView.snp.bottom).offset(-20)
      make.bottom.equalToSuperview()
    }
    
    self.containerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width)
      make.top.equalTo(self.mapView).priority(.high)
      make.bottom.equalTo(self.storeTableView).priority(.high)
    }
    
    self.mapView.snp.makeConstraints { make in
      make.left.right.equalToSuperview()
      make.top.equalToSuperview()
      make.height.equalTo(339 * RatioUtils.heightRatio)
    }
    
    self.currentLocationButton.snp.makeConstraints { (make) in
      make.right.equalTo(self.mapView.snp.right).offset(-24)
      make.bottom.equalTo(self.mapView.snp.bottom).offset(-15)
      make.width.height.equalTo(48)
    }
    
    self.categoryTitleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(24)
      make.right.equalToSuperview().offset(-129)
      make.top.equalTo(self.mapView.snp.bottom).offset(32)
    }
    
    self.certificatedButton.snp.makeConstraints { make in
      make.left.equalToSuperview().offset(24)
      make.top.equalTo(self.categoryTitleLabel.snp.bottom).offset(14)
    }
    
    self.orderFilterButton.snp.makeConstraints { make in
      make.top.equalTo(self.certificatedButton)
      make.bottom.equalTo(self.certificatedButton)
      make.left.equalTo(self.certificatedButton.snp.right).offset(12)
    }
    
    self.storeTableView.snp.makeConstraints { make in
      make.top.equalTo(self.certificatedButton.snp.bottom).offset(16)
      make.left.right.equalToSuperview()
      make.height.equalTo(0)
    }
    
    self.emptyImage.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.categoryTitleLabel.snp.bottom).offset(32)
    }
    
    self.emptyLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.top.equalTo(self.emptyImage.snp.bottom).offset(8)
    }
  }
  
  func bind(category: StoreCategory) {
    self.categoryImage.image = category.image
    self.categoryLabel.text = category.name
    
    let text = "category_list_\(category.lowcase)".localized
    let attributedString = NSMutableAttributedString(string: text)
    let boldTextRange = (text as NSString).range(of: "shared_category_\(category.lowcase)".localized)
    
    attributedString.addAttribute(
      .font,
      value: UIFont(name: "AppleSDGothicNeoEB00", size: 24)!,
      range: boldTextRange
    )
    attributedString.addAttribute(
      .kern,
      value: -1.2,
      range: .init(location: 0, length: text.count)
    )
    self.categoryTitleLabel.attributedText = attributedString
  }
}
