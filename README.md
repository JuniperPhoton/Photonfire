# Photonfire

A library utilize Swift Macros to generate code for network requests, inspired by [Retrofit](https://square.github.io/retrofit/).
All you need to do is writing a `protocol` that conforms to the `PhotonfireServiceProtocol` and add macros to describe how to access your network resources.

It uses `URLSession` to perform HTTP requests, with no other frameworks included.

> Note: this library is in early stage, and it supports generating GET methods for now. Since Swift Macros is availabe in Swift 5.9, to test this library, you should use Xcode 15 beta.

## Usage

First define a protocol that conforms to `PhotonfireServiceProtocol` and:
- Add `@PhotonfireService` attached macro to the protocol
- Define a function to retrieve your resources. In this case, I define a function to get keys, given an id as query item and a path appended to the baseURL.

```swift
@PhotonfireService
protocol OpenAIKeyService: PhotonfireServiceProtocol {
    @PhotonfireGet(path: "/APIKeys")
    func getKeys(id: String) async throws -> [OpenAIKey]
}
```

Then this macro library will expands the implementation for you:

```swift
class PhotonfireOpenAIKeyService: OpenAIKeyService {
    static func createInstance(client: PhotonfireClient) -> PhotonfireOpenAIKeyService {
        return PhotonfireOpenAIKeyService(client: client)
    }
    private let client: PhotonfireClient
    private init(client: PhotonfireClient) {
        self.client = client
    }
    func getKeys(id: String) async throws -> [OpenAIKey] {
        // impl...
    }
    private func setHeaders(request: inout URLRequest, httpMethod: String, headers: [String: String]) {
        // impl...
    }
}
```

To make a request, you setup a `PhotonfireClient` and use it to create a `PhotonfireOpenAIKeyService`, suffixing `Photonfire` with your service name, then you can call the functions you define.

```swift
let apiKey = "..."
let url: URL = ...
let client = PhotonfireClient.Builder(baseURL: url)
    .defaultHeaders(headers: [
        "apikey": apiKey,
        "Authorization" : "Bearer \(apiKey)",
        "Content-Type" : "application/json",
    ])
    .build()

let service = client.createService(of: PhotonfireOpenAIKeyService.self)

let keys = try? await service.getKeys(id: "1")
```

# Coming features

- [ ] Supports parameter pattern like '/account/{id}/' to help you custom the URL path in runtime
- [ ] Supports generating POST/DELETE methods

# MIT License

Copyright (c) [2023] [JuniperPhoton]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
