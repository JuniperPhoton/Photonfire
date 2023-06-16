//
//  File.swift
//  
//
//  Created by Photon Juniper on 2023/6/16.
//

import Foundation
import SwiftDiagnostics

enum PhotonfireMacrosError: Error, DiagnosticMessage {
    case argumentNotFound(_ arguments: [String])
    case notAProtocol
    
    var message: String {
        switch self {
        case .argumentNotFound(let arguments):
            return "Argument of \(arguments.joined(separator: ",")) not found"
        case .notAProtocol:
            return "The attached declaration is not a protocol"
        }
    }
    
    var diagnosticID: SwiftDiagnostics.MessageID {
        switch self {
        case .argumentNotFound(_):
            return .init(domain: "Photonfire", id: "argumentNotFound")
        case .notAProtocol:
            return .init(domain: "Photonfire", id: "notAProtocol")
        }
    }
    
    var severity: SwiftDiagnostics.DiagnosticSeverity {
        .error
    }
}
