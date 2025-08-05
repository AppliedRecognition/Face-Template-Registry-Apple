//
//  Errors.swift
//
//
//  Created by Jakub Dolejs on 29/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Face template registry errors
public enum FaceTemplateRegistryError: LocalizedError {
    /// Thrown when attempting to register a face that's similar to a face already registered under a different identifier
    case similarFaceAlreadyRegisteredAs(String, any FaceTemplateProtocol, Float)
    /// Thrown when attempting to authenticate against an identifier that's not registered
    case identifierNotRegistered(String)
    /// Thrown when multi-registry contains identifiers that cannot be compared with the same face recognition system
    case incompatibleFaceTemplates
    
    public var errorDescription: String? {
        switch self {
        case .similarFaceAlreadyRegisteredAs(let identifier, _, _):
            return "Similar face already registered as \(identifier)"
        case .identifierNotRegistered(let identifier):
            return "Identifier \(identifier) is not registered"
        case .incompatibleFaceTemplates:
            return "Face templates are incompatible"
        }
    }
}
