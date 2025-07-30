//
//  FaceTemplateMultiRegistryTest.swift
//  
//
//  Created by Jakub Dolejs on 29/07/2025.
//

import XCTest
import VerIDCommonTypes
@testable import FaceTemplateRegistry

final class FaceTemplateMultiRegistryTest: XCTestCase {
    
    // MARK: - Initialisation
    
    func test_createRegistryWithIncompatibleFaces_fails() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V1, Float>(data: 0),
                identifier: "User 1"
            )
        ]
        let reg2Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V2, Float>(data: 1),
                identifier: "User 2"
            )
        ]
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: reg1Templates).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: reg2Templates).eraseToAnyFaceTemplateRegistry()
        do {
            _ = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
            XCTFail()
        } catch FaceTemplateRegistryError.incompatibleFaceTemplates {
            // All good
        } catch {
            XCTFail()
        }
    }
    
    func test_createRegistryWithIncompatibleFacesTogglingCheckOnOff() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V1, Float>(data: 0),
                identifier: "User 1"
            )
        ]
        let reg2Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V2, Float>(data: 1),
                identifier: "User 2"
            )
        ]
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: reg1Templates).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: reg2Templates).eraseToAnyFaceTemplateRegistry()
        _ = try await FaceTemplateMultiRegistry(ensureFaceTemplateCompatibility: false, registries: reg1, reg2)
        do {
            _ = try await FaceTemplateMultiRegistry(ensureFaceTemplateCompatibility: true, registries: reg1, reg2)
            XCTFail()
        } catch FaceTemplateRegistryError.incompatibleFaceTemplates {
            // All good
        } catch {
            XCTFail()
        }
    }
    
    // MARK: - Registration

    func test_registerFace() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: []).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: []).eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let registeredFaceTemplates = try await multiRegistry.registerFace(Mocks.face(0), image: Mocks.image, identifier: "User 1")
        XCTAssertEqual(registeredFaceTemplates.count, multiRegistry.registries.count)
        let allFaceTemplates = await multiRegistry.faceTemplates
        XCTAssertEqual(allFaceTemplates.count, multiRegistry.registries.count)
    }

    func test_registerSimilarFaceAsDifferentIdentifier_fail() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V1, Float>(data: 0),
                identifier: "User 1"
            )
        ]
        let reg2Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V2, Float>(data: 1),
                identifier: "User 1"
            )
        ]
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: reg1Templates).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: reg2Templates).eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        do {
            _ = try await multiRegistry.registerFace(Mocks.face(0.1), image: Mocks.image, identifier: "User 2")
            XCTFail()
        } catch FaceTemplateRegistryError.similarFaceAlreadyRegisteredAs(let user) {
            XCTAssertEqual(user, "User 1")
        } catch {
            XCTFail()
        }
    }
    
    func test_registerSimilarFaceAsDifferentIdentifier() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V1, Float>(data: 0),
                identifier: "User 1"
            )
        ]
        let reg2Templates = [
            TaggedFaceTemplate(
                faceTemplate: FaceTemplate<V2, Float>(data: 1),
                identifier: "User 1"
            )
        ]
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: reg1Templates).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: reg2Templates).eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let registered = try await multiRegistry.registerFace(Mocks.face(0.1), image: Mocks.image, identifier: "User 2", forceEnrolment: true)
        XCTAssertEqual(registered.count, multiRegistry.registries.count)
    }
    
    func test_registerFaceEnsuringDelegateCalled() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: []).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: []).eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let expectation = XCTestExpectation()
        let delegate = TestDelegate(expectation: expectation)
        multiRegistry.delegate = delegate
        let registeredFaceTemplates = try await multiRegistry.registerFace(Mocks.face(0), image: Mocks.image, identifier: "User 1")
        XCTAssertEqual(registeredFaceTemplates.count, multiRegistry.registries.count)
        let allFaceTemplates = await multiRegistry.faceTemplates
        XCTAssertEqual(allFaceTemplates.count, multiRegistry.registries.count)
        await fulfillment(of: [expectation])
        XCTAssertEqual(delegate.addedTemplates.count, multiRegistry.registries.count)
    }
    
    // MARK: - Identification
    
    func test_identifyFaceInEmptySet_returnsEmptyResult() async throws {
        let rec1 = MockFaceRecognition<V1>()
        let rec2 = MockFaceRecognition<V2>()
        let reg1 = FaceTemplateRegistry(faceRecognition: rec1, faceTemplates: []).eraseToAnyFaceTemplateRegistry()
        let reg2 = FaceTemplateRegistry(faceRecognition: rec2, faceTemplates: []).eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let idResults = try await multiRegistry.identifyFace(Mocks.face(0), image: Mocks.image)
        XCTAssertTrue(idResults.isEmpty)
    }
    
    func test_identifyFace() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 10, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 10, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let idResults = try await multiRegistry.identifyFace(Mocks.face(5), image: Mocks.image)
        XCTAssertEqual(1, idResults.count)
        XCTAssertEqual("User 5", idResults[0].taggedFaceTemplate.identifier)
    }
    
    func test_identifyFaceInCorruptSet_fails() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 1, templatesPerUserCount: 1)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 1, templatesPerUserCount: 1, startingUserId: 1)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(ensureFaceTemplateCompatibility: false, registries: reg1, reg2)
        do {
            _ = try await multiRegistry.identifyFace(Mocks.face(0), image: Mocks.image)
            XCTFail()
        } catch FaceTemplateRegistryError.incompatibleFaceTemplates {
            // All good
        } catch {
            XCTFail()
        }
        let results = try await multiRegistry.identifyFace(Mocks.face(0), image: Mocks.image, safe: false)
        XCTAssertEqual(1, results.count)
    }
    
    func test_autoEnrolFaceAtIdentification() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 10, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 2, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let expectation = XCTestExpectation()
        let delegate = TestDelegate(expectation: expectation)
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        multiRegistry.delegate = delegate
        let results = try await multiRegistry.identifyFace(Mocks.face(5.3), image: Mocks.image)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].taggedFaceTemplate.identifier, "User 5")
        XCTAssertEqual(results[0].autoEnrolledFaceTemplates.count, 1)
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(delegate.addedTemplates.count, 1)
        XCTAssertEqual(delegate.addedTemplates[0].identifier, "User 5")
    }
    
    // MARK: - Authentication
    
    func test_authenticateFace() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let face = Mocks.face(3.1)
        let authResult = try await multiRegistry.authenticateFace(face, image: Mocks.image, identifier: "User 3")
        XCTAssertTrue(authResult.authenticated)
    }
    
    func test_authenticateFaceInEmptyRegistry_fail() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 0, templatesPerUserCount: 0)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 0, templatesPerUserCount: 0)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        do {
            _ = try await multiRegistry.authenticateFace(Mocks.face(0), image: Mocks.image, identifier: "Test")
            XCTFail()
        } catch FaceTemplateRegistryError.identifierNotRegistered(let user) {
            XCTAssertEqual(user, "Test")
        } catch {
            XCTFail()
        }
    }
    
    func test_authenticateFaceOfUnregisteredUser() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let result = try await multiRegistry.authenticateFace(Mocks.face(10.1), image: Mocks.image, identifier: "User 1")
        XCTAssertFalse(result.authenticated)
    }
    
    func test_autoEnrolFaceAtAuthentication() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 10, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 2, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let expectation = XCTestExpectation()
        let delegate = TestDelegate(expectation: expectation)
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        multiRegistry.delegate = delegate
        let results = try await multiRegistry.authenticateFace(Mocks.face(5.3), image: Mocks.image, identifier: "User 5")
        XCTAssertTrue(results.authenticated)
        XCTAssertEqual(results.autoEnrolledFaceTemplates.count, 1)
        await fulfillment(of: [expectation], timeout: 2)
        XCTAssertEqual(delegate.addedTemplates.count, 1)
        XCTAssertEqual(delegate.addedTemplates[0].identifier, "User 5")
    }
    
    func test_doNotAutoEnrolFaceAtAuthentication() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 10, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 2, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let results = try await multiRegistry.authenticateFace(Mocks.face(5.3), image: Mocks.image, identifier: "User 5", autoEnrol: false)
        XCTAssertTrue(results.authenticated)
        XCTAssertEqual(results.autoEnrolledFaceTemplates.count, 0)
    }
    
    // MARK: - Retrieval
    
    func test_getFaceTemplatesByIdentifier() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let templates = await multiRegistry.faceTemplatesByIdentifier("User 1")
        XCTAssertEqual(templates.count, 4)
    }
    
    func test_getIdentifiers() async throws {
        let reg1 = Mocks.createRegistry(for: V1.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let reg2 = Mocks.createRegistry(for: V2.self, userCount: 5, templatesPerUserCount: 2)
            .eraseToAnyFaceTemplateRegistry()
        let multiRegistry = try await FaceTemplateMultiRegistry(registries: reg1, reg2)
        let identifiers = await multiRegistry.identifiers
        XCTAssertEqual(identifiers.count, 5)
    }
}

class TestDelegate: FaceTemplateMultiRegistryDelegate {
    
    let expectation: XCTestExpectation
    var addedTemplates: [AnyTaggedFaceTemplate] = []
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func onFaceTemplatesAdded(_ faceTemplates: [AnyTaggedFaceTemplate]) {
        self.addedTemplates = faceTemplates
        self.expectation.fulfill()
    }
}
