import Foundation
import VerIDCommonTypes

/// Face template registry
///
/// Handles registration, authentication and identification on given face template sets
public class FaceTemplateRegistry<V: FaceTemplateVersion, D: FaceTemplateData, FaceRec: FaceRecognition> where FaceRec.Version == V, FaceRec.TemplateData == D {
    
    /// Face recognition instance to use for extracting face templates and face comparisons
    public let faceRecognition: FaceRec
    /// Get registered face template identifiers
    public var identifiers: Set<String> {
        get async {
            await self.faceTemplateStore.identifiers
        }
    }
    /// Get all registered face templates
    public var faceTemplates: [TaggedFaceTemplate<V, D>] {
        get async {
            await self.faceTemplateStore.all
        }
    }
    /// Registry configuration
    public let configuration: FaceTemplateRegistryConfiguration
    
    private let faceTemplateStore: FaceTemplateStore<V, D>
    
    /// Initialiser
    /// - Parameters:
    ///   - faceRecognition:Face recognition instance to use for extracting face templates and face comparisons
    ///   - faceTemplates: Initial set of face templates
    ///   - configuration: Registry configuration
    public init(faceRecognition: FaceRec, faceTemplates: Array<TaggedFaceTemplate<V, D>>, configuration: FaceTemplateRegistryConfiguration=FaceTemplateRegistryConfiguration()) {
        self.faceRecognition = faceRecognition
        self.faceTemplateStore = FaceTemplateStore(initialTemplates: faceTemplates)
        self.configuration = configuration
    }
    
    /// Register face
    /// - Parameters:
    ///   - face: Face to register
    ///   - image: Image in which the face was detected
    ///   - identifier: Identifier used to tag the face template
    /// - Returns: Registered face template
    public func registerFace(_ face: Face, image: Image, identifier: String) async throws -> FaceTemplate<V, D> {
        let template = try await self.faceRecognition.createFaceRecognitionTemplates(from: [face], in: image).first!
        let taggedTemplate = TaggedFaceTemplate(faceTemplate: template, identifier: identifier)
        let allTemplates = await self.faceTemplates
        if !allTemplates.isEmpty {
            let scores = try await self.faceRecognition.compareFaceRecognitionTemplates(allTemplates.map { $0.faceTemplate }, to: template)
            if let existingUser = zip(scores, allTemplates).first(where: { (score, template) in
                return score >= self.configuration.identificationThreshold && template.identifier != identifier
            }) {
                throw FaceTemplateRegistryError.similarFaceAlreadyRegisteredAs(existingUser.1.identifier, template, existingUser.0)
            }
        }
        await self.faceTemplateStore.append(taggedTemplate)
        return template
    }
    
    /// Identify face
    /// - Parameters:
    ///   - face: Face to identify
    ///   - image: Image in which the face was detected
    /// - Returns: Array of identification results
    public func identifyFace(_ face: Face, image: Image) async throws -> [IdentificationResult<V, D>] {
        let template: FaceTemplate<V, D> = try await self.faceRecognition.createFaceRecognitionTemplates(from: [face], in: image).first!
        let allTemplates = await self.faceTemplates
        if allTemplates.isEmpty {
            return []
        }
        let scores: [Float] = try await self.faceRecognition.compareFaceRecognitionTemplates(allTemplates.map({ $0.faceTemplate }), to: template)
        let matchingResults: [IdentificationResult<V, D>] = zip(scores, allTemplates).compactMap { (score: Float, template: TaggedFaceTemplate<V, D>) in
            if (score >= self.configuration.identificationThreshold) {
                return IdentificationResult(taggedFaceTemplate: template, score: score)
            } else {
                return nil
            }
        }
        let grouped = Dictionary(grouping: matchingResults) { $0.taggedFaceTemplate.identifier }
        let bestPerUser: [IdentificationResult<V, D>] = grouped.compactMap { (_, results) in
            return results.max { $0.score < $1.score }
        }
        return bestPerUser.sorted { $0.score > $1.score }
    }
    
    /// Authenticate face
    /// - Parameters:
    ///   - face: Face to authenticate
    ///   - image: Image in which the face was detected
    ///   - identifier: Identifier to authenticate the face against
    /// - Returns: Authentication result
    public func authenticateFace(_ face: Face, image: Image, identifier: String) async throws -> AuthenticationResult<V, D> {
        let userTemplates = await self.faceTemplatesByIdentifier(identifier)
        if userTemplates.isEmpty {
            throw FaceTemplateRegistryError.identifierNotRegistered(identifier)
        }
        let template = try await self.faceRecognition.createFaceRecognitionTemplates(from: [face], in: image).first!
        let scores = try await self.faceRecognition.compareFaceRecognitionTemplates(userTemplates, to: template)
        let maxIndex = scores.indices.max {
            return scores[$0] < scores[$1]
        }!
        let maxScore = scores[maxIndex]
        let matchedTemplate = userTemplates[maxIndex]
        return AuthenticationResult(
            authenticated: maxScore >= self.configuration.authenticationThreshold,
            challengeFaceTemplate: template,
            matchedFaceTemplate: matchedTemplate,
            score: maxScore
        )
    }
    
    /// Get all face templates tagged by the given identifier
    /// - Parameter identifier: Identifier
    /// - Returns: Array of face templates tagged as the identifier
    public func faceTemplatesByIdentifier(_ identifier: String) async -> [FaceTemplate<V, D>] {
        return await self.faceTemplateStore.getByIdentifier(identifier)
    }
    
    /// Create a type-erased version of this registry
    /// - Returns: Type-erased version of this registry
    public func eraseToAnyFaceTemplateRegistry() -> AnyFaceTemplateRegistry {
        return AnyFaceTemplateRegistry(self)
    }
}
