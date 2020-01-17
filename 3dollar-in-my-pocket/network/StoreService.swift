import Alamofire
import ObjectMapper
import UIKit

struct StoreService: APIServiceType {
    
    
    static func getStoreOrderByNearest(latitude: Double, longitude: Double,
                                       completion: @escaping (DataResponse<[StoreCard]>) -> Void) {
        let urlString = self.url("api/v1/store/get")
        let headers = self.defaultHeader()
        let parameters = ["latitude": latitude, "longitude": longitude]
        
        Alamofire.request(urlString, method: .get, parameters: parameters, headers: headers)
            .responseJSON { (response) in
                print(response)
                let response: DataResponse<[StoreCard]> = response.flatMapResult { json in
                    
                    if let storeCards = Mapper<StoreCard>().mapArray(JSONObject: json) {
                        return .success(storeCards)
                    } else {
                        return .failure(MappingError.init(from: self, to: StoreCard.self))
                    }
                }
                completion(response)
        }
    }
    
    static func saveStore(store: Store, images:[UIImage],completion: @escaping (DataResponse<SaveResponse>) -> Void) {
        let urlString = self.url("api/v1/store/save")
        let headers = self.defaultHeader()
        var parameters = store.toJSON()
        
        parameters["userId"] = "\(UserDefaultsUtil.getUserId()!)"
        parameters["menu"] = nil
        parameters["images"] = nil
        parameters["review"] = nil
        
        // 배열로 보냈을 경우 서버에서 못받아서 일단 임시로 필드처럼 해서 보냄 ㅠㅠ
        for index in store.menus.indices {
            let menu = store.menus[index]
            
            parameters["menu[\(index)].name"] = menu.name
            parameters["menu[\(index)].price"] = menu.price
        }
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            for index in images.indices {
                let image = images[index]

                multipartFormData.append(image.jpegData(compressionQuality: 0.5)!, withName: "image", fileName: "image\(index).jpeg", mimeType: "image/jpeg")
            }
            for (key, value) in parameters {
                let stringValue = String(describing: value)
                
                multipartFormData.append(stringValue.data(using: .utf8)!, withName: key)
            }
        }, to: urlString, headers: headers) { (result) in
            switch result {
            case .success(let uploadRequest, _, _):
                uploadRequest.responseJSON { (response) in
                    let response: DataResponse<SaveResponse> = response.flatMapResult { (json) in
                        if let saveResponse = Mapper<SaveResponse>().map(JSONObject: json) {
                            return .success(saveResponse)
                        } else {
                            return .failure(MappingError.init(from: json, to: Store.self))
                        }
                    }
                    completion(response)
                }
            case .failure(let error):
                AlertUtils.show(title: "Save store error", message: error.localizedDescription)
            }
        }
    }
    
    static func getStoreDetail(storeId: Int, completion: @escaping (DataResponse<Store>) -> Void) {
        let urlString = self.url("api/v1/store/detail")
        let headers = self.defaultHeader()
        let parameters = ["storeId": storeId]
        
        Alamofire.request(urlString, method: .get, parameters: parameters, headers: headers).responseJSON { (response) in
            let response: DataResponse<Store> = response.flatMapResult { (json) in
                if let store = Mapper<Store>().map(JSONObject: json) {
                    return .success(store)
                } else {
                    return .failure(MappingError.init(from: json, to: Store.self))
                }
            }
            completion(response)
        }
    }
}
