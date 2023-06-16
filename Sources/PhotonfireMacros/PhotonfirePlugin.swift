import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

@main
struct PhotonfirePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PhotonfireServiceMacro.self,
        PhotonfireGetMacro.self,
    ]
}
