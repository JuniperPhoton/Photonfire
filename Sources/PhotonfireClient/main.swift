import Photonfire
import Foundation

struct Account: Codable {
    let name: String
    let id: String
    
    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

@PhotonfireService
protocol AccountService: PhotonfireServiceProtocol {
    @PhotonfireGet(path: "/account")
    func getAccount(id: String, name: String) async throws -> Account
    
    @PhotonfireGet(path: "/account")
    func getAccount(@PhotonfireQuery(name: "is_activated") activated: Bool) async throws -> Account
}

let client = PhotonfireClient.Builder(baseURL: URL(string: "http")!).build()
let service = client.createService(of: PhotonfireAccountService.self)
