//
//  FaceTemplateRegistryConfiguration.swift
//  
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation

/// Face template registry configuration
public struct FaceTemplateRegistryConfiguration {
    /// Comparison threshold used at authentication
    public var authenticationThreshold: Float
    /// Comparison threshold used at identification
    public var identificationThreshold: Float
    /// Comparison threshold used to decide whether a face template should be automatically enrolled in other registries
    public var autoEnrolmentThreshold: Float
    /// Initialiser
    /// - Parameters:
    ///   - authenticationThreshold: Comparison threshold used at authentication
    ///   - identificationThreshold: Comparison threshold used at identification
    ///   - autoEnrolmentThreshold: Comparison threshold used to decide whether a face template should be automatically enrolled in other registries
    public init(authenticationThreshold: Float = 0.5, identificationThreshold: Float = 0.5, autoEnrolmentThreshold: Float = 0.6) {
        self.authenticationThreshold = authenticationThreshold
        self.identificationThreshold = identificationThreshold
        self.autoEnrolmentThreshold = autoEnrolmentThreshold
    }
}
