//
//  FaceTemplateMultiRegistry.swift
//
//
//  Created by Jakub Dolejs on 28/07/2025.
//

import Foundation
import VerIDCommonTypes

/// Face template registry handling multiple sub-registries
public class FaceTemplateMultiRegistry {
    
    /// Registries handled by this multi registry
    public let registries: [AnyFaceTemplateRegistry]
    /// Delegate that observes face template additions
    public var delegate: FaceTemplateMultiRegistryDelegate?
    
    /// Initialiser
    /// - Parameters:
    ///   - ensureFaceTemplateCompatibility: Set to `false` to accept registries with faces that cannot be effectively compared. For example, if one
    ///   registry has users [user1, user2] and one of the other registries has users [user1, user3] then there is no way to compare all users together because
    ///   comparisons crossing registry boundaries are not possible.
    ///   - registries: Registry to handle
    ///   - otherRegistries: Other registries to handle
    public init(ensureFaceTemplateCompatibility: Bool, registries: AnyFaceTemplateRegistry, _ otherRegistries: AnyFaceTemplateRegistry...) async throws {
        self.registries = [registries] + otherRegistries
        if ensureFaceTemplateCompatibility {
            try await self.checkForIncompatibleFaces()
        }
    }
    
    /// Initialiser
    ///
    /// Same as calling ``FaceTemplateMultiRegistry/init(ensureFaceTemplateCompatibility:registries:_:)`` with `ensureFaceTemplateCompatibility` set to `true`
    /// - Parameters:
    ///   - registries: Registry to handle
    ///   - otherRegistries: Other registries to handle
    public init(registries: AnyFaceTemplateRegistry, _ otherRegistries: AnyFaceTemplateRegistry...) async throws {
        self.registries = [registries] + otherRegistries
        try await self.checkForIncompatibleFaces()
    }
    
    /// Registered identifiers
    public var identifiers: Set<String> {
        get async {
            return await withTaskGroup(of: Set<String>.self) { group in
                for registry in registries {
                    group.addTask {
                        await registry.identifiers
                    }
                }
                var merged: Set<String> = []
                for await result in group {
                    merged.formUnion(result)
                }
                return merged
            }
        }
    }
    
    /// Registered tagged face templates
    public var faceTemplates: [AnyTaggedFaceTemplate] {
        get async {
            return await withTaskGroup(of: [AnyTaggedFaceTemplate].self) { group in
                for registry in registries {
                    group.addTask {
                        await registry.faceTemplates
                    }
                }
                var combined: [AnyTaggedFaceTemplate] = []
                for await templates in group {
                    combined.append(contentsOf: templates)
                }
                return combined
            }
        }
    }
    
    /// Register face
    /// - Parameters:
    ///   - face: Face to register
    ///   - image: Image in which the face was detected
    ///   - identifier: Identifier to tag the registered face with
    ///   - forceEnrolment: Set to `true` to  force enrolment even if another identifier with a similar face is already registered
    /// - Returns: Registered face templates
    public func registerFace(_ face: Face, image: Image, identifier: String, forceEnrolment: Bool=false) async throws -> [any FaceTemplateProtocol] {
        let registeredTemplates = try await withThrowingTaskGroup(of: (any FaceTemplateProtocol).self) { group in
            for registry in registries {
                group.addTask {
                    try await registry.registerFace(face, image: image, identifier: identifier, forceEnrolment: forceEnrolment)
                }
            }
            var combined: [any FaceTemplateProtocol] = []
            for try await template in group {
                combined.append(template)
            }
            return combined
        }
        if let delegate = self.delegate {
            Task.detached {
                delegate.onFaceTemplatesAdded(registeredTemplates.map {
                    AnyTaggedFaceTemplate(
                        faceTemplate: $0,
                        identifier: identifier
                    )
                })
            }
        }
        return registeredTemplates
    }
    
