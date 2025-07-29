//
//  AnyAuthenticationResult.swift
//  
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Type-erased version of ``AuthenticationResult`` to use with ``FaceTemplateMultiRegistry``
public struct AnyAuthenticationResult {
    
    /// `true` if face has been authenticated
    public let authenticated: Bool
    /// Face template extracted from the supplied face and image
    public let challengeFaceTemplate: any FaceTemplateProtocol
    /// Face template that was used for comparison
    public let matchedFaceTemplate: any FaceTemplateProtocol
    /// Comparison score between challenge and matched face templates
    public let score: Float
    /// Face templates automatically enrolled during the authentication
    public let autoEnrolledFaceTemplates: [any FaceTemplateProtocol]
    
    init(authenticated: Bool, challengeFaceTemplate: any FaceTemplateProtocol, matchedFaceTemplate: any FaceTemplateProtocol, score: Float, autoEnrolledFaceTemplates: [any FaceTemplateProtocol]=[]) {
        self.authenticated = authenticated
        self.challengeFaceTemplate = challengeFaceTemplate
        self.matchedFaceTemplate = matchedFaceTemplate
        self.score = score
        self.autoEnrolledFaceTemplates = autoEnrolledFaceTemplates
    }
}
