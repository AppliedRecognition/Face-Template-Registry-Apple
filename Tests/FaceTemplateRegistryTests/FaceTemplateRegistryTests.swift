import XCTest
import VerIDCommonTypes
@testable import FaceTemplateRegistry

final class FaceTemplateRegistryTests: XCTestCase {
    
    // MARK: - Registration
    
    func test_registerFaceTemplate() async throws {
        let rec = MockFaceRecognition<V1>()
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: [])
        let face = Mocks.face(0)
        let template = try await registry.registerFace(face, image: Mocks.image, identifier: "Test")
        XCTAssertEqual(template.data, 0)
        XCTAssertEqual(template.version, V1.id)
        let templates = await registry.faceTemplates
        XCTAssertEqual(templates.count, 1)
    }
    
    func test_registerSimilarFaceAsDifferentIdentifier_fail() async throws {
        let rec = MockFaceRecognition<V1>()
        let templates = stride(from: 0, to: 100, by: 10).map { i in
            return TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V1, Float>(data: Float(i)),
                identifier: "User \(i)"
            )
        }
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: templates)
        let face = Mocks.face(50.1)
        do {
            _ = try await registry.registerFace(face, image: Mocks.image, identifier: "New user")
            XCTFail()
        } catch FaceTemplateRegistryError.similarFaceAlreadyRegisteredAs(let user) {
            XCTAssertEqual(user, "User 50")
        } catch {
            XCTFail()
        }
    }
    
    func test_forceRegisterSimilarFacesAsDifferentIdentifier() async throws {
        let rec = MockFaceRecognition<V1>()
        let templates = stride(from: 0, to: 100, by: 10).map { i in
            return TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V1, Float>(data: Float(i)),
                identifier: "User \(i)"
            )
        }
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: templates)
        let face = Mocks.face(50.1)
        let registeredTemplate = try await registry.registerFace(face, image: Mocks.image, identifier: "New user", forceEnrolment: true)
        XCTAssertEqual(registeredTemplate.data, 50.1)
        XCTAssertEqual(registeredTemplate.version, V1.id)
        let newIds = await registry.identifiers
        XCTAssertTrue(newIds.contains("New user"))
    }
    
    // MARK: - Identification
    
    func test_identifyFaceInEmptySet_returnsEmptyResult() async throws {
        let rec = MockFaceRecognition<V1>()
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: [])
        let face = Mocks.face(50.1)
        let idResults = try await registry.identifyFace(face, image: Mocks.image)
        XCTAssertTrue(idResults.isEmpty)
    }
    
    func test_identifyFace() async throws {
        let rec = MockFaceRecognition<V1>()
        let templates = stride(from: 0, to: 100, by: 10).map { i in
            return [
                TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V1, Float>(data: Float(i)),
                    identifier: "User \(i)"
                ),
                TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V1, Float>(data: Float(i)-0.1),
                    identifier: "User \(i)"
                )
            ]
        }.flatMap { $0 }
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: templates)
        let face = Mocks.face(50.1)
        let idResults = try await registry.identifyFace(face, image: Mocks.image)
        XCTAssertEqual(1, idResults.count)
        XCTAssertEqual("User 50", idResults[0].taggedFaceTemplate.identifier)
    }
    
    // MARK: - Authentication
    
    func test_authenticateFace() async throws {
        let rec = MockFaceRecognition<V1>()
        let templates = stride(from: 0, to: 100, by: 10).map { i in
            return [
                TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V1, Float>(data: Float(i)),
                    identifier: "User \(i)"
                ),
                TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V1, Float>(data: Float(i)-0.1),
                    identifier: "User \(i)"
                )
            ]
        }.flatMap { $0 }
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: templates)
        let face = Mocks.face(50.1)
        let authResult = try await registry.authenticateFace(face, image: Mocks.image, identifier: "User 50")
        XCTAssertTrue(authResult.authenticated)
    }
    
    func test_authenticateFaceInEmptyRegistry_fail() async throws {
        let rec = MockFaceRecognition<V1>()
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: [])
        let face = Mocks.face(50.1)
        do {
            _ = try await registry.authenticateFace(face, image: Mocks.image, identifier: "User 50")
            XCTFail()
        } catch FaceTemplateRegistryError.identifierNotRegistered(let user) {
            XCTAssertEqual(user, "User 50")
        } catch {
            XCTFail()
        }
    }
    
    func test_authenticateFaceOfUnregisteredUser() async throws {
        let rec = MockFaceRecognition<V1>()
        let templates = stride(from: 0, to: 100, by: 10).map { i in
            return [
                TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V1, Float>(data: Float(i)),
                    identifier: "User \(i)"
                ),
                TaggedFaceTemplate(
                    faceTemplate: FaceTemplate<V1, Float>(data: Float(i)-0.1),
                    identifier: "User \(i)"
                )
            ]
        }.flatMap { $0 }
        let registry = FaceTemplateRegistry(faceRecognition: rec, faceTemplates: templates)
        let face = Mocks.face(55.1)
        let authResult = try await registry.authenticateFace(face, image: Mocks.image, identifier: "User 50")
        XCTAssertFalse(authResult.authenticated)
    }
}
