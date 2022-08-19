import UIKit
import RxSwift

class TabBarVC: UITabBarController {
    private let feedbackGenerator = UISelectionFeedbackGenerator()
    private let disposeBag = DisposeBag()
    private let loadingView = LoadingView()
    private lazy var dimView = UIView(frame: self.view.frame).then {
        $0.backgroundColor = .clear
    }
    
    
    deinit {
        self.removeKakaoLinkObserver()
    }
    
    static func instance() -> TabBarVC {
        return TabBarVC(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkIfBannerExisted()
        self.setupTabBarController()
        self.addKakaoLinkObserver()
        self.feedbackGenerator.prepare()
        self.delegate = self
        if #available(iOS 15, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            self.tabBar.standardAppearance = appearance
            self.tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.processKakaoLinkIfExisted()
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        self.feedbackGenerator.selectionChanged()
        switch item.tag {
        case TabBarTag.my.rawValue:
            self.tabBar.barTintColor = R.color.gray100()
            if #available(iOS 15, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = R.color.gray100()
                self.tabBar.standardAppearance = appearance
                self.tabBar.scrollEdgeAppearance = appearance
            }
        case TabBarTag.home.rawValue, TabBarTag.streetFood.rawValue:
            self.tabBar.barTintColor = .white
            if #available(iOS 15, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .white
                self.tabBar.standardAppearance = appearance
                self.tabBar.scrollEdgeAppearance = appearance
            }
        default:
            break
        }
    }
    
    func showLoading(isShow: Bool) {
        if isShow {
            self.view.addSubview(loadingView)
            self.loadingView.snp.makeConstraints { (make) in
                make.edges.equalTo(0)
            }
            self.view.isUserInteractionEnabled = false
            self.loadingView.startLoading()
        } else {
            self.loadingView.stopLoading()
            self.view.isUserInteractionEnabled = true
            self.loadingView.removeFromSuperview()
        }
    }
    
    func showDim(isShow: Bool) {
        if isShow {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.view.addSubview(self.dimView)
                UIView.animate(withDuration: 0.3) {
                    self.dimView.backgroundColor = UIColor.init(r: 0, g: 0, b: 0, a: 0.5)
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3, animations: {
                    self.dimView.backgroundColor = .clear
                }) { (_) in
                    self.dimView.removeFromSuperview()
                }
            }
        }
    }
    
    private func setupTabBarController() {
        self.setViewControllers([
            HomeViewController.instance(),
            StreetFoodListViewController.instance(),
            WriteAddressViewController.instance(delegate: self),
            MyPageViewController.instance()
        ], animated: true)
        self.tabBar.tintColor = R.color.red()
        self.tabBar.layer.borderWidth = 0
        self.tabBar.layer.borderColor = UIColor.clear.cgColor
        self.tabBar.clipsToBounds = true
        self.tabBar.barTintColor = .white
    }
    
    private func addKakaoLinkObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.processKakaoLinkIfExisted()
        }
    }
    
    private func removeKakaoLinkObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func processKakaoLinkIfExisted() {
        let kakaoShareLink = UserDefaultsUtil().shareLink
        guard !kakaoShareLink.isEmpty else { return }
        let storeType = kakaoShareLink.split(separator: ":").first ?? "foodTruck"
        let storeId = kakaoShareLink.split(separator: ":").last ?? ""
        
        if storeType ==  "foodTruck" {
            self.pushBossStoreDetail(storeId: String(storeId))
        } else {
            self.goToStoreDetail(storeId: Int(storeId) ?? 0)
        }
    }
    
    private func goToStoreDetail(storeId: Int) {
        self.selectedIndex = 0
        if let navigationVC = self.viewControllers?[0] as? UINavigationController,
           let homeVC = navigationVC.topViewController as? HomeViewController {
            homeVC.coordinator?.pushStoreDetail(storeId: String(storeId))
        }
    }
    
    private func pushBossStoreDetail(storeId: String) {
        self.selectedIndex = 0
        if let navigationVC = self.viewControllers?[0] as? UINavigationController,
           let homeVC = navigationVC.topViewController as? HomeViewController {
            homeVC.coordinator?.pushBossStoreDetail(storeId: storeId)
        }
    }
    
    private func checkIfBannerExisted() {
        AdvertisementService().fetchAdvertisements(position: .splash)
            .map { $0.map { Advertisement.init(response: $0)} }
            .subscribe(
                onNext: { [weak self] advertisements in
                    if !advertisements.isEmpty {
                        if let isDisable
                            = UserDefaultsUtil.getEventDisableToday(id: advertisements[0].id) {
                            if isDisable != DateUtils.todayString() {
                                // 다시보기 설정한 날짜가 오늘이 아니라면 팝업띄우기
                                self?.present(
                                    PopupViewController.instance(advertisement: advertisements[0]),
                                    animated: false
                                )
                            }
                        } else {
                            self?.present(
                                PopupViewController.instance(advertisement: advertisements[0]),
                                animated: false
                            )
                        }
                    }
                })
            .disposed(by: self.disposeBag)
    }
}

extension TabBarVC: WriteAddressDelegate {
    func onWriteSuccess(storeId: Int) {
        self.selectedIndex = 0
        if let navigationVC = self.viewControllers?[0] as? UINavigationController,
           let homeVC = navigationVC.viewControllers[0] as? HomeViewController {
            navigationVC.popToRootViewController(animated: false)
//            homeVC.fetchStoresFromCurrentLocation()
            homeVC.coordinator?.pushStoreDetail(storeId: String(storeId))
        }
    }
}

extension TabBarVC: UITabBarControllerDelegate {
    
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        if let navigationVC = viewController as? UINavigationController {
            if navigationVC.topViewController is WriteAddressViewController {
                let writeVC = WriteAddressViewController.instance(delegate: self)
                
                self.present(writeVC, animated: true, completion: nil)
                return false
            }
        }
        return true
    }
}