    /// Identify face
    /// - Parameters:
    ///   - face: Face to identify
    ///   - image: Image in which the face was detected
    ///   - autoEnrol: Auto enrol the face in registries where the user does not yet exist. This facilitates migrating from one face template registry to another.
    ///   - safe: If set to `false` the function will iterate over registries and return the first result with matching face templates. This risks missing evaluation of
    ///   face templates that may yield a higher score. Setting the parameter to `false` may help if there is no common face template version or if it's desired to
    ///   use a newer face recognition algorithm before all faces are migrated to it.
    /// - Returns: Array of identification results
    public func identifyFace(_ face: Face, image: Image, autoEnrol: Bool=true, safe: Bool=true) async throws -> [AnyIdentificationResult] {
        func autoEnrolFaceTemplatesFromResults(_ results: [AnyIdentificationResult]) async throws -> AnyIdentificationResult? {
            if let result = results.first, autoEnrol {
                let newFaceTemplates = try await self.autoEnrolFace(face, image: image, identifier: result.taggedFaceTemplate.identifier)
                return AnyIdentificationResult(taggedFaceTemplate: result.taggedFaceTemplate, score: result.score, autoEnrolledFaceTemplates: newFaceTemplates)
            } else {
                return nil
            }
        }
        if safe {
            let keyValuePairs: [(Int, Set<String>)] = try await withThrowingTaskGroup(of: (Int, Set<String>).self) { group in
                for registry in registries {
                    group.addTask {
                        let version = registry.faceTemplateVersion
                        let identifiers = await registry.identifiers
                        return (version, identifiers)
                    }
                }
                var results: [(Int, Set<String>)] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
            let users = Dictionary(uniqueKeysWithValues: keyValuePairs)
            let allUsers = Set(users.flatMap { key, val in return val })
            for registry in registries {
                let versionUsers = users[registry.faceTemplateVersion]!
                if allUsers.isSubset(of: versionUsers) {
                    var results = try await registry.identifyFace(face, image: image)
                    if let result = try await autoEnrolFaceTemplatesFromResults(results) {
                        results[0] = result
                    }
                    return results
                }
            }
            throw FaceTemplateRegistryError.incompatibleFaceTemplates
        } else {
            for registry in registries {
                var results = try await registry.identifyFace(face, image: image)
                if !results.isEmpty {
                    if let result = try await autoEnrolFaceTemplatesFromResults(results) {
                        results[0] = result
                    }
                    return results
                }
            }
            return []
        }
    }
    
    /// Authenticate face
    ///
    /// - Parameters:
    ///   - face: Face to authenticate
    ///   - image: Image in which the face was detected
    ///   - identifier: Identifier to authenticate against
    ///   - autoEnrol: Keep as the default `true` to auto enrol the face in registries where the user does not yet exist.
    /// - Returns: Authentication result
    public func authenticateFace(_ face: Face, image: Image, identifier: String, autoEnrol: Bool=true) async throws -> AnyAuthenticationResult {
        var finalResult: Result<AnyAuthenticationResult,Error> = .failure(NSError())
        for registry in registries {
            do {
                let result = try await registry.authenticateFace(face, image: image, identifier: identifier)
                if case .success(let interim) = finalResult, result.score > interim.score {
                    finalResult = .success(result)
                } else if case .failure = finalResult {
                    finalResult = .success(result)
                }
                if result.authenticated {
                    break
                }
            } catch {
                finalResult = .failure(error)
            }
        }
        switch finalResult {
        case .success(let result):
            if autoEnrol {
                let newFaceTemplates = try await self.autoEnrolFace(face, image: image, identifier: identifier)
                return AnyAuthenticationResult(authenticated: result.authenticated, challengeFaceTemplate: result.challengeFaceTemplate, matchedFaceTemplate: result.matchedFaceTemplate, score: result.score, autoEnrolledFaceTemplates: newFaceTemplates)
            }
            return result
        case .failure(let error):
            throw error
        }
    }
    
    /// Get face templates tagged with the given identifier
    /// - Parameter identifier: Identifier
    /// - Returns: Face templates tagged with the given identifier
    public func faceTemplatesByIdentifier(_ identifier: String) async -> [any FaceTemplateProtocol] {
        return await withTaskGroup(of: [any FaceTemplateProtocol].self) { group in
            for registry in registries {
                group.addTask {
                    await registry.faceTemplatesByIdentifier(identifier)
                }
            }
            var merged: [any FaceTemplateProtocol] = []
            for await templates in group {
                merged.append(contentsOf: templates)
            }
            return merged
        }
    }
    
    /// Delete face templates
    /// - Parameter faceTemplates: Face templates to delete
    public func deleteFaceTemplates(_ faceTemplates: [AnyTaggedFaceTemplate]) async {
        for registry in registries {
            await registry.deleteTemplates(faceTemplates)
        }
    }
    
    /// Delete face templates tagged by the given identifier
    /// - Parameter identifier: Identifier
    /// - Returns: Array of deleted face templates
    public func deleteFaceTemplatesByIdentifier(_ identifier: String) async -> [any FaceTemplateProtocol] {
        var allDeleted: [any FaceTemplateProtocol] = []
        for registry in registries {
            let deleted = await registry.deleteFaceTemplatesByIdentifier(identifier)
            allDeleted.append(contentsOf: deleted)
        }
        return allDeleted
    }
    
    private func autoEnrolFace(_ face: Face, image: Image, identifier: String) async throws -> [any FaceTemplateProtocol] {
        let addedTemplates = try await withThrowingTaskGroup(of: (any FaceTemplateProtocol)?.self) { group in
            for registry in registries {
                group.addTask {
                    let ids = await registry.identifiers
                    if !ids.contains(identifier) {
                        return try await registry.registerFace(face, image: image, identifier: identifier)
                    } else {
                        return nil
                    }
                }
            }
            var merged: [any FaceTemplateProtocol] = []
            for try await template in group {
                if let temp = template {
                    merged.append(temp)
                }
            }
            return merged
        }
        if !addedTemplates.isEmpty, let delegate = self.delegate {
            Task.detached {
                delegate.onFaceTemplatesAdded(addedTemplates.map {
                    AnyTaggedFaceTemplate(faceTemplate: $0, identifier: identifier)
                })
            }
        }
        return addedTemplates
    }
    
    private func checkForIncompatibleFaces() async throws {
        let identifierSets = await withTaskGroup(of: Set<String>.self) { group in
            for registry in registries {
                group.addTask {
                    await registry.identifiers
                }
            }
            var merged: Array<Set<String>> = []
            for await result in group {
                merged.append(result)
            }
            return merged
        }
        let allIdentifiers = identifierSets.reduce(into: Set<String>()) { $0.formUnion($1) }
        let hasCommonTemplate = identifierSets.contains { ids in
            allIdentifiers.isSubset(of: ids)
        }
        if !hasCommonTemplate {
            throw FaceTemplateRegistryError.incompatibleFaceTemplates
        }
    }
}

/// Face template multi-registry delegate protocol
public protocol FaceTemplateMultiRegistryDelegate: AnyObject {
    /// Called when face templates have been added either by face registration or auto-enrolment
    /// - Parameter faceTemplates: Added face templates
    func onFaceTemplatesAdded(_ faceTemplates: [AnyTaggedFaceTemplate])
}
