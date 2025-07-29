//
//  AnyIdentificationResult.swift
//
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Type-erased version of ``IdentificationResult``
public struct AnyIdentificationResult {
    
    /// Face template used for the identification
    public let taggedFaceTemplate: AnyTaggedFaceTemplate
    /// Score with which the face template matched the challenge face
    public let score: Float
    /// Face templates automatically enrolled during the identification
    public let autoEnrolledFaceTemplates: [any FaceTemplateProtocol]
    
    init(taggedFaceTemplate: AnyTaggedFaceTemplate, score: Float, autoEnrolledFaceTemplates: [any FaceTemplateProtocol]=[]) {
        self.taggedFaceTemplate = taggedFaceTemplate
        self.score = score
        self.autoEnrolledFaceTemplates = autoEnrolledFaceTemplates
    }
}
