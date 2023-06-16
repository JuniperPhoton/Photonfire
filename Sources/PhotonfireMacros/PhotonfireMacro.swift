import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct PhotonfireServiceMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        // This macro must be attached to a protocol declaration
        guard let protocolSyntax = declaration.as(ProtocolDeclSyntax.self) else {
            context.addDiagnostics(from: PhotonfireMacrosError.notAProtocol, node: node)
            return []
        }
        
        // The protocol name
        let name = protocolSyntax.identifier.text
        
        // Generates get/post/delete functions based on the attritube of the function
        let functions = protocolSyntax.memberBlock.members.map { member in
            // Currently we supports generating GET functions
            generateGetFunctionDecl(syntax: member, context: context)
        }
        
        let classDecl = try ClassDeclSyntax("class \(raw: "Photonfire\(name)"): \(raw: name)") {
            try FunctionDeclSyntax("static func createInstance(client: PhotonfireClient) -> \(raw: "Photonfire\(name)")") {
                CodeBlockItemSyntax(item: .decl("return \(raw: "Photonfire\(name)")(client: client)"))
            }
            
            DeclSyntax("private let client: PhotonfireClient")
            
            // TODO No idea why this initializer is not followed by a line break, so add it here
            try InitializerDeclSyntax("\nprivate init(client: PhotonfireClient)") {
                CodeBlockItemListSyntax([
                    .init(item: .decl("self.client = client"))
                ])
            }
            
            for function in functions  {
                MemberDeclListItemSyntax(decl: function)
            }
            
            generateSetHeaderDecl()
        }
        
        return [DeclSyntax(classDecl)]
    }
    
    private static func generateSetHeaderDecl() -> DeclSyntax{
        return """
        private func setHeaders(request: inout URLRequest, httpMethod: String, headers: [String: String]) {
            headers.forEach { (k, v) in
                request.setValue(v, forHTTPHeaderField: k)
            }
            request.httpMethod = httpMethod
        }
        """
    }
    
    /// Generate all functions that has ``@PhotonfireGet`` attributed attached.
    private static func generateGetFunctionDecl(syntax: MemberDeclListSyntax.Element,
                                                context: some MacroExpansionContext) -> DeclSyntax {
        return generateFunctionDecl(syntax: syntax, context: context, attributeName: "PhotonfireGet") { funcDecl, getAttr in
            guard let appendPathExpr = getAttr.argument?.as(TupleExprElementListSyntax.self)?.first?.expression else {
                context.addDiagnostics(from: PhotonfireMacrosError.argumentNotFound(["appendPathExpr"]), node: getAttr)
                return ""
            }
            
            let returnType = funcDecl.signature.output?.returnType.description ?? ""
            
            var queryItems: [String] = []
            let parameters = funcDecl.signature.input.parameterList.map { $0.as(FunctionParameterSyntax.self) }
            
            parameters.forEach { s in
                if let s = s {
                    queryItems.append(".init(name: \"\(s.firstName.text)\", value: \(s.firstName.text))")
                }
            }
            
            return """
            func \(funcDecl.identifier)\(raw: funcDecl.signature.description) {
                let appendPath = \(appendPathExpr)
            
                guard var urlComponents = URLComponents(string: client.baseURL.absoluteString) else {
                    throw PhotonfireError.parameterError("failed to create URLComponents")
                }
                
                urlComponents.path += appendPath
                urlComponents.queryItems = [
                    \(raw: queryItems.joined(separator: ",\n"))
                ]
                
                guard let finalURL = urlComponents.url else {
                    throw PhotonfireError.parameterError("failed to create url")
                }
                
                let type = \(raw: returnType).self
                
                let session = client.session
                var request = URLRequest(url: finalURL)
                setHeaders(request: &request, httpMethod: "GET", headers: client.defaultHeaders)
            
                let (data, _) = try await session.data(for: request)
                return try client.jsonDecoder.decode(type, from: data)
            }
            """
        }
    }
    
    /// Given a ``MemberDeclListSyntax.Element``, try cast it as ``FunctionDeclSyntax`` and find the ``AttributeSyntax``
    /// that matched the ``attributeName``, and invoke ``block`` to produce ``DeclSyntax``.
    private static func generateFunctionDecl(syntax: MemberDeclListSyntax.Element,
                                             context: some MacroExpansionContext,
                                             attributeName: String,
                                             block: (FunctionDeclSyntax, AttributeSyntax) -> DeclSyntax) -> DeclSyntax {
        if let itemSyntax = syntax.as(MemberDeclListItemSyntax.self),
           let funcDecl = itemSyntax.decl.as(FunctionDeclSyntax.self) {
            let matchedAttributeSyntax = funcDecl.attributes?.first { e in
                e.as(AttributeSyntax.self)?.attributeName.as(SimpleTypeIdentifierSyntax.self)?.name.text == attributeName
            }?.as(AttributeSyntax.self)
            
            guard let matchedAttributeSyntax else {
                context.addDiagnostics(from: PhotonfireMacrosError.argumentNotFound(["getFuncDecl", "matchedAttributeSyntax"]),
                                       node: funcDecl._syntaxNode)
                return ""
            }
            
            return block(funcDecl, matchedAttributeSyntax)
        } else {
            return ""
        }
    }
}

public struct PhotonfireGetMacro: MemberMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        return []
    }
}

extension FreestandingMacroExpansionSyntax {
    func getArgumentSyntax(label: String) -> TupleExprElementListSyntax.Element? {
        return argumentList.first { e in
            return e.label?.text == label
        }
    }
}
