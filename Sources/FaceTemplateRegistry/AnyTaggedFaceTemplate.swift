//
//  AnyTaggedFaceTemplate.swift
//  
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Type-erased version of ``TaggedFaceTemplate``
public struct AnyTaggedFaceTemplate {
    
    /// Identifier
    public let identifier: String
    /// Face template
    public let faceTemplate: any FaceTemplateProtocol
    
    init(faceTemplate: any FaceTemplateProtocol, identifier: String) {
        self.faceTemplate = faceTemplate
        self.identifier = identifier
    }
}

public extension TaggedFaceTemplate {
    
    /// Create a type-erased version of the tagged face template
    /// - Returns: Type-erased version of the face template
    func eraseToAnyTaggedFaceTemplate() -> AnyTaggedFaceTemplate {
        return AnyTaggedFaceTemplate(faceTemplate: self.faceTemplate, identifier: self.identifier)
    }
}
