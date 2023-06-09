protocol WriteAddressCoordinator: AnyObject, Coordinator {
    func goToWriteDetail(address: String, location: (Double, Double))
    
    func presentConfirmPopup(address: String)
}

extension WriteAddressCoordinator where Self: BaseVC {
    func goToWriteDetail(address: String, location: (Double, Double)) {
        let viewController = WriteDetailVC.instance(address: address, location: location)
        
        viewController.deleagte = self as? WriteDetailDelegate
        
        self.presenter.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func presentConfirmPopup(address: String) {
        let viewController = AddressConfirmPopupViewController.instacne(address: address)
        
        viewController.delegate = self as? AddressConfirmPopupViewControllerDelegate
        self.showRootDim(isShow: true)
        self.presenter.present(viewController, animated: true, completion: nil)
    }
}
