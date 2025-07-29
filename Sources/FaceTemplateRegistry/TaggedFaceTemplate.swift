//
//  TaggedFaceTemplate.swift
//
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Tagged face template
public struct TaggedFaceTemplate<V: FaceTemplateVersion, D: FaceTemplateData>: Hashable {
    /// Face template
    public let faceTemplate: FaceTemplate<V, D>
    /// Identifier with which the template is tagged
    public let identifier: String
    
    /// Initialiser
    /// - Parameters:
    ///   - faceTemplate: Face template
    ///   - identifier: Identifier with which the template is tagged
    public init(faceTemplate: FaceTemplate<V, D>, identifier: String) {
        self.faceTemplate = faceTemplate
        self.identifier = identifier
    }
}
