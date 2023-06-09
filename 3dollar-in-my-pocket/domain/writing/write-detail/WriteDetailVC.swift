import UIKit

import NMapsMap
import RxSwift
import RxDataSources

protocol WriteDetailDelegate: class {
  func onWriteSuccess(storeId: Int)
}

class WriteDetailVC: BaseVC {
  
  weak var deleagte: WriteDetailDelegate?
  
  private lazy var writeDetailView = WriteDetailView(frame: self.view.frame)
  let viewModel: WriteDetailViewModel
  var menuDataSource: RxTableViewSectionedReloadDataSource<MenuSection>!
  
  init(address: String, location: (Double, Double)) {
    self.viewModel = WriteDetailViewModel(
      address: address,
      location: location,
      storeService: StoreService(),
      globalState: GlobalState.shared
    )
    super.init(nibName: nil, bundle: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
    self.writeDetailView.menuTableView.removeObserver(self, forKeyPath: "contentSize")
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  static func instance(
    address: String,
    location: (Double, Double)
  ) -> WriteDetailVC {
    return WriteDetailVC(address: address, location: location)
  }
  
  override func viewDidLoad() {
    self.setupMenuTableView()
    self.setupCategoryCollectionView()
    self.setupKeyboardEvent()
    
    super.viewDidLoad()
    view = writeDetailView
    self.writeDetailView.scrollView.delegate = self
    self.viewModel.fetchInitialData()
    self.addObservers()
  }
  
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey : Any]?,
    context: UnsafeMutableRawPointer?
  ) {
    if let obj = object as? UITableView {
      if obj == self.writeDetailView.menuTableView && keyPath == "contentSize" {
        self.writeDetailView.refreshMenuTableViewHeight()
      }
    }
  }
  
  override func bindViewModel() {
    // Bind input
    self.writeDetailView.storeNameField.rx.text.orEmpty
      .bind(to: self.viewModel.input.storeName)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.sundayButton.rx.tap
      .map { WeekDay.sunday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.mondayButton.rx.tap
      .map { WeekDay.monday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.tuesdayButton.rx.tap
      .map { WeekDay.tuesday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.wednesday.rx.tap
      .map { WeekDay.wednesday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.thursday.rx.tap
      .map { WeekDay.thursday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.friday.rx.tap
      .map { WeekDay.friday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.dayStackView.saturday.rx.tap
      .map { WeekDay.saturday }
      .bind(to: self.viewModel.input.tapDay)
      .disposed(by: disposeBag)
    
    self.writeDetailView.storeTypeStackView.roadRadioButton.rx.tap
      .map { StreetFoodStoreType.road }
      .bind(to: self.viewModel.input.tapStoreType)
      .disposed(by: disposeBag)
    
    self.writeDetailView.storeTypeStackView.storeRadioButton.rx.tap
      .map { StreetFoodStoreType.store }
      .bind(to: self.viewModel.input.tapStoreType)
      .disposed(by: disposeBag)
    
    self.writeDetailView.storeTypeStackView.convenienceStoreRadioButton.rx.tap
      .map { StreetFoodStoreType.convenienceStore }
      .bind(to: self.viewModel.input.tapStoreType)
      .disposed(by: disposeBag)
    
    self.writeDetailView.paymentStackView.cashCheckButton.rx.tap
      .map { PaymentType.cash }
      .bind(to: self.viewModel.input.tapPaymentType)
      .disposed(by: disposeBag)
    
    self.writeDetailView.paymentStackView.cardCheckButton.rx.tap
      .map { PaymentType.card }
      .bind(to: self.viewModel.input.tapPaymentType)
      .disposed(by: disposeBag)
    
    self.writeDetailView.paymentStackView.transferCheckButton.rx.tap
      .map { PaymentType.transfer }
      .bind(to: self.viewModel.input.tapPaymentType)
      .disposed(by: disposeBag)
    
    self.writeDetailView.deleteAllButton.rx.tap
      .bind(to: self.viewModel.input.deleteAllCategories)
      .disposed(by: disposeBag)
    
    self.writeDetailView.registerButton.rx.tap
      .bind(to: self.viewModel.input.tapRegister)
      .disposed(by: disposeBag)
    
    // Bind output
    self.viewModel.output.address
      .bind(to: self.writeDetailView.locationValueLabel.rx.text)
      .disposed(by: disposeBag)
    
    self.viewModel.output.storeNameIsEmpty
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeDetailView.setStoreNameBorderColoe(isEmpty:))
      .disposed(by: disposeBag)
    
    self.viewModel.output.selectType
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeDetailView.storeTypeStackView.selectType(type:))
      .disposed(by: disposeBag)
    
    self.viewModel.output.selectPaymentType
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeDetailView.paymentStackView.selectPaymentType(paymentTypes:))
      .disposed(by: disposeBag)
    
    self.viewModel.output.selectDays
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.writeDetailView.dayStackView.selectDays(weekDays:))
      .disposed(by: disposeBag)
    
    self.viewModel.output.categories
      .bind(to: self.writeDetailView.categoryCollectionView.rx.items(cellIdentifier: WriteCategoryCell.registerId, cellType: WriteCategoryCell.self)) { row, category, cell in
        cell.bind(category: category)
        self.writeDetailView.refreshCategoryCollectionViewHeight()
      }
      .disposed(by: disposeBag)
    
    self.viewModel.output.showCategoryDialog
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showCategoryDialog(selectedCategories:))
      .disposed(by: disposeBag)
    
    self.viewModel.output.menus
      .do(onNext: self.writeDetailView.setMenuHeader)
      .bind(to: self.writeDetailView.menuTableView.rx.items(dataSource:self.menuDataSource))
      .disposed(by: disposeBag)
    
    self.viewModel.output.registerButtonIsEnable
      .bind(to: self.writeDetailView.registerButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    self.viewModel.output.dismissAndGoDetail
      .observeOn(MainScheduler.instance)
      .bind(onNext: dismissAndGoDetail)
      .disposed(by: disposeBag)
    
    self.viewModel.output.showLoading
      .observeOn(MainScheduler.instance)
          .bind(onNext: { isShow in
              LoadingManager.shared.showLoading(isShow: isShow)
          })
      .disposed(by: disposeBag)
    
    self.viewModel.httpErrorAlert
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showHTTPErrorAlert(error:))
      .disposed(by: disposeBag)
    
    self.viewModel.showSystemAlert
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.showSystemAlert(alert:))
      .disposed(by: disposeBag)
  }
  
