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
    public let authenticationThreshold: Float
    /// Comparison threshold used at identification
    public let identificationThreshold: Float
    /// Comparison threshold used to decide whether a face template should be automatically enrolled in other registries
    public let autoEnrolmentThreshold: Float
    /// Initialiser
    /// - Parameters:
    ///   - authenticationThreshold: Comparison threshold used at authentication
    ///   - identificationThreshold: Comparison threshold used at identification
    ///   - autoEnrolmentThreshold: Comparison threshold used to decide whether a face template should be automatically enrolled in other registries
    public init(authenticationThreshold: Float, identificationThreshold: Float, autoEnrolmentThreshold: Float) {
        self.authenticationThreshold = authenticationThreshold
        self.identificationThreshold = identificationThreshold
        self.autoEnrolmentThreshold = autoEnrolmentThreshold
    }
    /// Initialiser with default values
    public init() {
        self.init(authenticationThreshold: 0.5, identificationThreshold: 0.5, autoEnrolmentThreshold: 0.6)
    }
}
