//
//  MockFaceRecognition.swift
//
//
//  Created by Jakub Dolejs on 29/07/2025.
//

import Foundation
import VerIDCommonTypes

class MockFaceRecognition<V: FaceTemplateVersion>: FaceRecognition {
    typealias Version = V
    typealias TemplateData = Float
    
    func createFaceRecognitionTemplates(from faces: [Face], in image: Image) async throws -> [FaceTemplate<V, TemplateData>] {
        return faces.map { face in
            FaceTemplate(data: Float(face.bounds.minX))
        }
    }
    
    func compareFaceRecognitionTemplates(_ faceRecognitionTemplates: [FaceTemplate<V, TemplateData>], to template: FaceTemplate<V, TemplateData>) async throws -> [Float] {
        let challengeData = template.data
        let templateData = faceRecognitionTemplates.map { $0.data }
        return templateData.map { data in
            let diff = abs(data - challengeData)
            return diff > 1.0 ? 0 : 1.0 - diff
        }
    }
}
