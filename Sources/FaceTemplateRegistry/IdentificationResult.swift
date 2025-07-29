//
//  IdentificationResult.swift
//
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Identification result
public struct IdentificationResult<V: FaceTemplateVersion, D: FaceTemplateData> {
    
    /// Face template used for the identification
    public let taggedFaceTemplate: TaggedFaceTemplate<V, D>
    /// Score with which the face template matched the challenge face
    public let score: Float
    
    init(taggedFaceTemplate: TaggedFaceTemplate<V, D>, score: Float) {
        self.taggedFaceTemplate = taggedFaceTemplate
        self.score = score
    }
}
