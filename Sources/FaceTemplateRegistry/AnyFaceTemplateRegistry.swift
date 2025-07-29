//
//  File.swift
//  
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Type-erased version of ``FaceTemplateRegistry``
public class AnyFaceTemplateRegistry {
    
    private let _faceTemplates: () async -> [AnyTaggedFaceTemplate]
    private let _identifiers: () async -> Set<String>
    private let _registerFace: (Face, Image, String, Bool) async throws -> any FaceTemplateProtocol
    private let _identifyFace: (Face, Image) async throws -> [AnyIdentificationResult]
    private let _authenticateFace: (Face, Image, String) async throws -> AnyAuthenticationResult
    private let _faceTemplatesByIdentifier: (String) async -> [any FaceTemplateProtocol]
    private let _deleteFaceTemplatesByIdentifier: (String) async -> [any FaceTemplateProtocol]
    private let _deleteTemplates: ([AnyTaggedFaceTemplate]) async -> Void
    
    /// Face template version handled by this registry
    public let faceTemplateVersion: Int
    
    init<V: FaceTemplateVersion, D: FaceTemplateData, R: FaceRecognition>(
        _ registry: FaceTemplateRegistry<V, D, R>
    ) where R.Version == V, R.TemplateData == D {
        self.faceTemplateVersion = registry.faceRecognition.version
        self._faceTemplates = {
            await registry.faceTemplates.map {
                AnyTaggedFaceTemplate(
                    faceTemplate: $0.faceTemplate,
                    identifier: $0.identifier
                )
            }
        }
        
        self._identifiers = {
            await registry.identifiers
        }
        
        self._registerFace = { face, image, identifier, forceEnrolment in
            try await registry.registerFace(face, image: image, identifier: identifier, forceEnrolment: forceEnrolment)
        }
        
        self._identifyFace = { face, image in
            let result = try await registry.identifyFace(face, image: image)
            return result.map {
                AnyIdentificationResult(taggedFaceTemplate: $0.taggedFaceTemplate.eraseToAnyTaggedFaceTemplate(), score: $0.score)
            }
        }
        
        self._authenticateFace = { face, image, identifier in
            let result = try await registry.authenticateFace(face, image: image, identifier: identifier)
            return AnyAuthenticationResult(
                authenticated: result.authenticated,
                challengeFaceTemplate: result.challengeFaceTemplate,
                matchedFaceTemplate: result.matchedFaceTemplate,
                score: result.score
            )
        }
        
        self._faceTemplatesByIdentifier = { identifier in
            await registry.faceTemplatesByIdentifier(identifier)
        }
        
        self._deleteFaceTemplatesByIdentifier = { identifier in
            await registry.deleteFaceTemplatesByIdentifier(identifier)
        }
        
        self._deleteTemplates = { templates in
            let casted: [TaggedFaceTemplate<V, D>] = templates.compactMap {
                if $0.faceTemplate.version != registry.faceRecognition.version {
                    return nil
                }
                return TaggedFaceTemplate<V, D>(
                    faceTemplate: $0.faceTemplate as! FaceTemplate<V, D>,
                    identifier: $0.identifier
                )
            }
            await registry.deleteFaceTemplates(casted)
        }
    }
    
    var faceTemplates: [AnyTaggedFaceTemplate] {
        get async {
            await _faceTemplates()
        }
    }
    
    var identifiers: Set<String> {
        get async {
            await _identifiers()
        }
    }
    func registerFace(_ face: Face, image: Image, identifier: String, forceEnrolment: Bool = false) async throws -> any FaceTemplateProtocol {
        try await _registerFace(face, image, identifier, forceEnrolment)
    }
    
    func identifyFace(_ face: Face, image: Image) async throws -> [AnyIdentificationResult] {
        try await _identifyFace(face, image)
    }
    
    func authenticateFace(_ face: Face, image: Image, identifier: String) async throws -> AnyAuthenticationResult {
        try await _authenticateFace(face, image, identifier)
    }
    
    func faceTemplatesByIdentifier(_ identifier: String) async -> [any FaceTemplateProtocol] {
        await _faceTemplatesByIdentifier(identifier)
    }
    
    func deleteFaceTemplatesByIdentifier(_ identifier: String) async -> [any FaceTemplateProtocol] {
        await _deleteFaceTemplatesByIdentifier(identifier)
    }
    
    func deleteTemplates(_ templates: [AnyTaggedFaceTemplate]) async {
        await _deleteTemplates(templates)
    }
}
