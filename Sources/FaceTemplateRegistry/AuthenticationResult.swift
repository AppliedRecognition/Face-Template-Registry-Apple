//
//  AuthenticationResult.swift
//
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Authentication result
public struct AuthenticationResult<V: FaceTemplateVersion, D: FaceTemplateData> {
    
    /// `true` if face has been authenticated
    public let authenticated: Bool
    /// Face template extracted from the supplied face and image
    public let challengeFaceTemplate: FaceTemplate<V, D>
    /// Face template that was used for comparison
    public let matchedFaceTemplate: FaceTemplate<V, D>
    /// Comparison score between challenge and matched face templates
    public let score: Float
}
