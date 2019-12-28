import UIKit
import GoogleMaps

class DetailVC: BaseVC {
    
    private lazy var detailView = DetailView(frame: self.view.frame)
    
    
    static func instance() -> DetailVC {
        return DetailVC(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view = detailView
        
        let camera = GMSCameraPosition.camera(withLatitude: 37.49838214755165, longitude: 127.02844798564912, zoom: 15)
        
        detailView.mapView.camera = camera
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: 37.49838214755165, longitude: 127.02844798564912)
        marker.title = "닥고약기"
        marker.snippet = "무름표"
        marker.map = detailView.mapView
        
        detailView.tableView.delegate = self
        detailView.tableView.dataSource = self
        detailView.tableView.register(ReviewCell.self, forCellReuseIdentifier: ReviewCell.registerId)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("tableview height: \(detailView.tableView.frame.height)")
        print("contentSize height: \(detailView.tableView.contentSize.height)")
        detailView.tableView.frame = CGRect(x: 0, y: 0, width: detailView.tableView.frame.width, height: detailView.tableView.contentSize.height)
        print("tableview height: \(detailView.tableView.frame.height)")
    }
}

extension DetailVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ReviewCell.registerId, for: indexPath) as? ReviewCell else {
            return BaseTableViewCell()
        }
        
        return cell
    }
}
