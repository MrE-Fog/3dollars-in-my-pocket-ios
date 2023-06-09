import Foundation

import RxSwift
import RxCocoa

class AddCategoryViewModel: BaseViewModel {
  
  let input = Input()
  let output = Output()
  
  var selectedCategory: [StreetFoodStoreCategory]
  let categories: [StreetFoodStoreCategory] = [
    .DALGONA,
    .BUNGEOPPANG,
    .KKOCHI,
    .EOMUK,
    .GUKWAPPANG,
    .GUNGOGUMA,
    .GYERANPPANG,
    .HOTTEOK,
    .GUNOKSUSU,
    .SUNDAE,
    .TAKOYAKI,
    .TOAST,
    .TTANGKONGPPANG,
    .TTEOKBOKKI,
    .WAFFLE,
  ]
  
  struct Input {
    let tapCategory = PublishSubject<IndexPath>()
    let tapSelectButton = PublishSubject<Void>()
  }
  
  struct Output {
    let buttonText = PublishRelay<String>()
    let buttonEnable = PublishRelay<Bool>()
    let category = PublishRelay<[(category: StreetFoodStoreCategory, isSelected: Bool)]>()
    let selectCategories = PublishRelay<[StreetFoodStoreCategory]>()
  }
  
  
  init(selectedCategory: [StreetFoodStoreCategory?]) {
    self.selectedCategory = selectedCategory.compactMap { $0 }
    super.init()
    
    self.input.tapCategory
      .map { self.categories[$0.row] }
      .bind(onNext: self.onTapCategory(category:))
      .disposed(by: disposeBag)
    
    self.input.tapSelectButton
      .map { self.selectedCategory }
      .bind(to: self.output.selectCategories)
      .disposed(by: disposeBag)
  }
  
  func fetchSelectedCategory() {
    Observable.just(self.categories)
      .map{ $0.map {($0, self.selectedCategory.contains($0))} }
      .bind(to: self.output.category)
      .disposed(by: disposeBag)
    Observable.just(self.selectedCategory)
      .map { String(format: "add_category_number_format".localized, $0.count) }
      .bind(to: self.output.buttonText)
      .disposed(by: disposeBag)
    Observable.just(self.selectedCategory)
      .map { !$0.isEmpty }
      .bind(to: self.output.buttonEnable)
      .disposed(by: disposeBag)
  }
  
  private func onTapCategory(category: StreetFoodStoreCategory) {
    if self.selectedCategory.contains(category) {
      self.selectedCategory.remove(at: self.selectedCategory.firstIndex(of: category)!)
    } else {
      self.selectedCategory.append(category)
    }
    self.fetchSelectedCategory()
  }
}
