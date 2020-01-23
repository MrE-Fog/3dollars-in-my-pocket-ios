import UIKit

protocol DeleteModalDelegate: class {
    func onTapClose()
    
    func onRequest()
}

class DeleteModalVC: BaseVC {
    
    weak var deleagete: DeleteModalDelegate?
    var storeId: Int!
    
    private lazy var deleteModalView = DeleteModalView(frame: self.view.frame).then {
        $0.delegate = self
    }
    
    static func instance(storeId: Int) -> DeleteModalVC {
        return DeleteModalVC(nibName: nil, bundle: nil).then {
            $0.modalPresentationStyle = .overCurrentContext
            $0.storeId = storeId
        }
    }
    
    override func viewDidLoad() {
        view = deleteModalView
    }
    
    override func bindViewModel() {
    }
    
    private func requestDelete() {
        StoreService.deleteStore(storeId: self.storeId) { [weak self] (response) in
            switch response.result {
            case .success(_):
                self?.deleagete?.onRequest()
            case .failure(let error):
                if let vc = self {
                    AlertUtils.show(controller: vc, title: "delete store error", message: error.localizedDescription)
                }
            }
        }
    }
}

extension DeleteModalVC: DeleteModalViewDelegate {
    func onTapRequest() {
        self.requestDelete()
    }
    
    func onTapClose() {
        self.deleagete?.onTapClose()
    }
}
