protocol BookmarkViewerCoordinator: BaseCoordinator, AnyObject {
    func pushStoreDetail(storeId: String)
    
    func pushFoodTruckDetail(storeId: String)
    
    func presentSigninDialog()
    
    func goToMain(with folderId: String)
    
    func pushNickname(signinRequest: SigninRequest, bookmarkFolderId: String?)
}

extension BookmarkViewerCoordinator {
    func pushStoreDetail(storeId: String) {
        guard let storeId = Int(storeId) else { return }
        let viewController = StoreDetailViewController.instance(storeId: storeId)
        
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func pushFoodTruckDetail(storeId: String) {
        let viewController = BossStoreDetailViewController.instance(storeId: storeId)
        
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func presentSigninDialog() {
        let viewController = BookmarkSigninDialogViewController.instance()
        
        viewController.delegate = self as? BookmarkSigninDialogViewControllerDelegate
        self.presenter.present(viewController, animated: true)
    }
    
    func goToMain(with folderId: String) {
        let viewController = BookmarkViewerViewController.instance(folderId: folderId)
        let deeplinkContents = DeepLinkContents(
            targetViewController: viewController,
            transitionType: .present
        )
        
        self.presenter.dismiss(animated: true) {
            SceneDelegate.shared?.goToMain()
            DeeplinkManager.shared.reserveDeeplink(deeplinkContents: deeplinkContents)
        }
    }
    
    func pushNickname(signinRequest: SigninRequest, bookmarkFolderId: String?) {
        let viewController = NicknameViewController.instance(
            signinRequest: signinRequest,
            bookmarkFolderId: bookmarkFolderId
        )
        
        self.presenter.navigationController?.pushViewController(
            viewController,
            animated: true
        )
    }
}
