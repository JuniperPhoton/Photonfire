import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import PhotonfireMacros

let testMacros: [String: Macro.Type] = [
    "PhotonfireService": PhotonfireServiceMacro.self,
    "PhotonfireGet": PhotonfireGetMacro.self,
]

final class PhotonfireTests: XCTestCase {
    func testService() {
        assertMacroExpansion(
            """
            @PhotonfireService
            protocol AccountService: PhotonfireServiceProtocol {
                @PhotonfireGet(path: "/account")
                func getAccount(id: String, name: String) async throws -> Account
            
                @PhotonfireGet(path: "/account")
                func getAccount(@PhotonfireQuery(name: "is_activated") activated: Bool) async throws -> Account
            }
            """,
            expandedSource: """
            
            protocol AccountService: PhotonfireServiceProtocol {
                func getAccount(id: String, name: String) async throws -> Account
                func getAccount(@PhotonfireQuery(name: "is_activated") activated: Bool) async throws -> Account
            }
            class PhotonfireAccountService: AccountService {
                static func createInstance(client: PhotonfireClient) -> PhotonfireAccountService {
                    return PhotonfireAccountService(client: client)
                }
                private let client: PhotonfireClient
                private init(client: PhotonfireClient) {
                    self.client = client
                }
                func getAccount(id: String, name: String) async throws -> Account {
                    let appendPath = "/account"

                    guard var urlComponents = URLComponents(string: client.baseURL.absoluteString) else {
                        throw PhotonfireError.parameterError("failed to create URLComponents")
                    }

                    urlComponents.path += appendPath
                    urlComponents.queryItems = [
                        .init(name: "id", value: id),
                        .init(name: "name", value: name)
                    ]

                    guard let finalURL = urlComponents.url else {
                        throw PhotonfireError.parameterError("failed to create url")
                    }

                    let type = Account.self

                    let session = client.session
                    var request = URLRequest(url: finalURL)
                    setHeaders(request: &request, httpMethod: "GET", headers: client.defaultHeaders)

                    let (data, _) = try await session.data(for: request)
                    return try client.jsonDecoder.decode(type, from: data)
                }
                func getAccount(@PhotonfireQuery(name: "is_activated") activated: Bool) async throws -> Account {
                    let appendPath = "/account"

                    guard var urlComponents = URLComponents(string: client.baseURL.absoluteString) else {
                        throw PhotonfireError.parameterError("failed to create URLComponents")
                    }

                    urlComponents.path += appendPath
                    urlComponents.queryItems = [
                        .init(name: "is_activated", value: activated)
                    ]

                    guard let finalURL = urlComponents.url else {
                        throw PhotonfireError.parameterError("failed to create url")
                    }

                    let type = Account.self

                    let session = client.session
                    var request = URLRequest(url: finalURL)
                    setHeaders(request: &request, httpMethod: "GET", headers: client.defaultHeaders)

                    let (data, _) = try await session.data(for: request)
                    return try client.jsonDecoder.decode(type, from: data)
                }
                private func setHeaders(request: inout URLRequest, httpMethod: String, headers: [String: String]) {
                    headers.forEach { (k, v) in
                        request.setValue(v, forHTTPHeaderField: k)
                    }
                    request.httpMethod = httpMethod
                }
            }
            """,
            macros: testMacros
        )
    }
}
