import UIKit

import RxSwift
import RxCocoa

final class OrderFilterButton: BaseView {
    fileprivate let orderType = PublishSubject<StoreOrder>()
    
    private let distanceOrderButton = UIButton().then {
        $0.setTitle("category_ordering_distance".localized, for: .normal)
        $0.setTitleColor(Color.pink, for: .selected)
        $0.setTitleColor(Color.gray40, for: .normal)
        $0.titleLabel?.font = .regular(size: 14)
        $0.isSelected = true
    }
    
    private let reviewOrderButton = UIButton().then {
        $0.setTitle("category_ordering_review".localized, for: .normal)
        $0.setTitleColor(Color.pink, for: .selected)
        $0.setTitleColor(Color.gray40, for: .normal)
        $0.titleLabel?.font = .regular(size: 14)
    }
    
    private let selectedContainer = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 10
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 2, height: 2)
        $0.layer.shadowOpacity = 0.08
    }
    
    init(storeType: StoreType) {
        super.init(frame: .zero)
        
        if storeType == .streetFood {
            self.distanceOrderButton.setTitleColor(Color.pink, for: .selected)
            self.reviewOrderButton.setTitleColor(Color.pink, for: .selected)
        } else {
            self.distanceOrderButton.setTitleColor(Color.green, for: .selected)
            self.reviewOrderButton.setTitleColor(Color.green, for: .selected)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setup() {
        self.layer.cornerRadius = 12
        self.backgroundColor = Color.gray5
        self.addSubViews([
            self.selectedContainer,
            self.distanceOrderButton,
            self.reviewOrderButton
        ])
        
        self.distanceOrderButton.rx.tap
            .map { StoreOrder.distance }
            .do(onNext: { [weak self] order in
                self?.selectOrder(order: order)
            })
                .bind(to: self.orderType)
                .disposed(by: self.disposeBag)
                
                self.reviewOrderButton.rx.tap
                .map { StoreOrder.review }
                .do(onNext: { [weak self] order in
                    self?.selectOrder(order: order)
                })
                    .bind(to: self.orderType)
                    .disposed(by: self.disposeBag)
                    }
    
    override func bindConstraints() {
        self.distanceOrderButton.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalTo(self.snp.centerX)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        self.reviewOrderButton.snp.makeConstraints { make in
            make.left.equalTo(self.snp.centerX)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        self.selectedContainer.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(5)
            make.right.equalTo(self.snp.centerX).offset(-5)
            make.top.equalToSuperview().offset(5)
            make.bottom.equalToSuperview().offset(-5)
        }
        
        self.snp.makeConstraints { make in
            make.width.equalTo(140)
            make.height.equalTo(44)
        }
    }
    
    private func selectOrder(order: StoreOrder) {
        self.distanceOrderButton.isSelected = order == .distance
        self.reviewOrderButton.isSelected = order == .review
        switch order {
        case .distance:
            self.selectedContainer.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(5)
                make.right.equalTo(self.snp.centerX).offset(-5)
                make.top.equalToSuperview().offset(5)
                make.bottom.equalToSuperview().offset(-5)
            }
            
        case .review:
            self.selectedContainer.snp.remakeConstraints { make in
                make.left.equalTo(self.snp.centerX).offset(5)
                make.right.equalToSuperview().offset(-5)
                make.top.equalToSuperview().offset(5)
                make.bottom.equalToSuperview().offset(-5)
            }
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.layoutIfNeeded()
        }
    }
}

extension Reactive where Base: OrderFilterButton {
    var orderType: ControlEvent<StoreOrder> {
        return ControlEvent(events: base.orderType)
    }
}
