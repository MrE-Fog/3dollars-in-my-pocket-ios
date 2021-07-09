import RxSwift
import RxCocoa

class SplashViewModel: BaseViewModel {
  
  let input = Input()
  let output = Output()
  let userDefaults: UserDefaultsUtil
  let userService: UserServiceProtocol
  
  struct Input {
    let viewDidLoad = PublishSubject<Void>()
  }
  
  struct Output {
    let goToSignIn = PublishRelay<Void>()
    let goToMain = PublishRelay<Void>()
    let showGoToSignInAlert = PublishRelay<AlertContent>()
    let showMaintenanceAlert = PublishRelay<AlertContent>()
  }
  
  
  init(userDefaults: UserDefaultsUtil, userService: UserServiceProtocol) {
    self.userDefaults = userDefaults
    self.userService = userService
    super.init()
    
    self.input.viewDidLoad
      .bind(onNext: self.validateToken)
      .disposed(by: self.disposeBag)
  }
  
  private func validateToken() {
    
  }
  
  private func validateUserDefaultsToken() {
    let token = self.userDefaults.getUserToken()
    if !token.isEmpty {
      self.validateTokenFromServer(token: token)
    } else {
      self.output.goToSignIn.accept(())
    }
  }
  
  private func validateTokenFromServer(token: String) {
    self.userService.validateToken(token: token)
      .map { _ in Void() }
      .subscribe(
        onNext: self.output.goToMain.accept(_:),
        onError: self.handelValidationError(error:)
      )
      .disposed(by: disposeBag)
  }
  
  private func handelValidationError(error: Error) {
    if let httpError = error as? HTTPError {
      switch httpError {
      case .forbidden, .unauthorized:
        let alertContent = AlertContent(title: nil, message: httpError.description)
        
        self.output.showGoToSignInAlert.accept(alertContent)
      case .maintenance:
        let alertContent = AlertContent(title: nil, message: httpError.description)
        
        self.output.showMaintenanceAlert.accept(alertContent)
      default:
        self.httpErrorAlert.accept(httpError)
      }
    } else if let error = error as? CommonError {
      let alertContent = AlertContent(title: nil, message: error.description)
      
      self.showSystemAlert.accept(alertContent)
    }
  }
}