  override func bindEvent() {
    self.writeDetailView.bgTap.rx.event
      .subscribe { [weak self] event in
        self?.writeDetailView.endEditing(true)
      }.disposed(by: disposeBag)
    
    self.writeDetailView.backButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.popupVC)
      .disposed(by: disposeBag)
    
    self.writeDetailView.modifyLocationButton.rx.tap
      .observeOn(MainScheduler.instance)
      .bind(onNext: self.popupVC)
      .disposed(by: disposeBag)
  }
  
  private func addObservers() {
    self.writeDetailView.menuTableView.addObserver(
      self,
      forKeyPath: "contentSize",
      options: .new,
      context: nil
    )
  }
  
  private func popupVC() {
    self.navigationController?.popViewController(animated: true)
  }
  
  private func isValid(category: StreetFoodStoreCategory?, storeName: String) -> Bool {
    return category != nil && !storeName.isEmpty
  }
  
  private func setupCategoryCollectionView() {
    self.writeDetailView.categoryCollectionView.register(
      WriteCategoryCell.self,
      forCellWithReuseIdentifier: WriteCategoryCell.registerId
    )
    self.writeDetailView.categoryCollectionView.rx
      .setDelegate(self)
      .disposed(by: disposeBag)
    self.writeDetailView.categoryCollectionView.rx.itemSelected
      .bind { [weak self] indexPath in
        guard let self = self else { return }
        if indexPath.row == 0 {
          self.viewModel.input.tapAddCategory.onNext(())
        } else {
          self.viewModel.input.deleteCategory.onNext(indexPath.row - 1)
        }
      }
      .disposed(by: disposeBag)
  }
  
  private func setupMenuTableView() {
    self.writeDetailView.menuTableView.register(
      MenuCell.self,
      forCellReuseIdentifier: MenuCell.registerId
    )
    self.writeDetailView.menuTableView.rx
      .setDelegate(self)
      .disposed(by: disposeBag)
    self.menuDataSource = RxTableViewSectionedReloadDataSource<MenuSection> { (dataSource, tableView, indexPath, item) in
      guard let cell = tableView.dequeueReusableCell(
        withIdentifier: MenuCell.registerId,
        for: indexPath
      ) as? MenuCell else { return BaseTableViewCell() }
      
      cell.setMenu(menu: item)
      cell.nameField.rx.controlEvent(.editingDidEnd)
        .withLatestFrom(cell.nameField.rx.text.orEmpty)
        .map { (indexPath, $0) }
        .bind(to: self.viewModel.input.menuName)
        .disposed(by: cell.disposeBag)
        
      cell.descField.rx.controlEvent(.editingDidEnd)
        .withLatestFrom(cell.descField.rx.text.orEmpty)
        .map { (indexPath, $0) }
        .bind(to: self.viewModel.input.menuPrice)
        .disposed(by: cell.disposeBag)
        
      return cell
    }
  }
  
  private func setupKeyboardEvent() {
    NotificationCenter.default.addObserver(self, selector: #selector(onShowKeyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(onHideKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  }
  
  private func showCategoryDialog(selectedCategories: [StreetFoodStoreCategory?]) {
    let addCategoryVC = AddCategoryVC.instance(selectedCategory: selectedCategories).then {
      $0.delegate = self
    }
    
    self.writeDetailView.showDim(isShow: true)
    self.present(addCategoryVC, animated: true, completion: nil)
  }
  
  private func dismissAndGoDetail(storeId: Int) {
    self.dismiss(animated: true, completion: nil)
    self.deleagte?.onWriteSuccess(storeId: storeId)
  }
  
  @objc func onShowKeyboard(notification: NSNotification) {
    let userInfo = notification.userInfo!
    var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
    keyboardFrame = self.view.convert(keyboardFrame, from: nil)
    
    var contentInset:UIEdgeInsets = self.writeDetailView.scrollView.contentInset
    contentInset.bottom = keyboardFrame.size.height + 50
    self.writeDetailView.scrollView.contentInset = contentInset
  }
  
  @objc func onHideKeyboard(notification: NSNotification) {
    let contentInset:UIEdgeInsets = UIEdgeInsets.zero
    
    self.writeDetailView.scrollView.contentInset = contentInset
  }
}

extension WriteDetailVC: UIScrollViewDelegate {
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.writeDetailView.endEditing(true)
    self.writeDetailView.hideRegisterButton()
  }
  
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      self.writeDetailView.showRegisterButton()
    }
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    self.writeDetailView.showRegisterButton()
  }
}

