import RxSwift
import FirebaseMessaging

protocol DeviceServiceProtocol {
    func registerDevice(
        pushPlatformType: PushPlatformType,
        pushSettings: [PushSettingType],
        pushToken: String
    ) -> Observable<String>
    
    func getFCMToken() -> Observable<String>
}

struct DeviceService: DeviceServiceProtocol {
    private let networkManager = NetworkManager()
    
    func registerDevice(
        pushPlatformType: PushPlatformType,
        pushSettings: [PushSettingType],
        pushToken: String
    ) -> Observable<String> {
        let urlString = HTTPUtils.url + "/api/v1/device"
        let headers = HTTPUtils.defaultHeader()
        let registerUserDeviceRequest = RegisterUserDeviceRequest(
            pushPlatformType: pushPlatformType,
            pushSettings: pushSettings,
            pushToken: pushToken
        )
        
        return self.networkManager.createPostObservable(
            class: String.self,
            urlString: urlString,
            headers: headers,
            parameters: registerUserDeviceRequest.params
        )
    }
    
    func getFCMToken() -> Observable<String> {
        return .create { observer in
            Messaging.messaging().token { token, error in
                if let error = error {
                    observer.onError(error)
                } else if let token = token {
                    observer.onNext(token)
                    observer.onCompleted()
                } else {
                    observer.onError(BaseError.unknown)
                }
            }
            
            return Disposables.create()
        }
    }
}