extension WriteDetailVC: AddCategoryDelegate {
  
  func onDismiss() {
    self.writeDetailView.showDim(isShow: false)
  }
  
  func onSuccess(selectedCategories: [StreetFoodStoreCategory]) {
    self.viewModel.input.addCategories.onNext(selectedCategories)
    self.writeDetailView.showDim(isShow: false)
  }
}

extension WriteDetailVC: UITableViewDelegate {
  func tableView(
    _ tableView: UITableView,
    viewForHeaderInSection section: Int
  ) -> UIView? {
    let menuHeaderView = MenuHeaderView().then {
      $0.frame = CGRect(
        x: 0,
        y: 0,
        width: tableView.frame.width,
        height: 56
      )
    }
    let sectionCategory = self.menuDataSource.sectionModels[section].category ?? .BUNGEOPPANG
    
    menuHeaderView.bind(category: sectionCategory)
    menuHeaderView.deleteButton.rx.tap
      .map { section }
      .subscribe(onNext: (self.viewModel.input.deleteCategory.onNext))
      .disposed(by: menuHeaderView.disposeBag)
    
    return menuHeaderView
  }
  
  func tableView(
    _ tableView: UITableView,
    heightForFooterInSection section: Int
  ) -> CGFloat {
    return 20
  }
  
  func tableView(
    _ tableView: UITableView,
    viewForFooterInSection section: Int
  ) -> UIView? {
    return MenuFooterView(frame: CGRect(
      x: 0,
      y: 0,
      width: tableView.frame.width,
      height: 20
    ))
  }
}
